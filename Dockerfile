# HealthShield AI - Production Container
FROM python:3.11-slim

# Prevent Python from writing pyc files and buffer output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies (curl for healthcheck, libpq for Postgres)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application source
COPY backend ./backend

# Pre-create medical report storage directory
RUN mkdir -p backend/storage/reports

# Set environment defaults
ENV PORT=8000
ENV HOST=0.0.0.0
ENV STORAGE_DIR=/app/backend/storage/reports

# Expose default port
EXPOSE 8000

# Health check probe for AWS container runners
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/health || exit 1

# Start Uvicorn server bound to 0.0.0.0 and dynamic PORT
CMD ["sh", "-c", "uvicorn backend.app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
