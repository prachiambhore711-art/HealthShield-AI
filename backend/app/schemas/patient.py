from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class MedicalProfileResponse(BaseModel):
    blood_group: Optional[str] = None
    height: Optional[str] = None
    weight: Optional[str] = None
    allergies: Optional[str] = None
    conditions: Optional[str] = None
    medications: Optional[str] = None
    critical_notes: Optional[str] = None

    class Config:
        from_attributes = True

class MedicalProfileUpdate(BaseModel):
    blood_group: Optional[str] = None
    height: Optional[str] = None
    weight: Optional[str] = None
    allergies: Optional[str] = None
    conditions: Optional[str] = None
    medications: Optional[str] = None
    critical_notes: Optional[str] = None

class EmergencyContactCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    relationship: str = Field(..., min_length=1, max_length=50)
    phone_number: str = Field(..., min_length=10, max_length=20)
    is_primary: bool = False

class EmergencyContactResponse(BaseModel):
    id: int
    name: str
    relationship: str
    phone_number: str
    is_primary: bool

    class Config:
        from_attributes = True

class ReportResponse(BaseModel):
    id: int
    title: str
    type: str
    report_date: str
    description: Optional[str] = None
    file_name: str
    created_at: datetime

    class Config:
        from_attributes = True

class QRResponse(BaseModel):
    token: str
    is_active: bool

    class Config:
        from_attributes = True

class EmergencyAccessResponse(BaseModel):
    id: int
    doctor_name: str
    doctor_email: str
    status: str
    granted_at: datetime
    expires_at: datetime
    revoked_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class HealthcareProviderResponse(BaseModel):
    id: int
    name: str
    specialization: str
    phone_number: Optional[str] = None
    latitude: float
    longitude: float
    availability_status: str
    distance: float

    class Config:
        from_attributes = True

class AIChatRequest(BaseModel):
    query: str

class AIChatResponse(BaseModel):
    status: str
    response: str
