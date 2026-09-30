from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from typing import Optional, Dict, Any

from backend.app.core.database import get_db
from backend.app.core.rate_limiter import check_rate_limit
from backend.app.models.user import User
from backend.app.models.patient import (
    EmergencyQR,
    PatientMedicalProfile,
    EmergencyContact
)
from backend.app.models.audit_log import AuditLog

router = APIRouter(prefix="/api/public", tags=["Public Emergency"])

@router.get("/emergency/{token}")
def get_public_emergency_info(
    token: str,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Public emergency access endpoint for bystanders/first responders.
    Accepts ONLY an opaque token (format: HS-E:<token>).
    Never accepts patient_id, email, or phone.
    Rate-limited per client IP.
    Returns STRICTLY minimal emergency data: First Name, Blood Group,
    Critical Allergy Warning (if marked emergency-critical), and Primary Contact.
    """
    clean_token = token.strip()
    if not clean_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Emergency token is required."
        )
    if not clean_token.startswith("HS-E:"):
        clean_token = f"HS-E:{clean_token}"

    # Rate limit by client IP to prevent brute-force token enumeration
    client_ip = request.client.host if request.client else "unknown"
    check_rate_limit(request, identifier=f"public_qr_{client_ip}", limit=15, window_seconds=60)

    # Lookup opaque token
    qr_record = db.query(EmergencyQR).filter(
        EmergencyQR.token == clean_token,
        EmergencyQR.is_active == True
    ).first()

    if not qr_record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency QR code is invalid, inactive, or has been revoked."
        )

    # Verify patient
    patient = db.query(User).filter(
        User.id == qr_record.user_id,
        User.role == "patient"
    ).first()

    if not patient or patient.account_status != "active":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Associated emergency profile is unavailable."
        )

    # 1. First Name ONLY (Data minimization: no full name or surname)
    first_name = patient.full_name.split()[0] if patient.full_name else "Patient"

    # 2. Blood Group & Critical Allergy Warning
    med_profile = db.query(PatientMedicalProfile).filter(
        PatientMedicalProfile.user_id == patient.id
    ).first()

    blood_group = (med_profile.blood_group if med_profile and med_profile.blood_group else "Unknown").strip()

    # Only expose critical allergy warning if explicitly noted in critical_notes
    critical_warning = None
    if med_profile and med_profile.critical_notes and med_profile.critical_notes.strip():
        critical_warning = med_profile.critical_notes.strip()

    # 3. Primary Emergency Contact ONLY
    primary_contact_record = db.query(EmergencyContact).filter(
        EmergencyContact.user_id == patient.id,
        EmergencyContact.is_primary == True
    ).first()

    if not primary_contact_record:
        # Fallback to first contact if no primary is explicitly marked
        primary_contact_record = db.query(EmergencyContact).filter(
            EmergencyContact.user_id == patient.id
        ).first()

    primary_contact = None
    if primary_contact_record:
        primary_contact = {
            "name": primary_contact_record.name,
            "relationship": primary_contact_record.relationship,
            "phone_number": primary_contact_record.phone_number
        }

    # Log public access event in audit log (Data minimization: no sensitive data in log)
    try:
        log_entry = AuditLog(
            admin_id=None,
            target_user_id=patient.id,
            action="public_emergency_view",
            previous_status="active",
            new_status="active",
            notes=f"Public emergency lookup via QR token from IP {client_ip}"
        )
        db.add(log_entry)
        db.commit()
    except Exception:
        db.rollback()

    return {
        "status": "success",
        "first_name": first_name,
        "blood_group": blood_group,
        "critical_allergy_warning": critical_warning,
        "primary_contact": primary_contact
    }
