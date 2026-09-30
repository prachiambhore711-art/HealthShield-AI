from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

class DoctorProfileResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone_number: str
    role: str
    professional_id: Optional[str] = None
    specialization: Optional[str] = None
    doctor_verification_status: str
    account_status: str

    class Config:
        from_attributes = True

class DoctorProfileUpdate(BaseModel):
    professional_id: str = Field(..., min_length=2, max_length=50)
    specialization: str = Field(..., min_length=2, max_length=100)

class EmergencyAccessRequest(BaseModel):
    token: str = Field(..., min_length=5)

class EmergencyAccessActiveSession(BaseModel):
    id: int
    patient_name: str
    patient_email: str
    granted_at: datetime
    expires_at: datetime
    status: str

    class Config:
        from_attributes = True

class EmergencyAccessHistoryItem(BaseModel):
    id: int
    patient_name: str
    granted_at: datetime
    status: str

    class Config:
        from_attributes = True
