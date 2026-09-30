from sqlalchemy import Column, Integer, String, Float, DateTime, func
from backend.app.core.database import Base

class HealthcareProvider(Base):
    __tablename__ = "healthcare_providers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    specialization = Column(String, nullable=False)
    phone_number = Column(String, nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    availability_status = Column(String, default="available")
