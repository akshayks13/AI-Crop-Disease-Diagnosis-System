import logging
import random
import smtplib
from email.message import EmailMessage

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


def _normalized_smtp_password() -> str:
    """Normalize SMTP password (Gmail app passwords are often displayed with spaces)."""
    return (settings.smtp_password or "").replace(" ", "").strip()


def _send_otp_email(email: str, otp: str) -> None:
    """Send OTP via SMTP."""
    msg = EmailMessage()
    msg["Subject"] = "Your OTP Code - AI Crop Disease Diagnosis"
    msg["From"] = settings.smtp_from_email or settings.smtp_username
    msg["To"] = email

    sender_name = settings.smtp_from_name
    body = (
        f"Hello,\n\n"
        f"Your OTP code is: {otp}\n"
        f"This code is valid for a short time.\n\n"
        f"If you did not request this code, you can ignore this email.\n\n"
        f"Thanks,\n{sender_name}"
    )
    msg.set_content(body)

    if settings.smtp_use_ssl:
        with smtplib.SMTP_SSL(settings.smtp_host, settings.smtp_port, timeout=20) as server:
            if settings.smtp_username:
                server.login(settings.smtp_username.strip(), _normalized_smtp_password())
            server.send_message(msg)
        return

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as server:
        if settings.smtp_use_tls:
            server.starttls()
        if settings.smtp_username:
            server.login(settings.smtp_username.strip(), _normalized_smtp_password())
        server.send_message(msg)

def generate_and_send_otp(email: str) -> str:
    """
    Generate a 6-digit OTP and send it.
    Returns the generated OTP.
    """
    otp = "".join([str(random.randint(0, 9)) for _ in range(6)])

    smtp_ready = bool(
        settings.smtp_host and
        settings.smtp_port and
        (settings.smtp_from_email or settings.smtp_username)
    )

    if smtp_ready:
        try:
            _send_otp_email(email, otp)
            logger.info(f"OTP email sent to {email}")
            return otp
        except Exception as exc:
            logger.error(f"Failed to send OTP email to {email}: {exc}")
            if not settings.debug:
                raise RuntimeError("OTP email delivery failed")

    if settings.debug:
        print("\n" + "=" * 44)
        print(f"OTP for {email}: {otp}")
        print("=" * 44 + "\n")
        logger.warning(f"SMTP not configured; OTP email skipped for {email} (debug mode)")
        return otp

    raise RuntimeError("SMTP is not configured for OTP delivery")
    
    return otp
