import os
from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.api.deps import get_current_user
from backend.app.models.user import User
from backend.app.models.doctor import DoctorProfile
from backend.app.models.patient import (
    EmergencyAccess,
    EmergencyQR,
    PatientMedicalProfile,
    EmergencyContact,
    MedicalReport
)
from backend.app.schemas.doctor import (
    DoctorProfileResponse,
    DoctorProfileUpdate,
    EmergencyAccessRequest,
    EmergencyAccessActiveSession,
    EmergencyAccessHistoryItem
)
from backend.app.api.patient import resolve_report_file_path

router = APIRouter(prefix="/api/doctor", tags=["Doctor"])

@router.get("/profile", response_model=DoctorProfileResponse)
def get_doctor_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Enforce role check
    if current_user.role != "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to doctor role only."
        )

    # Retrieve or initialize DoctorProfile table entry
    profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == current_user.id).first()
    if not profile:
        profile = DoctorProfile(
            user_id=current_user.id,
            professional_id=None,
            specialization=None
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)

    return DoctorProfileResponse(
        id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
        phone_number=current_user.phone_number,
        role=current_user.role,
        professional_id=profile.professional_id,
        specialization=profile.specialization,
        doctor_verification_status=current_user.doctor_verification_status,
        account_status=current_user.account_status
    )

@router.put("/profile", response_model=DoctorProfileResponse)
def update_doctor_profile(
    payload: DoctorProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to doctor role only."
        )

    # Retrieve profile
    profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == current_user.id).first()
    if not profile:
        profile = DoctorProfile(user_id=current_user.id)
        db.add(profile)

    profile.professional_id = payload.professional_id.strip()
    profile.specialization = payload.specialization.strip()
    db.commit()
    db.refresh(profile)

    return DoctorProfileResponse(
        id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
        phone_number=current_user.phone_number,
        role=current_user.role,
        professional_id=profile.professional_id,
        specialization=profile.specialization,
        doctor_verification_status=current_user.doctor_verification_status,
        account_status=current_user.account_status
    )

@router.get("/verification-status")
def get_verification_status(current_user: User = Depends(get_current_user)):
    if current_user.role != "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to doctor role only."
        )
    return {
        "status": "success",
        "doctor_verification_status": current_user.doctor_verification_status
    }

@router.post("/emergency-access/request")
def request_emergency_access(
    payload: EmergencyAccessRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Enforce secure checks on doctor
    if current_user.role != "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to doctor role only."
        )
    
    if current_user.account_status != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Doctor account is currently inactive."
        )

    # Unverified/Pending/Rejected/Suspended doctors are strictly blocked
    if current_user.doctor_verification_status != "verified":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access blocked. Your professional medical verification is currently pending or restricted."
        )

    # Retrieve and validate Opaque QR Token
    qr_record = db.query(EmergencyQR).filter(
        EmergencyQR.token == payload.token.strip(),
        EmergencyQR.is_active == True
    ).first()

    if not qr_record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This Emergency QR code is invalid or has been invalidated."
        )

    # Find the patient associated with the token
    patient = db.query(User).filter(User.id == qr_record.user_id, User.role == "patient").first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Associated patient profile not found."
        )

    # Check if there is already an active session to prevent double records
    existing_access = db.query(EmergencyAccess).filter(
        EmergencyAccess.patient_id == patient.id,
        EmergencyAccess.doctor_id == current_user.id,
        EmergencyAccess.status == "active",
        EmergencyAccess.expires_at > datetime.utcnow()
    ).first()

    if existing_access:
        return {
            "status": "success",
            "access_id": existing_access.id,
            "expires_at": existing_access.expires_at.isoformat(),
            "message": "Existing active emergency access session reused."
        }

    # Establish new 15-minute emergency access session
    granted_at = datetime.utcnow()
    expires_at = granted_at + timedelta(minutes=15)

    new_access = EmergencyAccess(
        patient_id=patient.id,
        doctor_id=current_user.id,
        status="active",
        granted_at=granted_at,
        expires_at=expires_at
    )
    db.add(new_access)
    db.commit()
    db.refresh(new_access)

    return {
        "status": "success",
        "access_id": new_access.id,
        "expires_at": expires_at.isoformat(),
        "message": "Emergency access session created successfully."
    }

@router.get("/emergency-access/active", response_model=List[EmergencyAccessActiveSession])
def get_active_sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access restricted to doctor role only.")

    # Sweep and auto-expire stale sessions first
    now = datetime.utcnow()
    stale_sessions = db.query(EmergencyAccess).filter(
        EmergencyAccess.doctor_id == current_user.id,
        EmergencyAccess.status == "active",
        EmergencyAccess.expires_at <= now
    ).all()
    if stale_sessions:
        for s in stale_sessions:
            s.status = "expired"
        db.commit()

    # Query active ones
    active_rows = db.query(EmergencyAccess).filter(
        EmergencyAccess.doctor_id == current_user.id,
        EmergencyAccess.status == "active",
        EmergencyAccess.expires_at > now
    ).all()

    results = []
    for s in active_rows:
        results.append(EmergencyAccessActiveSession(
            id=s.id,
            patient_name=s.patient.full_name,
            patient_email=s.patient.email,
            granted_at=s.granted_at,
            expires_at=s.expires_at,
            status=s.status
        ))
    return results

@router.get("/emergency-access/{access_id}/patient")
def get_authorized_patient_data(
    access_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access restricted to doctor role only.")

    # Retrieve access log
    access = db.query(EmergencyAccess).filter(EmergencyAccess.id == access_id).first()
    if not access:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Access session not found.")

    # Enforce Anti-IDOR: verify the requested access belongs to the authenticated doctor
    if access.doctor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized access session.")

    # Verify session status is active
    if access.status == "revoked":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This emergency access has been revoked."
        )

    # Verify session has not expired
    if access.expires_at <= datetime.utcnow() or access.status == "expired":
        if access.status == "active":
            access.status = "expired"
            db.commit()
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This emergency access session has expired."
        )

    # Session is valid. Gather patient data (Data Minimization)
    patient = access.patient
    med_profile = db.query(PatientMedicalProfile).filter(PatientMedicalProfile.user_id == patient.id).first()
    contacts = db.query(EmergencyContact).filter(EmergencyContact.user_id == patient.id).all()
    reports = db.query(MedicalReport).filter(MedicalReport.user_id == patient.id).all()

    profile_data = {}
    if med_profile:
        profile_data = {
            "blood_group": med_profile.blood_group,
            "height": med_profile.height,
            "weight": med_profile.weight,
            "allergies": med_profile.allergies,
            "conditions": med_profile.conditions,
            "medications": med_profile.medications,
            "critical_notes": med_profile.critical_notes
        }

    contacts_data = []
    for c in contacts:
        contacts_data.append({
            "name": c.name,
            "relationship": c.relationship,
            "phone_number": c.phone_number,
            "is_primary": c.is_primary
        })

    reports_data = []
    for r in reports:
        reports_data.append({
            "id": r.id,
            "title": r.title,
            "type": r.type,
            "report_date": r.report_date,
            "description": r.description
        })

    return {
        "status": "success",
        "patient_name": patient.full_name,
        "patient_email": patient.email,
        "patient_phone": patient.phone_number,
        "medical_profile": profile_data,
        "contacts": contacts_data,
        "reports": reports_data
    }

@router.get("/emergency-access/{access_id}/reports/{report_id}/file")
def get_authorized_patient_file(
    access_id: int,
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access restricted to doctor role only.")

    # Retrieve access session
    access = db.query(EmergencyAccess).filter(EmergencyAccess.id == access_id).first()
    if not access:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    # Anti-IDOR: Check doctor association
    if access.doctor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized access session.")

    if access.status == "revoked":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access revoked.")

    if access.expires_at <= datetime.utcnow() or access.status == "expired":
        if access.status == "active":
            access.status = "expired"
            db.commit()
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access expired.")

    # Retrieve the report
    report = db.query(MedicalReport).filter(MedicalReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")

    # Enforce security boundary: verify report belongs to the authorized patient
    if report.user_id != access.patient_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access restricted. File does not belong to authorized patient.")

    # Stream file
    resolved_path = resolve_report_file_path(report.file_path)
    if not os.path.exists(resolved_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report file not found on disk.")

    return FileResponse(resolved_path, filename=report.file_name)

@router.post("/emergency-access/{access_id}/revoke")
def revoke_emergency_access_by_doctor(
    access_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access restricted to doctor role only.")

    access = db.query(EmergencyAccess).filter(EmergencyAccess.id == access_id).first()
    if not access:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

    # Verify ownership
    if access.doctor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized.")

    access.status = "revoked"
    access.revoked_at = datetime.utcnow()
    db.commit()

    return {"status": "success", "message": "Emergency access session terminated successfully."}

@router.get("/emergency-access/history", response_model=List[EmergencyAccessHistoryItem])
def get_doctor_access_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access restricted to doctor role only.")

    # Return access sessions for current doctor
    history = db.query(EmergencyAccess).filter(
        EmergencyAccess.doctor_id == current_user.id
    ).order_by(EmergencyAccess.granted_at.desc()).all()

    results = []
    for h in history:
        # Determine status
        status_str = h.status
        if h.status == "active" and h.expires_at <= datetime.utcnow():
            status_str = "expired"

        results.append(EmergencyAccessHistoryItem(
            id=h.id,
            patient_name=h.patient.full_name,
            granted_at=h.granted_at,
            status=status_str
        ))
    return results
