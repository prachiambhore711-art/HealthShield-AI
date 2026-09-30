import os
from datetime import datetime, timedelta
from typing import Union, Any
import bcrypt
import jwt

# Fetch JWT Secret from environment variables
JWT_SECRET = os.getenv("JWT_SECRET")

# Ensure a secret is present, using a local dev fallback with a console warning if missing
if not JWT_SECRET:
    print("\n[WARNING] JWT_SECRET environment variable is missing. Using a fallback development key. Set JWT_SECRET in production!\n")
    JWT_SECRET = "healthshield_dev_fallback_secret_key_not_for_production_use"

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours for convenience in testing

def hash_password(password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    password_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt(rounds=12)
    hashed_bytes = bcrypt.hashpw(password_bytes, salt)
    return hashed_bytes.decode("utf-8")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a hashed password."""
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8")
        )
    except Exception:
        return False

def create_access_token(subject: Union[str, Any], expires_delta: timedelta = None) -> str:
    """Generate a JWT access token containing the subject."""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {"exp": expire, "sub": str(subject)}
    return jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)

def decode_access_token(token: str) -> Union[str, None]:
    """Decode a JWT access token and return the subject if valid."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        return payload.get("sub")
    except jwt.PyJWTError:
        return None
