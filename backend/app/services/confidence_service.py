"""Confidence Scoring and Review Determination Service.

Assigns confidence tiers (High: 0.90-1.00, Med: 0.75-0.89, Low: <0.75) to extracted
clinical entities and determines if a document requires manual review.
"""

from typing import Any

CONFIDENCE_HIGH = 0.90
CONFIDENCE_MEDIUM = 0.75


def get_confidence_tier(score: float) -> str:
    """Returns 'High', 'Medium', or 'Low' based on numeric score."""
    if score >= CONFIDENCE_HIGH:
        return "High"
    if score >= CONFIDENCE_MEDIUM:
        return "Medium"
    return "Low"


def calculate_field_confidence(
    value: Any,
    source_method: str = "pdf_text",
    is_pattern_matched: bool = True,
    has_exact_units: bool = False,
) -> float:
    """Calculates a normalized confidence score between 0.0 and 1.0."""
    if value is None or (isinstance(value, str) and not value.strip()):
        return 0.0

    score = 0.80

    # PyMuPDF digital text layer gives higher baseline than OCR
    if source_method == "pdf_text":
        score += 0.10
    elif source_method == "ocr":
        score -= 0.05

    # Valid clinical pattern match increases score
    if is_pattern_matched:
        score += 0.05

    # Exact dosage or lab unit found increases accuracy
    if has_exact_units:
        score += 0.05

    return min(1.0, max(0.1, round(score, 2)))


def evaluate_requires_review(
    doc_type_confidence: float,
    conditions: list[dict],
    medications: list[dict],
    lab_results: list[dict] | None = None,
) -> bool:
    """Returns True if any critical field has confidence < 0.75 or document type is ambiguous."""
    if doc_type_confidence < CONFIDENCE_MEDIUM:
        return True

    for c in conditions:
        if c.get("confidence", 1.0) < CONFIDENCE_MEDIUM:
            return True

    for m in medications:
        if m.get("confidence", 1.0) < CONFIDENCE_MEDIUM:
            return True

    if lab_results:
        for lab in lab_results:
            if lab.get("confidence", 1.0) < CONFIDENCE_MEDIUM:
                return True

    return False
