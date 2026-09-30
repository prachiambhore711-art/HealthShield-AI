from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship as sa_relationship, backref as sa_backref
from backend.app.core.database import Base

class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True, nullable=False)
    professional_id = Column(String, unique=True, index=True, nullable=True) # Medical License/Registration ID
    specialization = Column(String, nullable=True) # Cardiologist, etc.
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)

    user = sa_relationship("User", backref=sa_backref("doctor_profile", uselist=False, cascade="all, delete-orphan"))
