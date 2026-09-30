import re
from typing import Optional
from pydantic import BaseModel, Field, field_validator

class UserRegister(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    email: str
    phone_number: str
    password: str = Field(..., min_length=8)
    role: str = Field(..., description="'patient' or 'doctor'")
    specialization: Optional[str] = None
    professional_id: Optional[str] = None

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        v = v.strip().lower()
        if not re.match(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$", v):
            raise ValueError("Invalid email format")
        return v

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        # Strip all whitespace
        cleaned = re.sub(r"\s+", "", v)
        # Verify it has digits and option to start with +
        if not re.match(r"^\+?[1-9]\d{9,14}$", cleaned):
            raise ValueError("Invalid phone format (e.g. +919876543210)")
        return cleaned

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        role_cleaned = v.strip().lower()
        if role_cleaned not in ["patient", "doctor"]:
            raise ValueError("Role must be 'patient' or 'doctor'")
        return role_cleaned

class UserLogin(BaseModel):
    email_or_phone: str = Field(..., min_length=3)
    password: str = Field(..., min_length=1)
    role: Optional[str] = Field(None, description="Requested login role: 'patient', 'doctor', or 'admin'")

class OTPVerify(BaseModel):
    email_or_phone: str = Field(..., min_length=3)
    code: str = Field(..., min_length=6, max_length=6)
    purpose: str = Field(..., description="'register' or 'reset'")

class OTPLinkRequest(BaseModel):
    email_or_phone: str = Field(..., min_length=3)

class PasswordReset(BaseModel):
    email_or_phone: str = Field(..., min_length=3)
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    full_name: str
    doctor_verification_status: str

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone_number: str
    role: str
    account_status: str
    doctor_verification_status: str

    class Config:
        from_attributes = True
