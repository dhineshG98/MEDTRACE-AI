"""Clinical Negation Detection Service.

Identifies whether conditions, symptoms, findings, or allergens are explicitly
negated in clinical text (e.g., 'no acute abnormality', 'patient denies diabetes',
'NKDA', 'no known drug allergies').
"""

import re
from typing import Optional

# Common pre-negation regex patterns (trigger appears before entity)
_PRE_NEGATION_TRIGGERS = [
    r"\bno\b",
    r"\bnot\b",
    r"\bdenies\b",
    r"\bdenied\b",
    r"\bwithout\b",
    r"\bfree of\b",
    r"\bnegative for\b",
    r"\brules? out\b",
    r"\bruled out\b",
    r"\bno evidence of\b",
    r"\bno signs? of\b",
    r"\bno history of\b",
    r"\babsence of\b",
    r"\bno acute\b",
    r"\bno significant\b",
    r"\bno known\b",
    r"\bzero\b",
    r"\bnon-reactive\b",
    r"\bunremarkable\b",
]

# Post-negation regex patterns (trigger appears shortly after entity)
_POST_NEGATION_TRIGGERS = [
    r"\bwas ruled out\b",
    r"\bis absent\b",
    r"\bunlikely\b",
    r"\bnot detected\b",
    r"\bnot seen\b",
    r"\bnegative\b",
]

# Allergen negation specific triggers
_ALLERGY_NEGATION_PATTERNS = [
    r"\bnkda\b",
    r"\bno known drug allergies\b",
    r"\bno known allergies\b",
    r"\bno allergies\b",
    r"\ballergies[:\s]+none\b",
    r"\ballergies[:\s]+no\b",
    r"\ballergies[:\s]+denied\b",
    r"\ballergies[:\s]+nil\b",
    r"\ballergies[:\s]+nkda\b",
]

_PRE_PATTERN = re.compile(r"|".join(_PRE_NEGATION_TRIGGERS), re.IGNORECASE)
_POST_PATTERN = re.compile(r"|".join(_POST_NEGATION_TRIGGERS), re.IGNORECASE)
_ALLERGY_PATTERN = re.compile(r"|".join(_ALLERGY_NEGATION_PATTERNS), re.IGNORECASE)


def is_negated(target_term: str, full_text: str, window_chars: int = 70) -> bool:
    """Checks if target_term is preceded or followed by negation within a window."""
    if not target_term or not full_text:
        return False

    escaped = re.escape(target_term.strip())
    matches = list(re.finditer(rf"\b{escaped}\b", full_text, re.IGNORECASE))
    if not matches:
        return False

    for m in matches:
        start, end = m.start(), m.end()
        # Look behind
        prefix_start = max(0, start - window_chars)
        prefix_window = full_text[prefix_start:start]

        # Stop looking across strong punctuation boundaries
        sentences = re.split(r"[.;\n]", prefix_window)
        immediate_prefix = sentences[-1] if sentences else prefix_window

        if _PRE_PATTERN.search(immediate_prefix):
            return True

        # Look ahead
        suffix_end = min(len(full_text), end + window_chars)
        suffix_window = full_text[end:suffix_end]
        immediate_suffix = re.split(r"[.;\n]", suffix_window)[0]

        if _POST_PATTERN.search(immediate_suffix):
            return True

    return False


def extract_allergies_with_negation(full_text: str) -> list[dict]:
    """Detects allergens and whether allergies are negated (e.g. NKDA)."""
    allergies: list[dict] = []
    lower = full_text.lower()

    # Check for blanket negation
    if _ALLERGY_PATTERN.search(lower):
        allergies.append({
            "name": "No Known Drug Allergies (NKDA)",
            "is_negated": True,
            "confidence": 0.98,
        })
        return allergies

    # Look for explicit allergy sections
    match = re.search(r"(?:allergies|allergy|allergens?)[:\s]+([^\n.]+)", full_text, re.IGNORECASE)
    if match:
        raw_val = match.group(1).strip()
        if any(w in raw_val.lower() for w in ["none", "nil", "denied", "no", "na", "n/a"]):
            allergies.append({
                "name": "No Known Drug Allergies (NKDA)",
                "is_negated": True,
                "confidence": 0.96,
            })
        else:
            # Split comma separated allergens
            parts = [p.strip() for p in re.split(r"[,;/]", raw_val) if len(p.strip()) > 1]
            for p in parts:
                neg = is_negated(p, full_text)
                allergies.append({
                    "name": p.title(),
                    "is_negated": neg,
                    "confidence": 0.88,
                })

    return allergies


def is_allergy_negated(allergen: str, text: str) -> bool:
    """Checks whether an allergy is negated in text.

    Covers:
    - "allergic to penicillin" -> False
    - "NOT allergic to penicillin" -> True
    - "no known drug allergies" -> True
    - "denies allergy to penicillin" -> True
    """
    if not text:
        return False

    lower_text = text.lower()
    lower_allergen = allergen.lower().strip()

    # 1. Blanket negation patterns (e.g., NKDA, no known drug allergies)
    for pat in _ALLERGY_NEGATION_PATTERNS:
        if re.search(pat, lower_text):
            return True

    # 2. Specific negation preceding or around the allergen
    patterns = [
        rf"\b(?:not|no|denies|denied|negative\s+for)\s+(?:allergic\s+to|allergy\s+to|known\s+allergy\s+to|adverse\s+reaction\s+to)?\s*{re.escape(lower_allergen)}\b",
        rf"\b{re.escape(lower_allergen)}\b[^\.\n;]*(?:denies|denied|negative|not\s+allergic|no\s+adverse|no\s+known|absent|ruled\s+out)",
    ]
    for p in patterns:
        if re.search(p, lower_text):
            return True

    return is_negated(allergen, text)


def apply_negation_safeguards(record: dict, raw_text: str) -> dict:
    """Safety net: double checks LLM output against deterministic negation rules."""
    if not record or not raw_text:
        return record

    # Safeguard allergies
    for allergy in record.get("allergies", []):
        allergen = allergy.get("allergen", "")
        already_negated = allergy.get("negated", False)
        if not already_negated and allergen:
            if is_allergy_negated(allergen, raw_text):
                allergy["negated"] = True

    # Safeguard conditions
    for cond in record.get("conditions", []):
        cond_val = cond.get("value", "")
        if cond_val and is_negated(cond_val, raw_text):
            cond["negated"] = True

    return record

