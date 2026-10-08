import os
import uuid
import shutil
import secrets
import math
from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Request
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from backend.app.core.database import get_db
from backend.app.api.deps import get_current_user, require_role
from backend.app.models.user import User
from backend.app.models.healthcare_provider import HealthcareProvider
from backend.app.models.patient import (
    PatientMedicalProfile,
    MedicalReport,
    EmergencyContact,
    EmergencyQR,
    EmergencyAccess
)
from backend.app.models.reminder import MedicationReminder
from backend.app.schemas.patient import (
    MedicalProfileResponse,
    MedicalProfileUpdate,
    EmergencyContactCreate,
    EmergencyContactResponse,
    ReportResponse,
    QRResponse,
    EmergencyAccessResponse,
    HealthcareProviderResponse,
    AIChatRequest,
    AIChatResponse
)
from backend.app.schemas.reminder import (
    ReminderCreate,
    ReminderUpdate,
    ReminderResponse
)
from backend.app.services.ai_service import generate_health_assistant_response

router = APIRouter(prefix="/api/patient", tags=["patient"])

# Storage configuration for reports (private directory)
# Resolves to absolute path or environment variable to prevent working-directory mismatches in Docker/AWS
_DEFAULT_STORAGE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "storage", "reports"))
STORAGE_DIR = os.getenv("STORAGE_DIR", _DEFAULT_STORAGE_DIR)

def resolve_report_file_path(path: str) -> str:
    """Robustly resolve report file path across different environments and working directories."""
    if os.path.exists(path):
        return path
    # Try resolving relative to storage dir
    basename = os.path.basename(path)
    candidate = os.path.join(STORAGE_DIR, basename)
    if os.path.exists(candidate):
        return candidate
    # Try resolving relative to project root
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    candidate2 = os.path.join(project_root, path)
    if os.path.exists(candidate2):
        return candidate2
    return path

# Ensure storage directory exists on runtime
os.makedirs(STORAGE_DIR, exist_ok=True)

# ----------------------------------------------------
# 1. MEDICAL PROFILE ROUTES
# ----------------------------------------------------

@router.get("/profile", response_model=MedicalProfileResponse)
def get_medical_profile(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    profile = db.query(PatientMedicalProfile).filter(PatientMedicalProfile.user_id == current_user.id).first()
    if not profile:
        # Auto-initialize an empty profile so the client doesn't crash on empty DB
        profile = PatientMedicalProfile(
            user_id=current_user.id,
            blood_group="",
            height="",
            weight="",
            allergies="",
            conditions="",
            medications="",
            critical_notes=""
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile

@router.put("/profile", response_model=MedicalProfileResponse)
def update_medical_profile(
    payload: MedicalProfileUpdate,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    profile = db.query(PatientMedicalProfile).filter(PatientMedicalProfile.user_id == current_user.id).first()
    if not profile:
        profile = PatientMedicalProfile(user_id=current_user.id)
        db.add(profile)
        
    # Update properties dynamically
    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(profile, key, value)
        
    db.commit()
    db.refresh(profile)
    return profile

# ----------------------------------------------------
# 2. EMERGENCY CONTACT ROUTES
# ----------------------------------------------------

@router.get("/contacts", response_model=List[EmergencyContactResponse])
def get_emergency_contacts(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    return db.query(EmergencyContact).filter(EmergencyContact.user_id == current_user.id).all()

@router.post("/contacts", response_model=EmergencyContactResponse)
def add_emergency_contact(
    payload: EmergencyContactCreate,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    # If this is marked as primary, reset previous contacts' primary flag
    if payload.is_primary:
        db.query(EmergencyContact).filter(
            EmergencyContact.user_id == current_user.id
        ).update({"is_primary": False})
        db.commit()

    contact = EmergencyContact(
        user_id=current_user.id,
        name=payload.name,
        relationship=payload.relationship,
        phone_number=payload.phone_number,
        is_primary=payload.is_primary
    )
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact

@router.put("/contacts/{contact_id}", response_model=EmergencyContactResponse)
def update_emergency_contact(
    contact_id: int,
    payload: EmergencyContactCreate,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    contact = db.query(EmergencyContact).filter(
        EmergencyContact.id == contact_id,
        EmergencyContact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Emergency contact not found")

    if payload.is_primary:
        # Reset other primary marks
        db.query(EmergencyContact).filter(
            EmergencyContact.user_id == current_user.id,
            EmergencyContact.id != contact_id
        ).update({"is_primary": False})
        db.commit()

    contact.name = payload.name
    contact.relationship = payload.relationship
    contact.phone_number = payload.phone_number
    contact.is_primary = payload.is_primary
    
    db.commit()
    db.refresh(contact)
    return contact

@router.delete("/contacts/{contact_id}")
def delete_emergency_contact(
    contact_id: int,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    contact = db.query(EmergencyContact).filter(
        EmergencyContact.id == contact_id,
        EmergencyContact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Emergency contact not found")

    db.delete(contact)
    db.commit()
    return {"status": "success", "message": "Emergency contact deleted"}

# ----------------------------------------------------
# 3. MEDICAL REPORT ROUTES
# ----------------------------------------------------

@router.get("/reports", response_model=List[ReportResponse])
def get_medical_reports(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    return db.query(MedicalReport).filter(MedicalReport.user_id == current_user.id).all()

@router.post("/reports", response_model=ReportResponse)
def add_medical_report(
    title: str = Form(...),
    type: str = Form(...),
    report_date: str = Form(...),
    description: str = Form(None),
    file: UploadFile = File(...),
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    # Generate secure filesystem name
    file_ext = os.path.splitext(file.filename)[1]
    secure_filename = f"{current_user.id}_{uuid.uuid4().hex}{file_ext}"
    dest_path = os.path.join(STORAGE_DIR, secure_filename)

    # Save file locally on the backend server
    with open(dest_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    report = MedicalReport(
        user_id=current_user.id,
        title=title,
        type=type,
        report_date=report_date,
        description=description,
        file_name=file.filename,
        file_path=dest_path
    )
    
    db.add(report)
    db.commit()
    db.refresh(report)
    return report

@router.get("/reports/{report_id}/file")
def get_report_file(
    report_id: int,
    current_user: User = Depends(get_current_user), # Any authenticated user (allows patient ownership check OR future doctor authorization check)
    db: Session = Depends(get_db)
):
    report = db.query(MedicalReport).filter(MedicalReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Medical report not found")

    # Authorize Access: Patient must own it, or a doctor must have an active emergency access log
    if current_user.role == "patient" and report.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this file")
        
    elif current_user.role == "doctor":
        # Future-proof foundation check: Assert doctor has an active, unexpired emergency session
        active_access = db.query(EmergencyAccess).filter(
            EmergencyAccess.patient_id == report.user_id,
            EmergencyAccess.doctor_id == current_user.id,
            EmergencyAccess.status == "active",
            EmergencyAccess.expires_at > datetime.utcnow()
        ).first()
        if not active_access:
            raise HTTPException(status_code=403, detail="No active emergency authorization found for this patient")

    resolved_path = resolve_report_file_path(report.file_path)
    if not os.path.exists(resolved_path):
        raise HTTPException(status_code=404, detail="Physical report file not found on disk")

    return FileResponse(
        path=resolved_path,
        filename=report.file_name,
        media_type="application/octet-stream"
    )

@router.delete("/reports/{report_id}")
def delete_medical_report(
    report_id: int,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    report = db.query(MedicalReport).filter(
        MedicalReport.id == report_id,
        MedicalReport.user_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Medical report not found")

    # Delete physical file from disk
    resolved_path = resolve_report_file_path(report.file_path)
    if os.path.exists(resolved_path):
        try:
            os.remove(resolved_path)
        except Exception:
            pass # Keep database deletion clean even if file was missing on disk

    db.delete(report)
    db.commit()
    return {"status": "success", "message": "Medical report deleted"}

# ----------------------------------------------------
# 4. EMERGENCY QR ROUTES
# ----------------------------------------------------

@router.get("/qr", response_model=QRResponse)
def get_emergency_qr(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    qr = db.query(EmergencyQR).filter(
        EmergencyQR.user_id == current_user.id
    ).first()

    if not qr:
        # Generate initial secure token
        token = f"HS-E:{secrets.token_urlsafe(32)}"
        qr = EmergencyQR(
            user_id=current_user.id,
            token=token,
            is_active=True
        )
        db.add(qr)
        db.commit()
        db.refresh(qr)
    elif not qr.is_active:
        token = f"HS-E:{secrets.token_urlsafe(32)}"
        qr.token = token
        qr.is_active = True
        db.commit()
        db.refresh(qr)
        
    return qr

@router.post("/qr/regenerate", response_model=QRResponse)
def regenerate_emergency_qr(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    # Find existing QR record or create a new one if not found
    qr = db.query(EmergencyQR).filter(EmergencyQR.user_id == current_user.id).first()
    new_token = f"HS-E:{secrets.token_urlsafe(32)}"
    
    if not qr:
        qr = EmergencyQR(
            user_id=current_user.id,
            token=new_token,
            is_active=True
        )
        db.add(qr)
    else:
        # Invalidate old sessions by updating token
        qr.token = new_token
        qr.is_active = True
        
    db.commit()
    db.refresh(qr)
    return qr

# ----------------------------------------------------
# 5. EMERGENCY ACCESS FOUNDATION
# ----------------------------------------------------

@router.get("/emergency-access/active", response_model=List[EmergencyAccessResponse])
def get_active_emergency_accesses(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    active_records = db.query(EmergencyAccess).filter(
        EmergencyAccess.patient_id == current_user.id,
        EmergencyAccess.status == "active",
        EmergencyAccess.expires_at > datetime.utcnow()
    ).all()

    response_list = []
    for access in active_records:
        response_list.append(
            EmergencyAccessResponse(
                id=access.id,
                doctor_name=access.doctor.full_name,
                doctor_email=access.doctor.email,
                status=access.status,
                granted_at=access.granted_at,
                expires_at=access.expires_at,
                revoked_at=access.revoked_at
            )
        )
    return response_list

@router.post("/emergency-access/revoke/{access_id}")
def revoke_emergency_access(
    access_id: int,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    access = db.query(EmergencyAccess).filter(
        EmergencyAccess.id == access_id,
        EmergencyAccess.patient_id == current_user.id
    ).first()

    if not access:
        raise HTTPException(status_code=404, detail="Emergency access record not found")

    access.status = "revoked"
    access.revoked_at = datetime.utcnow()
    db.commit()
    return {"status": "success", "message": "Doctor access successfully revoked"}

@router.get("/emergency-access/history", response_model=List[EmergencyAccessResponse])
def get_emergency_access_history(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    # Retrieve all accesses (active, revoked, expired)
    all_records = db.query(EmergencyAccess).filter(
        EmergencyAccess.patient_id == current_user.id
    ).order_by(EmergencyAccess.granted_at.desc()).all()

    response_list = []
    for access in all_records:
        # Determine if active has naturally expired
        current_status = access.status
        if current_status == "active" and access.expires_at < datetime.utcnow():
            current_status = "expired"

        response_list.append(
            EmergencyAccessResponse(
                id=access.id,
                doctor_name=access.doctor.full_name,
                doctor_email=access.doctor.email,
                status=current_status,
                granted_at=access.granted_at,
                expires_at=access.expires_at,
                revoked_at=access.revoked_at
            )
        )
    return response_list

def calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    # Earth radius in kilometers
    R = 6371.0
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0)**2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    
    return round(R * c, 2) # Rounded to 2 decimal places

@router.get("/nearby-providers", response_model=List[HealthcareProviderResponse])
def get_nearby_providers(
    latitude: float,
    longitude: float,
    radius_km: float = 50.0,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    # Retrieve all providers
    all_providers = db.query(HealthcareProvider).all()
    
    nearby_list = []
    for provider in all_providers:
        dist = calculate_haversine_distance(latitude, longitude, provider.latitude, provider.longitude)
        if dist <= radius_km:
            nearby_list.append(
                HealthcareProvider(
                    id=provider.id,
                    name=provider.name,
                    specialization=provider.specialization,
                    phone_number=provider.phone_number,
                    latitude=provider.latitude,
                    longitude=provider.longitude,
                    availability_status=provider.availability_status,
                    # Dynamic property for sorting and serialization
                )
            )
            # Add distance property on provider object dynamically
            setattr(nearby_list[-1], "distance", dist)
            
    # Sort by distance (ascending)
    nearby_list.sort(key=lambda x: getattr(x, "distance"))
    if radius_km > 50.0:
        nearby_list = nearby_list[:5]
    return nearby_list

# ----------------------------------------------------
# 6. MEDICATION REMINDER ROUTES
# ----------------------------------------------------

@router.get("/reminders", response_model=List[ReminderResponse])
def get_reminders(
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    """Retrieve all medication reminders belonging strictly to the current patient."""
    return db.query(MedicationReminder).filter(
        MedicationReminder.user_id == current_user.id
    ).order_by(MedicationReminder.created_at.desc()).all()

@router.post("/reminders", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
def create_reminder(
    payload: ReminderCreate,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    """Create a new medication reminder for the current patient."""
    reminder = MedicationReminder(
        user_id=current_user.id,
        medication_name=payload.medication_name.strip(),
        dosage=payload.dosage.strip(),
        frequency=payload.frequency.strip(),
        reminder_times=payload.reminder_times.strip(),
        start_date=payload.start_date.strip() if payload.start_date else None,
        end_date=payload.end_date.strip() if payload.end_date else None,
        is_active=payload.is_active,
        notes=payload.notes.strip() if payload.notes else None
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder

@router.put("/reminders/{reminder_id}", response_model=ReminderResponse)
def update_reminder(
    reminder_id: int,
    payload: ReminderUpdate,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    """Update a medication reminder with strict ownership check."""
    reminder = db.query(MedicationReminder).filter(
        MedicationReminder.id == reminder_id,
        MedicationReminder.user_id == current_user.id
    ).first()

    if not reminder:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")

    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if isinstance(value, str):
            setattr(reminder, key, value.strip())
        else:
            setattr(reminder, key, value)

    reminder.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(reminder)
    return reminder

@router.patch("/reminders/{reminder_id}/toggle", response_model=ReminderResponse)
def toggle_reminder(
    reminder_id: int,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    """Toggle a medication reminder between enabled and disabled."""
    reminder = db.query(MedicationReminder).filter(
        MedicationReminder.id == reminder_id,
        MedicationReminder.user_id == current_user.id
    ).first()

    if not reminder:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")

    reminder.is_active = not reminder.is_active
    reminder.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(reminder)
    return reminder

@router.delete("/reminders/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    """Delete a medication reminder with strict ownership check."""
    reminder = db.query(MedicationReminder).filter(
        MedicationReminder.id == reminder_id,
        MedicationReminder.user_id == current_user.id
    ).first()

    if not reminder:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")

    db.delete(reminder)
    db.commit()
    return {"status": "success", "message": "Medication reminder deleted successfully"}

# ----------------------------------------------------
# 7. AI HEALTH ASSISTANT ROUTE
# ----------------------------------------------------

@router.post("/ai-chat", response_model=AIChatResponse)
def ai_chat(
    payload: AIChatRequest,
    current_user: User = Depends(require_role(["patient"])),
    db: Session = Depends(get_db)
):
    """
    Patient educational AI chat endpoint.
    Passes sanitized, non-sensitive context to the backend AI service.
    Backend transparently delegates to Gemini API or local educational engine.
    """
    # Build minimal non-sensitive patient context
    med_profile = db.query(PatientMedicalProfile).filter(
        PatientMedicalProfile.user_id == current_user.id
    ).first()

    patient_ctx = {}
    if med_profile:
        if med_profile.blood_group:
            patient_ctx["blood_group"] = med_profile.blood_group
        if med_profile.allergies:
            patient_ctx["allergies"] = med_profile.allergies
        if med_profile.conditions:
            patient_ctx["conditions"] = med_profile.conditions

    ai_reply = generate_health_assistant_response(payload.query, patient_context=patient_ctx)
    return AIChatResponse(status="success", response=ai_reply)


