import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

try:
    from dotenv import load_dotenv, find_dotenv

    # Search upwards from current directory for .env
    env_path = find_dotenv(usecwd=True)
    if env_path:
        load_dotenv(env_path)
    else:
        # Also check project root specifically
        root_env = os.path.abspath(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "..",
                "..",
                ".env",
            )
        )
        if os.path.exists(root_env):
            load_dotenv(root_env)
except Exception:
    pass


# Fetch database URL from environment;
# fallback to local SQLite for development
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./healthshield.db",
).strip()


# Normalize PostgreSQL dialect/driver.
# Render/Neon may provide:
#   postgres://...
#   postgresql://...
# We explicitly use the installed psycopg2-binary driver.
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace(
        "postgres://",
        "postgresql+psycopg2://",
        1,
    )
elif DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace(
        "postgresql://",
        "postgresql+psycopg2://",
        1,
    )


# Configure engine arguments based on database dialect
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
    )
else:
    # PostgreSQL (Neon / cloud deployment)
    # pool_pre_ping checks connection liveness before queries.
    # pool_recycle refreshes stale pooled connections.
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_recycle=300,
        pool_size=10,
        max_overflow=20,
    )


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()