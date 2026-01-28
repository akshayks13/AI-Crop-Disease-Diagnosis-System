import logging
import random

logger = logging.getLogger(__name__)

def generate_and_send_otp(email: str) -> str:
    """
    Generate a 6-digit OTP and send it (currently prints to console).
    Returns the generated OTP.
    """
    otp = "".join([str(random.randint(0, 9)) for _ in range(6)])
    
    # Send OTP (Print to console)
    print(f"\n{'='*44}")
    print(f"OTP for {email}: {otp}")
    print(f"{'='*44}\n")
    
    logger.info(f"OTP for {email}: {otp}")
    
    return otp
