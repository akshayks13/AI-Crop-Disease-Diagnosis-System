"""
Input Validators
"""
import re
from typing import Optional


def validate_email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def validate_phone(phone: str) -> bool:
    """Validate phone number format."""
    # Allow various formats: +1234567890, 123-456-7890, etc.
    pattern = r'^[\+]?[(]?[0-9]{1,3}[)]?[-\s\.]?[(]?[0-9]{1,3}[)]?[-\s\.]?[0-9]{3,6}[-\s\.]?[0-9]{3,6}$'
    return bool(re.match(pattern, phone))


def sanitize_filename(filename: str) -> str:
    """Sanitize filename for safe storage."""
    # Remove or replace unsafe characters
    safe_chars = re.sub(r'[^\w\-_\.]', '_', filename)
    # Limit length
    return safe_chars[:100]


def validate_crop_type(crop_type: str) -> Optional[str]:
    """Validate and normalize crop type."""
    valid_crops = {
        'tomato', 'potato', 'corn', 'wheat', 'rice',
        'cotton', 'soybean', 'sugarcane', 'vegetables',
        'fruits', 'pulses', 'oilseeds'
    }
    normalized = crop_type.lower().strip()
    return normalized if normalized in valid_crops else None
