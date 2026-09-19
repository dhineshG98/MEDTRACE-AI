"""Document Quality Scoring Service.

Computes a quality score (0-100) based on extraction fidelity, OCR confidence,
detected clinical schema completeness, and document structure.
"""

from typing import Any


def calculate_quality_score(
    text_length: int,
    extraction_method: str,
    document_type: str | None,
    document_type_confidence: float,
    has_patient_info: bool,
    has_dates: bool,
    entity_count: int,
) -> int:
    """Computes quality score = f(text extracted, doc type detected, fields present, OCR quality)."""
    score = 0

    # 1. Text extraction quality (up to 30 pts)
    if text_length > 300:
        score += 30
    elif text_length > 100:
        score += 20
    elif text_length > 0:
        score += 10

    # Penalty if OCR had to be used due to noisy scan
    if extraction_method == "ocr":
        score -= 5

    # 2. Document type detection & classification confidence (up to 25 pts)
    if document_type and document_type != "Unknown Medical Document":
        type_pts = int(document_type_confidence * 25)
        score += max(10, type_pts)

    # 3. Patient identity & encounter date markers (up to 20 pts)
    if has_patient_info:
        score += 10
    if has_dates:
        score += 10

    # 4. Clinical entities detected (up to 25 pts)
    if entity_count >= 5:
        score += 25
    elif entity_count >= 2:
        score += 18
    elif entity_count >= 1:
        score += 10

    return max(10, min(100, score))
