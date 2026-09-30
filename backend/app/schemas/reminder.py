from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class ReminderCreate(BaseModel):
    medication_name: str = Field(..., min_length=1, max_length=255)
    dosage: str = Field(..., min_length=1, max_length=100)
    frequency: str = Field(..., min_length=1, max_length=100)
    reminder_times: str = Field(..., min_length=1, max_length=255)  # e.g., "08:00, 20:00"
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: bool = True
    notes: Optional[str] = None

class ReminderUpdate(BaseModel):
    medication_name: Optional[str] = Field(None, min_length=1, max_length=255)
    dosage: Optional[str] = Field(None, min_length=1, max_length=100)
    frequency: Optional[str] = Field(None, min_length=1, max_length=100)
    reminder_times: Optional[str] = Field(None, min_length=1, max_length=255)
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = None

class ReminderResponse(BaseModel):
    id: int
    user_id: int
    medication_name: str
    dosage: str
    frequency: str
    reminder_times: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: bool
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
