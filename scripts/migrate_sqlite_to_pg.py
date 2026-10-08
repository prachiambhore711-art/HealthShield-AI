"""
HealthShield AI — Non-Destructive SQLite to Neon PostgreSQL Data Migration Script
================================================================================
Transfers existing development data from local SQLite database into Neon PostgreSQL
without modifying or corrupting the source SQLite database.

Usage:
    py scripts/migrate_sqlite_to_pg.py --pg-url "postgresql://neondb_owner:...@ep-....aws.neon.tech/neondb?sslmode=require"
    OR
    Set DATABASE_URL in your environment / .env and run:
    py scripts/migrate_sqlite_to_pg.py
"""

import sys
import os
import argparse
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker

# Add project root to sys.path
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from backend.app.core.database import Base
# Register all models
from backend.app.models.user import User
from backend.app.models.patient import (
    PatientMedicalProfile,
    MedicalReport,
    EmergencyContact,
    EmergencyQR,
    EmergencyAccess
)
from backend.app.models.doctor import DoctorProfile
from backend.app.models.healthcare_provider import HealthcareProvider
from backend.app.models.reminder import MedicationReminder
from backend.app.models.otp import OTP
from backend.app.models.audit_log import AuditLog

# Dependency order for safe foreign key insertion
MODEL_CLASSES = [
    User,
    PatientMedicalProfile,
    DoctorProfile,
    HealthcareProvider,
    EmergencyContact,
    EmergencyQR,
    EmergencyAccess,
    MedicalReport,
    MedicationReminder,
    OTP,
    AuditLog
]

def migrate(sqlite_url: str, pg_url: str):
    print("=" * 70)
    print(" HEALTHSHIELD AI — SQLITE TO NEON POSTGRESQL DATA MIGRATION")
    print("=" * 70)

    if pg_url.startswith("postgres://"):
        pg_url = pg_url.replace("postgres://", "postgresql://", 1)

    print(f"[*] Source (SQLite):      {sqlite_url}")
    print(f"[*] Destination (Postgres): {pg_url.split('@')[-1] if '@' in pg_url else pg_url}")

    sqlite_engine = create_engine(sqlite_url, connect_args={"check_same_thread": False})
    pg_engine = create_engine(pg_url, pool_pre_ping=True)

    # 1. Create tables in PostgreSQL if they don't already exist
    print("\n[1/3] Ensuring PostgreSQL tables are created...")
    Base.metadata.create_all(bind=pg_engine)
    print("      Tables verified successfully.")

    SqliteSession = sessionmaker(bind=sqlite_engine)
    PgSession = sessionmaker(bind=pg_engine)

    sqlite_db = SqliteSession()
    pg_db = PgSession()

    try:
        print("\n[2/3] Migrating table rows in foreign-key safe order...")
        total_migrated = 0

        for model in MODEL_CLASSES:
            table_name = model.__tablename__
            rows = sqlite_db.query(model).all()
            if not rows:
                print(f"      - {table_name:26} : 0 rows (Skipped)")
                continue

            # Check existing count in destination
            existing_count = pg_db.query(model).count()
            if existing_count > 0:
                print(f"      - {table_name:26} : {len(rows)} rows found, destination already has {existing_count} rows. (Merging/Skipping duplicates)")
                # Merge row by row to prevent duplicate primary key collisions
                inserted = 0
                for r in rows:
                    try:
                        pg_db.merge(r)
                        inserted += 1
                    except Exception as e:
                        pg_db.rollback()
                        print(f"        [!] Warning on row {r}: {e}")
                pg_db.commit()
                print(f"      - {table_name:26} : {inserted} rows merged successfully.")
                total_migrated += inserted
            else:
                # Direct bulk insert
                for r in rows:
                    pg_db.merge(r)
                pg_db.commit()
                print(f"      - {table_name:26} : {len(rows)} rows transferred.")
                total_migrated += len(rows)

        print(f"\n      Total records migrated: {total_migrated}")

        # 3. Synchronize PostgreSQL serial sequences so new inserts don't collide
        print("\n[3/3] Synchronizing PostgreSQL sequence generators...")
        with pg_engine.connect() as conn:
            for model in MODEL_CLASSES:
                table_name = model.__tablename__
                try:
                    query = text(f"""
                        SELECT setval(
                            pg_get_serial_sequence('{table_name}', 'id'),
                            COALESCE((SELECT MAX(id) FROM {table_name}), 1),
                            (SELECT COUNT(*) FROM {table_name}) > 0
                        );
                    """)
                    conn.execute(query)
                    conn.commit()
                except Exception:
                    # Table might not use a serial id sequence
                    pass

        print("      PostgreSQL sequences synchronized successfully.")

        print("\n" + "=" * 70)
        print(" [SUCCESS] Neon PostgreSQL database is now ready for production!")
        print("=" * 70)

    except Exception as e:
        print(f"\n[ERROR] Migration failed: {e}")
        pg_db.rollback()
        raise e
    finally:
        sqlite_db.close()
        pg_db.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate SQLite data to Neon PostgreSQL.")
    parser.add_argument("--sqlite-url", default=None, help="Source SQLite URL (defaults to ./healthshield.db)")
    parser.add_argument("--pg-url", default=None, help="Destination Neon PostgreSQL URL")

    args = parser.parse_args()

    sqlite_source = args.sqlite_url or f"sqlite:///{os.path.join(PROJECT_ROOT, 'healthshield.db')}"
    pg_dest = args.pg_url or os.getenv("DATABASE_URL")

    if not pg_dest or "sqlite" in pg_dest.lower():
        print("[ERROR] Please provide your Neon PostgreSQL connection string:")
        print("  py scripts/migrate_sqlite_to_pg.py --pg-url \"postgresql://user:pass@ep-...neon.tech/neondb?sslmode=require\"")
        print("  OR set DATABASE_URL environment variable to your Neon connection string.")
        sys.exit(1)

    migrate(sqlite_source, pg_dest)
