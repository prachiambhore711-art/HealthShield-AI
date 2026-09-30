import os
import smtplib
from abc import ABC, abstractmethod
from datetime import datetime
from email.message import EmailMessage
from typing import Optional

# Resolve root directory for backend.log
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
LOG_FILE_PATH = os.path.join(PROJECT_ROOT, "backend.log")

class NotificationService(ABC):
    """
    Abstract interface for HealthShield AI notification delivery.
    Isolates auth modules from specific delivery APIs (SMS/Email).
    """
    @abstractmethod
    def send_otp(self, destination: str, code: str, purpose: str) -> bool:
        """Send a 6-digit OTP code to a destination email or phone number."""
        pass

def mask_identifier(destination: str) -> str:
    """Mask email or phone number for safe development logging."""
    if not destination:
        return "***"
    clean = destination.strip()
    if "@" in clean:
        parts = clean.split("@", 1)
        name, domain = parts[0], parts[1]
        masked_name = name[0] + "***" if len(name) > 1 else name + "***"
        return f"{masked_name}@{domain}"
    else:
        # Phone number
        if len(clean) > 4:
            return clean[:2] + "****" + clean[-2:]
        return "****"

def append_to_backend_log(destination: str, code: str, purpose: str):
    """Write OTP directly to backend.log in the project root for easy developer access."""
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE_PATH, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] [OTP] {purpose.upper()} for {destination} -> OTP CODE: {code}\n")
    except Exception as e:
        print(f"[LOG_ERROR] Could not write to {LOG_FILE_PATH}: {e}")

def try_send_smtp_email(to_email: str, code: str, purpose: str) -> bool:
    """
    Sends real email via SMTP if credentials are configured in environment variables.
    Works with Gmail (using an App Password), Outlook, SendGrid, or custom SMTP servers.
    """
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))

    if not smtp_user or not smtp_password:
        return False

    try:
        msg = EmailMessage()
        msg["Subject"] = f"HealthShield AI - Your {purpose.capitalize()} Verification Code"
        msg["From"] = f"HealthShield AI <{smtp_user}>"
        msg["To"] = to_email

        text_body = f"""Hello,

Your HealthShield AI verification code is: {code}

This code is valid for 5 minutes. Please do not share this OTP with anyone.

HealthShield AI Security Team
"""
        html_body = f"""
        <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 12px; background: #ffffff;">
            <div style="text-align: center; margin-bottom: 20px;">
                <h2 style="color: #00A86B; margin: 0; font-size: 24px;">HealthShield AI</h2>
                <p style="color: #666; font-size: 13px; margin: 4px 0 0 0;">Secure Emergency Health Records</p>
            </div>
            <p style="font-size: 14px; color: #333; line-height: 1.5;">
                Please use the one-time verification code below to complete your <strong>{purpose}</strong> verification:
            </p>
            <div style="text-align: center; margin: 28px 0;">
                <div style="display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1A2B3C; background: #E6FDF4; padding: 14px 28px; border-radius: 10px; border: 1.5px solid #00A86B;">
                    {code}
                </div>
            </div>
            <p style="font-size: 12px; color: #777; line-height: 1.4;">
                This code is valid for <strong>5 minutes</strong>. If you did not request this code, you can safely ignore this email.
            </p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0 16px 0;" />
            <p style="font-size: 11px; color: #aaa; text-align: center; margin: 0;">
                HealthShield AI Automated Security Notification &bull; Do not reply
            </p>
        </div>
        """
        msg.set_content(text_body)
        msg.add_alternative(html_body, subtype="html")

        with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
            server.starttls()
            server.login(smtp_user, smtp_password)
            server.send_message(msg)

        print(f"[EMAIL_DISPATCH] Real email successfully delivered to {to_email}")
        return True
    except Exception as e:
        print(f"[EMAIL_ERROR] Failed to send real email to {to_email}: {e}")
        return False

class UnifiedNotificationService(NotificationService):
    def send_otp(self, destination: str, code: str, purpose: str) -> bool:
        masked_dest = mask_identifier(destination)
        
        # 1. Always record in backend.log in the project root
        append_to_backend_log(destination, code, purpose)

        # 2. Console notification box
        print(f"[OTP_DEBUG] OTP generated for {masked_dest}: {code}")
        print("\n" + "=" * 60)
        print(" HEALTHSHIELD AI - OUTBOUND NOTIFICATION")
        print(f" [To]:      {destination}")
        print(f" [Purpose]: {purpose.upper()} VERIFICATION")
        print(f" [OTP]:     {code}")
        print(f" [Saved]:   Logged to backend.log")
        print("=" * 60 + "\n")

        # 3. Attempt real email dispatch if destination is an email address
        if "@" in destination:
            sent = try_send_smtp_email(destination, code, purpose)
            if not sent:
                print(f"[EMAIL_INFO] Real email not sent (SMTP credentials not configured in environment).")
                print(f"[EMAIL_INFO] To enable real delivery to {destination}, set SMTP_USER and SMTP_PASSWORD in .env")

        return True

# Global service provider instance
notification_service: NotificationService = UnifiedNotificationService()
