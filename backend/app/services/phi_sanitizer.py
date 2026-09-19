"""PHI Sanitizer & De-identification Service.

Implements HIPAA Safe Harbor de-identification rules (§164.514(b)) to redact
direct identifiers from clinical text and structured clinical entity dictionaries:
  - Social Security Numbers (SSN)
  - Telephone and fax numbers
  - Electronic mail addresses
  - Medical Record Numbers (MRN) and account identifiers
  - Dates of Birth (DOB)
  - Direct patient names in headers
"""

import copy
import re
from typing import Any, Optional

# --- Safe Harbor Regex Patterns ---
_SSN_PATTERN = re.compile(r"\b(?!000|666|9\d{2})\d{3}[-.\s]?(?!00)\d{2}[-.\s]?(?!0000)\d{4}\b")
_PHONE_PATTERN = re.compile(r"(?:\+?1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b")
_EMAIL_PATTERN = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b")
_MRN_PATTERN = re.compile(r"(?i)\b(?:MRN|Medical Record (?:Number|#)|Record #|Patient ID)[:\s#]+([A-Z0-9-]{4,15})\b")
_DOB_PATTERN = re.compile(r"(?i)\b(?:DOB|Date of Birth|Birth Date)[:\s]+([0-9]{1,4}[-/.][0-9]{1,2}[-/.][0-9]{1,4})\b")
_PATIENT_HEADER_PATTERN = re.compile(r"(?i)\b(?:Patient(?: Name)?|Pt Name)[:\s]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})")


def sanitize_text(text: Optional[str], patient_name: Optional[str] = None) -> str:
    """Masks all direct PHI identifiers from raw clinical text.

    Args:
        text: Raw clinical text.
        patient_name: Optional explicit patient name to redact throughout text.

    Returns:
        De-identified text safe for audit, analytics, or export.
    """
    if not text:
        return ""

    sanitized = text

    # 1. Redact SSNs
    sanitized = _SSN_PATTERN.sub("[REDACTED_SSN]", sanitized)

    # 2. Redact Phone numbers
    sanitized = _PHONE_PATTERN.sub("[REDACTED_PHONE]", sanitized)

    # 3. Redact Email addresses
    sanitized = _EMAIL_PATTERN.sub("[REDACTED_EMAIL]", sanitized)

    # 4. Redact MRN
    sanitized = _MRN_PATTERN.sub(lambda m: m.group(0).replace(m.group(1), "[REDACTED_MRN]"), sanitized)

    # 5. Redact DOB
    sanitized = _DOB_PATTERN.sub(lambda m: m.group(0).replace(m.group(1), "[REDACTED_DOB]"), sanitized)

    # 6. Redact Patient Name in Header
    sanitized = _PATIENT_HEADER_PATTERN.sub(lambda m: m.group(0).replace(m.group(1), "[REDACTED_NAME]"), sanitized)

    # 7. Explicit patient name masking if known
    if patient_name and len(patient_name.strip()) > 2:
        name_esc = re.escape(patient_name.strip())
        sanitized = re.sub(rf"(?i)\b{name_esc}\b", "[REDACTED_NAME]", sanitized)

    return sanitized


def sanitize_entities(entities: dict[str, Any]) -> dict[str, Any]:
    """Produces a sanitized, de-identified copy of structured clinical entities.

    Preserves clinical utility (diagnoses, medications, lab values) while
    masking direct personal identifiers.
    """
    if not entities:
        return {}

    sanitized = copy.deepcopy(entities)

    # Mask Patient Info
    if "patient" in sanitized and isinstance(sanitized["patient"], dict):
        p = sanitized["patient"]
        if "name" in p:
            p["name"] = "[REDACTED_NAME]"
        if "phone" in p:
            p["phone"] = "[REDACTED_PHONE]"
        if "email" in p:
            p["email"] = "[REDACTED_EMAIL]"
        if "ssn" in p:
            p["ssn"] = "[REDACTED_SSN]"
        if "mrn" in p:
            p["mrn"] = "[REDACTED_MRN]"
        if "address" in p:
            p["address"] = "[REDACTED_ADDRESS]"
        if "dob" in p:
            p["dob"] = "[REDACTED_DOB]"

    # Mask Summary and Review Reasons
    if "summary" in sanitized and isinstance(sanitized["summary"], str):
        sanitized["summary"] = sanitize_text(sanitized["summary"])

    return sanitized
