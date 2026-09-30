from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class DoctorDetailResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone_number: str
    professional_id: Optional[str] = None
    specialization: Optional[str] = None
    doctor_verification_status: str
    account_status: str

    class Config:
        from_attributes = True

class UserSearchResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone_number: str
    role: str
    account_status: str
    doctor_verification_status: str

    class Config:
        from_attributes = True

class AuditLogResponse(BaseModel):
    id: int
    admin_id: int
    admin_name: str
    target_user_id: int
    target_user_name: str
    action: str
    previous_status: Optional[str] = None
    new_status: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
