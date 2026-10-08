from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.core.database import Base, engine
from backend.app.api.auth import router as auth_router
from backend.app.api.patient import router as patient_router

# Import patient models to register them in SQLAlchemy Base metadata
from backend.app.models.patient import (
    PatientMedicalProfile,
    MedicalReport,
    EmergencyContact,
    EmergencyQR,
    EmergencyAccess
)
from backend.app.models.doctor import DoctorProfile
from backend.app.models.audit_log import AuditLog
from backend.app.models.healthcare_provider import HealthcareProvider
from backend.app.models.reminder import MedicationReminder
from backend.app.api.doctor import router as doctor_router
from backend.app.api.admin import router as admin_router
from backend.app.api.public import router as public_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create SQLite database tables if they do not exist
    Base.metadata.create_all(bind=engine)

    # Seed Admin User and Healthcare Providers
    from backend.app.core.database import SessionLocal
    from backend.app.models.user import User
    from backend.app.core.security import hash_password
    
    db = SessionLocal()
    try:
        # Seed Admin
        admin_email = "admin@healthshield.ai"
        admin_exists = db.query(User).filter(User.email == admin_email).first()
        if not admin_exists:
            import os
            dev_admin_pass = os.getenv("DEV_ADMIN_PASSWORD", "AdminSafePass123!")
            admin_user = User(
                email=admin_email,
                full_name="System Admin",
                phone_number="+919999999999",
                password_hash=hash_password(dev_admin_pass),
                role="admin",
                account_status="active",
                doctor_verification_status="not_applicable"
            )
            db.add(admin_user)
            db.commit()
            print("Admin user seeded successfully!")

        # Seed Healthcare Providers if empty
        if db.query(HealthcareProvider).count() == 0:
            providers = [
                # Mountain View / Googleplex area (typical emulator position)
                HealthcareProvider(
                    name="El Camino Hospital",
                    specialization="General Hospital & Emergency Care",
                    phone_number="+1 650-940-7000",
                    latitude=37.3719,
                    longitude=-122.0684,
                    availability_status="available"
                ),
                HealthcareProvider(
                    name="Mountain View Medical Group",
                    specialization="Family Medicine",
                    phone_number="+1 650-988-8200",
                    latitude=37.4035,
                    longitude=-122.0784,
                    availability_status="available"
                ),
                HealthcareProvider(
                    name="Palo Alto Medical Foundation",
                    specialization="Multi-specialty Clinic",
                    phone_number="+1 650-934-7000",
                    latitude=37.4184,
                    longitude=-122.0880,
                    availability_status="available"
                ),
                # India Pune/Mumbai area
                HealthcareProvider(
                    name="Ruby Hall Clinic",
                    specialization="Cardiology & Trauma Care",
                    phone_number="+91 20 6645 5100",
                    latitude=18.5312,
                    longitude=73.8741,
                    availability_status="available"
                ),
                HealthcareProvider(
                    name="Jehangir Hospital",
                    specialization="Neurology & Orthopedics",
                    phone_number="+91 20 6681 9999",
                    latitude=18.5298,
                    longitude=73.8732,
                    availability_status="available"
                ),
                HealthcareProvider(
                    name="Inlaks & Budhrani Hospital",
                    specialization="Oncology & General Surgery",
                    phone_number="+91 20 6609 9999",
                    latitude=18.5360,
                    longitude=73.8931,
                    availability_status="available"
                )
            ]
            db.bulk_save_objects(providers)
            db.commit()
            print("Healthcare providers seeded successfully!")
    except Exception as e:
        print(f"Error seeding DB elements: {e}")
    finally:
        db.close()

    yield

app = FastAPI(
    title="HealthShield AI Backend",
    description="Backend API services supporting registration, authentication, and secure login for HealthShield AI.",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for development and cross-platform testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Authentication router
app.include_router(auth_router)

# Mount Patient router
app.include_router(patient_router)

# Mount Doctor router
app.include_router(doctor_router)

# Mount Admin router
app.include_router(admin_router)

# Mount Public Emergency router
app.include_router(public_router)

@app.get("/")
def root():
    return {
        "status": "online",
        "app": "HealthShield AI API",
        "version": "1.0.0"
    }

@app.get("/health")
@app.get("/api/health")
def health_check():
    """Health check endpoint for AWS Load Balancer / App Runner / ECS container probes."""
    db_status = "healthy"
    try:
        from backend.app.core.database import SessionLocal
        from sqlalchemy import text
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "online",
        "database": db_status,
        "app": "HealthShield AI API",
        "version": "1.0.0"
    }
