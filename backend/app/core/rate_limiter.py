import time
from collections import defaultdict
from typing import Dict, List
from fastapi import HTTPException, Request, status

# In-memory dictionary mapping a composite key (IP/identifier/route) to timestamps of requests
# Structure: { key: [timestamp1, timestamp2, ...] }
_attempts_cache: Dict[str, List[float]] = defaultdict(list)

def is_rate_limited(key: str, limit: int, window_seconds: int) -> bool:
    """
    Check if a key has exceeded its limit in the given sliding window of seconds.
    Returns True if rate limited, False otherwise.
    """
    now = time.time()
    # Retain only timestamps that fall within the current sliding window
    timestamps = [t for t in _attempts_cache[key] if now - t < window_seconds]
    _attempts_cache[key] = timestamps
    
    if len(timestamps) >= limit:
        return True
    
    # Register the new request timestamp
    _attempts_cache[key].append(now)
    return False

def check_rate_limit(request: Request, identifier: str = None, limit: int = 5, window_seconds: int = 60):
    """
    Check rate limit for sensitive endpoints.
    Throws HTTP 429 if the request count exceeds the limit.
    """
    client_ip = request.client.host if request.client else "unknown"
    endpoint = request.url.path
    
    # Build unique compound key based on client IP, path, and optional identifier (like email/phone)
    key = f"rl:{client_ip}:{endpoint}"
    if identifier:
        key += f":{identifier}"
        
    if is_rate_limited(key, limit, window_seconds):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please wait and try again."
        )
