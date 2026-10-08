"""
HealthShield AI — AWS Deployment Zip Packager
=============================================
Creates a clean, production-ready deploy-backend.zip package
suitable for direct upload to AWS Elastic Beanstalk or extraction on an AWS EC2 instance.

Excludes:
- .env and secrets
- local SQLite databases (*.db)
- virtual environments (venv, .venv)
- cache and logs
- frontend and mobile build artifacts
"""

import os
import zipfile
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUTPUT_ZIP = os.path.join(PROJECT_ROOT, "deploy-backend.zip")

EXCLUDE_DIRS = {
    ".git",
    ".idea",
    ".vscode",
    "__pycache__",
    "venv",
    ".venv",
    "frontend",
    "shelf",
    "admin_screens",
}

EXCLUDE_EXTS = {
    ".pyc",
    ".pyo",
    ".pyd",
    ".db",
    ".db.backup",
    ".sqlite",
    ".sqlite3",
    ".log",
    ".apk",
    ".aab",
    ".zip"
}

EXCLUDE_FILES = {
    ".env",
    "backend.log",
    "backend_server.log",
    "app-debug.apk"
}

def create_package():
    print("=" * 60)
    print(" HEALTHSHIELD AI — PACKAGING AWS BACKEND DEPLOYMENT ZIP")
    print("=" * 60)
    
    if os.path.exists(OUTPUT_ZIP):
        try:
            os.remove(OUTPUT_ZIP)
        except Exception:
            pass

    count = 0
    with zipfile.ZipFile(OUTPUT_ZIP, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(PROJECT_ROOT):
            # Prune excluded directories in-place
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith(".") and not d.startswith("frontend")]

            for file in files:
                if file in EXCLUDE_FILES or file.startswith(".env"):
                    continue
                _, ext = os.path.splitext(file)
                if ext.lower() in EXCLUDE_EXTS:
                    continue

                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, PROJECT_ROOT)

                # Only include backend, root deployment configs, and scripts
                if (
                    rel_path.startswith("backend") or
                    rel_path in {"Dockerfile", ".dockerignore", "Procfile", "apprunner.yaml", "requirements.txt"} or
                    rel_path.startswith("scripts")
                ):
                    zf.write(full_path, rel_path)
                    count += 1

    size_mb = os.path.getsize(OUTPUT_ZIP) / (1024 * 1024)
    print(f"[SUCCESS] Packaged {count} files into:")
    print(f"          {OUTPUT_ZIP} ({size_mb:.2f} MB)")
    print("=" * 60)

if __name__ == "__main__":
    create_package()
