from sqlalchemy import Column, Integer, String, DateTime, func
from backend.app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone_number = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="patient", nullable=False)  # 'patient' or 'doctor'
    account_status = Column(String, default="inactive", nullable=False)  # 'inactive' or 'active'
    doctor_verification_status = Column(String, default="not_applicable", nullable=False)  # 'not_applicable', 'pending', 'verified'
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
