import re
import secrets
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.core.rate_limiter import check_rate_limit
from backend.app.core.security import create_access_token, hash_password, verify_password
from backend.app.models.otp import OTP
from backend.app.models.user import User
from backend.app.models.doctor import DoctorProfile
from backend.app.schemas.auth import (
    OTPLinkRequest,
    OTPVerify,
    PasswordReset,
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)
from backend.app.services.notification_service import notification_service

router = APIRouter(prefix="/api/auth", tags=["authentication"])

def generate_otp_code() -> str:
    """Generate a secure 6-digit random code."""
    return "".join(secrets.choice("0123456789") for _ in range(6))

@router.post("/register", response_model=UserResponse)
def register(payload: UserRegister, request: Request, db: Session = Depends(get_db)):
    # Rate limit based on IP and email
    check_rate_limit(request, identifier=payload.email, limit=5, window_seconds=60)
    
    # Check if email exists
    existing_user_email = db.query(User).filter(User.email == payload.email).first()
    if existing_user_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email address is already registered."
        )
        
    # Check if phone number exists
    existing_user_phone = db.query(User).filter(User.phone_number == payload.phone_number).first()
    if existing_user_phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is already registered."
        )

    # If doctor, check if professional_id (license) is already registered
    if payload.role == "doctor" and payload.professional_id and payload.professional_id.strip():
        clean_license = payload.professional_id.strip()
        existing_license = db.query(DoctorProfile).filter(DoctorProfile.professional_id == clean_license).first()
        if existing_license:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Medical License / Professional ID is already registered."
            )

    # Hash the password using direct bcrypt wrapper
    hashed = hash_password(payload.password)
    
    # Determine doctor verification status
    doc_ver_status = "pending" if payload.role == "doctor" else "not_applicable"

    # Clean doctor full_name to store actual name without title prefix
    clean_name = payload.full_name.strip()
    if payload.role == "doctor":
        clean_name = re.sub(r'^(dr\.?|doctor)\s+', '', clean_name, flags=re.IGNORECASE).strip()

    # Create new User record with account_status = 'inactive'
    new_user = User(
        full_name=clean_name,
        email=payload.email,
        phone_number=payload.phone_number,
        password_hash=hashed,
        role=payload.role,
        account_status="inactive",
        doctor_verification_status=doc_ver_status
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Persist DoctorProfile if role is doctor
    if payload.role == "doctor":
        doc_profile = DoctorProfile(
            user_id=new_user.id,
            professional_id=payload.professional_id.strip() if payload.professional_id and payload.professional_id.strip() else None,
            specialization=payload.specialization.strip() if payload.specialization and payload.specialization.strip() else None,
        )
        db.add(doc_profile)
        db.commit()

    # Generate registration OTP
    otp_code = generate_otp_code()
    expires_at = datetime.utcnow() + timedelta(minutes=5)
    
    otp_record = OTP(
        email_or_phone=payload.email,
        code=otp_code,
        purpose="register",
        expires_at=expires_at,
        is_used=False
    )
    
    db.add(otp_record)
    db.commit()

    # Dispatch OTP via isolated service
    notification_service.send_otp(payload.email, otp_code, "register")

    return new_user

@router.post("/verify-otp")
def verify_otp(payload: OTPVerify, request: Request, db: Session = Depends(get_db)):
    # Rate limit on target email/phone
    check_rate_limit(request, identifier=payload.email_or_phone, limit=5, window_seconds=60)

    # Retrieve matching OTP that is not expired and not used
    otp_record = db.query(OTP).filter(
        OTP.email_or_phone == payload.email_or_phone.strip().lower(),
        OTP.code == payload.code.strip(),
        OTP.purpose == payload.purpose,
        OTP.is_used == False,
        OTP.expires_at > datetime.utcnow()
    ).first()

    if not otp_record:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP code."
        )

    # Mark OTP as used (only for registration; reset flow marks it used inside /reset-password)
    if payload.purpose != "reset":
        otp_record.is_used = True
        db.commit()

    # Find the user by email or phone to activate account
    user = db.query(User).filter(
        (User.email == payload.email_or_phone.strip().lower()) |
        (User.phone_number == payload.email_or_phone.strip())
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User account not found."
        )

    # Activate account status
    user.account_status = "active"
    db.commit()

    # Note: doctor_verification_status remains untouched ('pending'). OTP verification does not grant privileges.
    return {
        "status": "success",
        "message": "Account successfully activated.",
        "role": user.role,
        "doctor_verification_status": user.doctor_verification_status
    }

@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, request: Request, db: Session = Depends(get_db)):
    # Rate limit attempts on IP/email
    check_rate_limit(request, identifier=payload.email_or_phone, limit=5, window_seconds=60)

    # Find user by email or phone
    user = db.query(User).filter(
        (User.email == payload.email_or_phone.strip().lower()) |
        (User.phone_number == payload.email_or_phone.strip())
    ).first()

    if not user or not verify_password(payload.password, user.password_hash):
        print(f"[AUTH_DEBUG] Failed login attempt: credentials invalid")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect credentials. Please try again."
        )

    # Block login if user has not activated their account via OTP
    if user.account_status != "active":
        print(f"[AUTH_DEBUG] Login blocked: account inactive")
        # Re-send verification OTP
        otp_code = generate_otp_code()
        expires_at = datetime.utcnow() + timedelta(minutes=5)
        
        otp_record = OTP(
            email_or_phone=user.email,
            code=otp_code,
            purpose="register",
            expires_at=expires_at,
            is_used=False
        )
        db.add(otp_record)
        db.commit()
        
        notification_service.send_otp(user.email, otp_code, "register")
        
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. A verification OTP has been sent to your email."
        )

    # Role validation on backend: requested role must match authenticated user's role
    if payload.role:
        requested_role = payload.role.strip().lower()
        print(f"[ROLE_DEBUG] Login requested: {requested_role}")
        print(f"[ROLE_DEBUG] Authenticated account role: {user.role}")
        if user.role.strip().lower() != requested_role:
            print(f"[ROLE_DEBUG] Login rejected: role mismatch")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access restricted to {requested_role} role only."
            )

    print(f"[AUTH_DEBUG] Login successful: user_id={user.id}, role={user.role}")

    # Generate session access token
    access_token = create_access_token(subject=user.id)

    return TokenResponse(
        access_token=access_token,
        role=user.role,
        full_name=user.full_name,
        doctor_verification_status=user.doctor_verification_status
    )

@router.post("/forgot-password")
def forgot_password(payload: OTPLinkRequest, request: Request, db: Session = Depends(get_db)):
    # Rate limit forgot password queries
    check_rate_limit(request, identifier=payload.email_or_phone, limit=3, window_seconds=60)

    # Find active user
    user = db.query(User).filter(
        (User.email == payload.email_or_phone.strip().lower()) |
        (User.phone_number == payload.email_or_phone.strip())
    ).first()

    if not user:
        # Prevent user enumeration attacks by returning success even if email not found
        # In a college project context, we will return success to keep flow secure.
        return {
            "status": "success",
            "message": "If the account exists, an OTP has been sent."
        }

    # Generate reset OTP
    otp_code = generate_otp_code()
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    otp_record = OTP(
        email_or_phone=user.email,
        code=otp_code,
        purpose="reset",
        expires_at=expires_at,
        is_used=False
    )
    db.add(otp_record)
    db.commit()

    notification_service.send_otp(user.email, otp_code, "reset")

    return {
        "status": "success",
        "message": "Verification OTP sent successfully."
    }

@router.post("/reset-password")
def reset_password(payload: PasswordReset, request: Request, db: Session = Depends(get_db)):
    # Rate limit reset calls
    check_rate_limit(request, identifier=payload.email_or_phone, limit=3, window_seconds=60)

    # Check OTP record
    otp_record = db.query(OTP).filter(
        OTP.email_or_phone == payload.email_or_phone.strip().lower(),
        OTP.code == payload.code.strip(),
        OTP.purpose == "reset",
        OTP.is_used == False,
        OTP.expires_at > datetime.utcnow()
    ).first()

    if not otp_record:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset OTP code."
        )

    # Mark OTP as used
    otp_record.is_used = True

    # Retrieve user and update credentials
    user = db.query(User).filter(
        (User.email == payload.email_or_phone.strip().lower()) |
        (User.phone_number == payload.email_or_phone.strip())
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User account not found."
        )

    # Encrypt new password using direct bcrypt
    user.password_hash = hash_password(payload.new_password)
    db.commit()

    return {
        "status": "success",
        "message": "Password successfully updated. You may now login."
    }
