"""Reusable input validators. Each returns a cleaned value or raises ValidationError."""
import re
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from typing import Optional

from .exceptions import ValidationError

_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
_PHONE = re.compile(r"^\+?\d{7,15}$")


def required_text(value, field: str, max_len: int = 100) -> str:
    text = (value or "").strip()
    if not text:
        raise ValidationError(f"{field} cannot be empty.")
    if len(text) > max_len:
        raise ValidationError(f"{field} must be at most {max_len} characters.")
    return text


def optional_text(value, field: str, max_len: int = 255) -> Optional[str]:
    text = (value or "").strip()
    if not text:
        return None
    if len(text) > max_len:
        raise ValidationError(f"{field} must be at most {max_len} characters.")
    return text


def _to_int(value, field: str) -> int:
    try:
        return int(str(value).strip())
    except (ValueError, TypeError):
        raise ValidationError(f"{field} must be a whole number.") from None


def positive_int(value, field: str) -> int:
    number = _to_int(value, field)
    if number <= 0:
        raise ValidationError(f"{field} must be greater than 0.")
    return number


def non_negative_int(value, field: str) -> int:
    number = _to_int(value, field)
    if number < 0:
        raise ValidationError(f"{field} cannot be negative.")
    return number


def non_negative_decimal(value, field: str) -> Decimal:
    try:
        number = Decimal(str(value).strip())
    except (InvalidOperation, ValueError):
        raise ValidationError(f"{field} must be a number.") from None
    if not number.is_finite() or number < 0:
        raise ValidationError(f"{field} must be 0 or more.")
    return number.quantize(Decimal("0.01"))


def parse_date(value, field: str = "Date", allow_future: bool = False) -> date:
    """Accepts YYYY-MM-DD. A blank value means today."""
    text = (value or "").strip()
    if not text:
        return date.today()
    try:
        parsed = datetime.strptime(text, "%Y-%m-%d").date()
    except ValueError:
        raise ValidationError(f"{field} must be in YYYY-MM-DD format.") from None
    if parsed > date.today() and not allow_future:
        raise ValidationError(f"{field} cannot be in the future.")
    return parsed


def valid_email(value) -> Optional[str]:
    text = (value or "").strip()
    if not text:
        return None
    if not _EMAIL.match(text):
        raise ValidationError("Email address is not valid.")
    return text.lower()


def valid_phone(value) -> Optional[str]:
    text = (value or "").strip()
    if not text:
        return None
    digits = text.replace(" ", "").replace("-", "")
    if not _PHONE.match(digits):
        raise ValidationError("Phone must have 7-15 digits (optional leading +).")
    return digits
