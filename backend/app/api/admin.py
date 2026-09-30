from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from backend.app.core.database import get_db
from backend.app.api.deps import require_role
from backend.app.models.user import User
from backend.app.models.doctor import DoctorProfile
from backend.app.models.audit_log import AuditLog
from backend.app.schemas.admin import DoctorDetailResponse, UserSearchResponse, AuditLogResponse

router = APIRouter(prefix="/api/admin", tags=["admin"])

class VerificationNote(BaseModel):
    notes: Optional[str] = None

@router.get("/doctors/pending", response_model=List[DoctorDetailResponse])
def get_pending_doctors(
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    # Fetch doctors where verification status is pending
    pending_users = db.query(User).filter(
        User.role == "doctor",
        User.doctor_verification_status == "pending"
    ).all()

    results = []
    for user in pending_users:
        doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
        results.append(
            DoctorDetailResponse(
                id=user.id,
                full_name=user.full_name,
                email=user.email,
                phone_number=user.phone_number,
                professional_id=doc_profile.professional_id if doc_profile else None,
                specialization=doc_profile.specialization if doc_profile else None,
                doctor_verification_status=user.doctor_verification_status,
                account_status=user.account_status
            )
        )
    return results

@router.get("/doctors/{doctor_id}", response_model=DoctorDetailResponse)
def get_doctor_details(
    doctor_id: int,
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == doctor_id, User.role == "doctor").first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor profile not found."
        )

    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
    return DoctorDetailResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        professional_id=doc_profile.professional_id if doc_profile else None,
        specialization=doc_profile.specialization if doc_profile else None,
        doctor_verification_status=user.doctor_verification_status,
        account_status=user.account_status
    )

@router.post("/doctors/{doctor_id}/verify", response_model=DoctorDetailResponse)
def verify_doctor(
    doctor_id: int,
    payload: VerificationNote,
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == doctor_id, User.role == "doctor").first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found."
        )

    prev_status = user.doctor_verification_status
    # Allowed source statuses for verification: pending, suspended
    if prev_status not in ["pending", "suspended"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot transition status from '{prev_status}' to 'verified'."
        )

    # Perform update
    user.doctor_verification_status = "verified"
    user.account_status = "active"  # Ensure the account is active

    # Log action
    log = AuditLog(
        admin_id=current_user.id,
        target_user_id=user.id,
        action="verify",
        previous_status=prev_status,
        new_status="verified",
        notes=payload.notes
    )
    db.add(log)
    db.commit()
    db.refresh(user)

    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
    return DoctorDetailResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        professional_id=doc_profile.professional_id if doc_profile else None,
        specialization=doc_profile.specialization if doc_profile else None,
        doctor_verification_status=user.doctor_verification_status,
        account_status=user.account_status
    )

@router.post("/doctors/{doctor_id}/reject", response_model=DoctorDetailResponse)
def reject_doctor(
    doctor_id: int,
    payload: VerificationNote,
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == doctor_id, User.role == "doctor").first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found."
        )

    prev_status = user.doctor_verification_status
    # Allowed source statuses for reject: pending
    if prev_status not in ["pending"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot transition status from '{prev_status}' to 'rejected'."
        )

    user.doctor_verification_status = "rejected"

    log = AuditLog(
        admin_id=current_user.id,
        target_user_id=user.id,
        action="reject",
        previous_status=prev_status,
        new_status="rejected",
        notes=payload.notes
    )
    db.add(log)
    db.commit()
    db.refresh(user)

    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
    return DoctorDetailResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        professional_id=doc_profile.professional_id if doc_profile else None,
        specialization=doc_profile.specialization if doc_profile else None,
        doctor_verification_status=user.doctor_verification_status,
        account_status=user.account_status
    )

@router.post("/doctors/{doctor_id}/suspend", response_model=DoctorDetailResponse)
def suspend_doctor(
    doctor_id: int,
    payload: VerificationNote,
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == doctor_id, User.role == "doctor").first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found."
        )

    prev_status = user.doctor_verification_status
    # Allowed source statuses for suspension: verified
    if prev_status not in ["verified"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot transition status from '{prev_status}' to 'suspended'."
        )

    user.doctor_verification_status = "suspended"

    log = AuditLog(
        admin_id=current_user.id,
        target_user_id=user.id,
        action="suspend",
        previous_status=prev_status,
        new_status="suspended",
        notes=payload.notes
    )
    db.add(log)
    db.commit()
    db.refresh(user)

    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
    return DoctorDetailResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        professional_id=doc_profile.professional_id if doc_profile else None,
        specialization=doc_profile.specialization if doc_profile else None,
        doctor_verification_status=user.doctor_verification_status,
        account_status=user.account_status
    )

@router.post("/doctors/{doctor_id}/reactivate", response_model=DoctorDetailResponse)
def reactivate_doctor(
    doctor_id: int,
    payload: VerificationNote,
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == doctor_id, User.role == "doctor").first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found."
        )

    prev_status = user.doctor_verification_status
    # Allowed source statuses for reactivation: suspended
    if prev_status not in ["suspended"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot transition status from '{prev_status}' to 'verified' via reactivation."
        )

    user.doctor_verification_status = "verified"

    log = AuditLog(
        admin_id=current_user.id,
        target_user_id=user.id,
        action="reactivate",
        previous_status=prev_status,
        new_status="verified",
        notes=payload.notes
    )
    db.add(log)
    db.commit()
    db.refresh(user)

    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
    return DoctorDetailResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        professional_id=doc_profile.professional_id if doc_profile else None,
        specialization=doc_profile.specialization if doc_profile else None,
        doctor_verification_status=user.doctor_verification_status,
        account_status=user.account_status
    )

@router.get("/users/search", response_model=List[UserSearchResponse])
def search_users(
    query: Optional[str] = None,
    role: Optional[str] = None,
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    db_query = db.query(User)
    
    if query:
        search_str = f"%{query}%"
        db_query = db_query.filter(
            (User.full_name.ilike(search_str)) |
            (User.email.ilike(search_str))
        )
        
    if role:
        db_query = db_query.filter(User.role == role.strip().lower())

    users = db_query.all()
    return [
        UserSearchResponse(
            id=u.id,
            full_name=u.full_name,
            email=u.email,
            phone_number=u.phone_number,
            role=u.role,
            account_status=u.account_status,
            doctor_verification_status=u.doctor_verification_status
        )
        for u in users
    ]

@router.get("/audit-logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    current_user: User = Depends(require_role(["admin"])),
    db: Session = Depends(get_db)
):
    logs = db.query(AuditLog).order_by(AuditLog.created_at.desc()).all()
    results = []
    for log in logs:
        admin_name = log.admin.full_name if log.admin else "Unknown Admin"
        target_name = log.target_user.full_name if log.target_user else "Unknown User"
        results.append(
            AuditLogResponse(
                id=log.id,
                admin_id=log.admin_id,
                admin_name=admin_name,
                target_user_id=log.target_user_id,
                target_user_name=target_name,
                action=log.action,
                previous_status=log.previous_status,
                new_status=log.new_status,
                notes=log.notes,
                created_at=log.created_at
            )
        )
    return results
