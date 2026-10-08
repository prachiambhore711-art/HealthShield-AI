#!/usr/bin/env bash
# ==============================================================================
# HealthShield AI — AWS EC2 (Ubuntu Linux) Deployment Setup Script
# ==============================================================================
set -e

echo "=== Installing system dependencies ==="
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv libpq-dev curl nginx

echo "=== Creating Python virtual environment ==="
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

echo "=== Creating systemd service ==="
CURRENT_DIR=$(pwd)
CURRENT_USER=$(whoami)

sudo bash -c "cat > /etc/systemd/system/healthshield.service <<EOF
[Unit]
Description=HealthShield AI FastAPI Service
After=network.target

[Service]
User=${CURRENT_USER}
WorkingDirectory=${CURRENT_DIR}
EnvironmentFile=${CURRENT_DIR}/.env
ExecStart=${CURRENT_DIR}/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable healthshield
sudo systemctl restart healthshield

echo "=== HealthShield AI service started ==="
sudo systemctl status healthshield --no-pager
