"""Clinical Extraction Orchestrator.

Integrates:
- Provider-agnostic LLM or offline clinical heuristic extraction
- Negation detection (negation_service)
- Pharmacological & ICD-10 normalization (normalization_service)
- Medication-condition relationship mapping (relationship_service)
- Confidence scoring & tiering (confidence_service)
- Document quality scoring (quality_service)
"""

import json
import logging
import re
from typing import Any, Optional

from app.config.settings import settings
from app.services import (
    confidence_service,
    negation_service,
    normalization_service,
    quality_service,
    relationship_service,
)
from app.services.ai_service import CloudAiProvider, HeuristicClinicalProvider, _DRUG_NAMES

logger = logging.getLogger(__name__)

# Common lab test extraction patterns with standard units & reference ranges
_LAB_DEFINITIONS = [
    {
        "pattern": r"(?i)\bHbA1c[:\s\r\n]+([0-9.]+\s*%?)",
        "name": "HbA1c",
        "unit": "%",
        "reference_range": "< 5.7%",
        "high_threshold": 6.5,
    },
    {
        "pattern": r"(?i)\b(?:Fasting Blood Glucose|Fasting Glucose)[:\s\r\n]+([0-9.]+\s*(?:mg/dL)?)",
        "name": "Fasting Blood Glucose",
        "unit": "mg/dL",
        "reference_range": "70 - 99 mg/dL",
        "high_threshold": 126.0,
    },
    {
        "pattern": r"(?i)\bBlood Glucose[:\s\r\n]+([0-9.]+\s*(?:mg/dL)?)",
        "name": "Blood Glucose",
        "unit": "mg/dL",
        "reference_range": "70 - 140 mg/dL",
        "high_threshold": 200.0,
    },
    {
        "pattern": r"(?i)\bCreatinine[:\s\r\n]+([0-9.]+\s*(?:mg/dL)?)",
        "name": "Creatinine",
        "unit": "mg/dL",
        "reference_range": "0.7 - 1.3 mg/dL",
        "high_threshold": 1.5,
    },
    {
        "pattern": r"(?i)\b(?:Total )?Cholesterol[:\s\r\n]+([0-9.]+\s*(?:mg/dL)?)",
        "name": "Total Cholesterol",
        "unit": "mg/dL",
        "reference_range": "< 200 mg/dL",
        "high_threshold": 240.0,
    },
    {
        "pattern": r"(?i)\beGFR[:\s\r\n]+([0-9.]+\s*(?:mL/min)?[^\n,;]*)",
        "name": "eGFR",
        "unit": "mL/min/1.73m²",
        "reference_range": "> 60 mL/min",
        "low_threshold": 60.0,
    },
    {
        "pattern": r"(?i)\bHemoglobin[:\s\r\n]+([0-9.]+\s*(?:g/dL)?)",
        "name": "Hemoglobin",
        "unit": "g/dL",
        "reference_range": "13.5 - 17.5 g/dL",
        "low_threshold": 12.0,
    },
    {
        "pattern": r"(?i)\bWBC[:\s\r\n]+([0-9.,]+\s*(?:/uL|x10\^3/uL)?)",
        "name": "White Blood Cell Count (WBC)",
        "unit": "x10^3/uL",
        "reference_range": "4.5 - 11.0 x10^3/uL",
        "high_threshold": 12.0,
    },
    {
        "pattern": r"(?i)\bPlatelets?[:\s\r\n]+([0-9.,]+\s*(?:/uL|/mcL)?)",
        "name": "Platelets",
        "unit": "x10^3/uL",
        "reference_range": "150 - 450 x10^3/uL",
        "low_threshold": 140.0,
    },
    {
        "pattern": r"(?i)\bPotassium[:\s\r\n]+([0-9.]+\s*(?:mEq/L|mmol/L)?)",
        "name": "Potassium",
        "unit": "mEq/L",
        "reference_range": "3.5 - 5.0 mEq/L",
        "high_threshold": 5.2,
        "low_threshold": 3.4,
    },
    {
        "pattern": r"(?i)\bSodium[:\s\r\n]+([0-9.]+\s*(?:mEq/L|mmol/L)?)",
        "name": "Sodium",
        "unit": "mEq/L",
        "reference_range": "135 - 145 mEq/L",
    },
]

_DOCTOR_PATTERNS = [
    r"(?i)(?:Dr\.|Doctor|Physician|Provider|Attending|Consultant|Signed by)[:\s]+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)+)",
    r"\bDr\.\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)+)",
    r"\b([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)+),\s*(?:M\.?D\.?|D\.?O\.?|MBBS)\b",
]

_DATE_PATTERNS = [
    (r"(?i)(?:Encounter|Visit|Admission|Date of Service)[:\s]+(\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})", "Encounter Date"),
    (r"(?i)(?:Report|Specimen|Collected|Order)[:\s]+Date[:\s]+(\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})", "Report Date"),
    (r"(?i)\bDate[:\s]+(\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})", "Clinical Date"),
]


def _extract_heuristic_raw(text: str) -> dict[str, Any]:
    """Offline heuristic extractor for clinical entities."""
    doc_type = HeuristicClinicalProvider.classify(text)
    heuristic_entities = HeuristicClinicalProvider.extract_entities(text)

    # 1. Patient info
    patient_info = dict(heuristic_entities.patient_info)

    p_pipe = re.search(r"(?i)\bPatient(?:\s+Name)?\s*\|\s*([^|\n\r#]+)", text)
    if p_pipe:
        val = p_pipe.group(1).strip()
        if val and not any(w in val.lower() for w in ["synthetic", "test record"]):
            patient_info["name"] = val

    if not patient_info.get("name"):
        p_match = re.search(r"(?i)\b(?:patient(?:\s+name)?|pt|patient\s+name)\s*:\s*([A-Za-z]+(?:[ \t]+[A-Za-z]+)+)", text)
        if p_match:
            patient_info["name"] = p_match.group(1).strip()

    mrn_pipe = re.search(r"(?i)\b(?:MRN|UHID|Patient ID|Record #)(?:\s*/\s*UHID)?\s*\|\s*([^|\n\r#]+)", text)
    if mrn_pipe:
        patient_info["mrn"] = mrn_pipe.group(1).strip()
    elif not patient_info.get("mrn"):
        mrn_match = re.search(r"(?i)\b(?:mrn|patient id|record #)[:\s]+([A-Z0-9-]+)\b", text)
        if mrn_match:
            patient_info["mrn"] = mrn_match.group(1).strip()

    age_pipe = re.search(r"(?i)\bAge(?:\s*/\s*Sex)?\s*\|\s*([^|\n\r#]+)", text)
    if age_pipe:
        raw_age_sex = age_pipe.group(1).strip()
        patient_info["age_or_dob"] = raw_age_sex
        if "male" in raw_age_sex.lower():
            patient_info["gender"] = "Male"
        elif "female" in raw_age_sex.lower():
            patient_info["gender"] = "Female"

    if not patient_info.get("age_or_dob"):
        dob_match = re.search(r"(?i)\b(?:dob|date of birth|birth)[:\s]+([0-9\-/]+|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})", text)
        if dob_match:
            patient_info["age_or_dob"] = dob_match.group(1).strip()
        else:
            age_match = re.search(r"(?i)\b(?:age)[:\s]+(\d{1,3}(?:\s*y(?:ears?)?(?:\s*old)?)?)", text)
            if age_match:
                patient_info["age_or_dob"] = age_match.group(1).strip()

    if not patient_info.get("date"):
        dt_match = re.search(r"(?i)\b(?:date|encounter date)[:\s]+(\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})", text)
        if dt_match:
            patient_info["date"] = dt_match.group(1).strip()

    if not patient_info.get("gender"):
        gender_match = re.search(r"(?i)\b(?:gender|sex)[:\s]+(male|female|m|f|non-binary)\b", text)
        if gender_match:
            patient_info["gender"] = "Male" if gender_match.group(1).upper() in ["M", "MALE"] else "Female"

    # 2. Conditions / Diagnoses
    raw_conditions = list(heuristic_entities.diagnoses)

    # 3. Medications
    raw_medications = []
    for med in heuristic_entities.medications:
        raw_medications.append({
            "name": med.name,
            "dosage": med.dosage,
            "frequency": med.frequency,
            "route": med.route,
        })

    # 4. Allergies
    raw_allergies = negation_service.extract_allergies_with_negation(text)

    # 5. Lab results
    raw_labs = []
    for lab_def in _LAB_DEFINITIONS:
        match = re.search(lab_def["pattern"], text)
        if match:
            raw_val = match.group(1).strip()
            num_match = re.search(r"([0-9]+(?:\.[0-9]+)?)", raw_val)
            val_num = float(num_match.group(1)) if num_match else None

            flag = "Normal"
            if val_num is not None:
                if "high_threshold" in lab_def and val_num >= lab_def["high_threshold"]:
                    flag = "High"
                elif "low_threshold" in lab_def and val_num <= lab_def["low_threshold"]:
                    flag = "Low"

            # Check for unit in val or use default
            unit = lab_def["unit"]
            clean_val = raw_val.replace(unit, "").strip() if unit else raw_val

            raw_labs.append({
                "test_name": lab_def["name"],
                "value": clean_val or raw_val,
                "unit": unit,
                "reference_range": lab_def.get("reference_range"),
                "flag": flag,
                "date": patient_info.get("date"),
            })

    # 6. Dates
    dates = []
    seen_dates = set()
    for pat, date_type in _DATE_PATTERNS:
        for m in re.finditer(pat, text):
            d_val = m.group(1).strip()
            if d_val not in seen_dates:
                seen_dates.add(d_val)
                dates.append({"date": d_val, "type": date_type})

    # 7. Doctors
    doctors = []
    seen_docs = set()
    for pat in _DOCTOR_PATTERNS:
        for m in re.finditer(pat, text):
            doc_name = m.group(1).strip()
            if len(doc_name) > 3 and doc_name not in seen_docs:
                seen_docs.add(doc_name)
                doctors.append(f"Dr. {doc_name}" if not doc_name.lower().startswith("dr.") else doc_name)

    return {
        "document_type": doc_type,
        "document_type_confidence": 0.92,
        "patient": patient_info,
        "conditions": [{"name": c} for c in raw_conditions],
        "medications": raw_medications,
        "allergies": raw_allergies,
        "lab_results": raw_labs,
        "dates": dates,
        "doctors": doctors,
        "summary": heuristic_entities.summary,
    }


def _extract_with_llm(text: str) -> Optional[dict[str, Any]]:
    """Calls the configured AI provider via get_ai_provider() and validates output.

    Uses the Phase 3 AIProvider abstraction which includes:
    - tenacity retry with exponential back-off
    - correction-prompt retry on JSON parse failure
    - StructuredMedicalRecord Pydantic validation
    - negation safeguards, relationship enrichment, normalization
    """
    from app.services.ai_provider import get_ai_provider
    from app.schemas.extraction import StructuredMedicalRecord
    from app.services.negation_service import apply_negation_safeguards
    from app.services.relationship_service import enrich_relationships
    from app.services.normalization_service import normalize_extraction_record

    provider = get_ai_provider()
    if provider.provider_name == "heuristic":
        return None  # let caller fall through to _extract_heuristic_raw

    try:
        raw_dict = provider.extract(text)
    except RuntimeError as exc:
        logger.error("AI provider extraction failed: %s", exc)
        return None

    # --- Validate against strict Pydantic schema --------------------------
    try:
        record = StructuredMedicalRecord.model_validate(raw_dict)
        record_dict = record.model_dump()
    except Exception as exc:
        logger.warning("StructuredMedicalRecord validation failed (%s). Using raw dict.", exc)
        record_dict = raw_dict

    # --- Post-processing pipeline -----------------------------------------
    try:
        record_dict = apply_negation_safeguards(record_dict, text)
        record_dict["relationships"] = enrich_relationships(record_dict)
        record_dict = normalize_extraction_record(record_dict)
    except Exception as exc:
        logger.warning("Post-processing step failed (%s). Continuing with partial data.", exc)

    record_dict["_provider"] = provider.provider_name
    return record_dict


def run_clinical_extraction_pipeline(
    raw_text: str,
    extraction_method: str = "pdf_text",
) -> dict[str, Any]:
    """Executes the full end-to-end clinical extraction pipeline.

    1. Extract initial entity graph via LLM or Heuristics
    2. Apply clinical negation detection
    3. Apply pharmacological and ICD-10 normalization
    4. Map medication 'treats' relationships to conditions
    5. Compute granular confidence scores and review flags
    6. Compute document quality score
    """
    provider_used = "heuristic"
    raw_data: Optional[dict[str, Any]] = None

    if settings.ai_configured:
        raw_data = _extract_with_llm(raw_text)
        if raw_data:
            provider_used = raw_data.pop("_provider", settings.resolved_ai_provider)

    if not raw_data:
        raw_data = _extract_heuristic_raw(raw_text)
        provider_used = "heuristic"

    # --- 1. Document Type & Confidence ---
    dt_raw = raw_data.get("document_type")
    if isinstance(dt_raw, dict):
        doc_type = dt_raw.get("value") or "Clinical Medical Document"
        doc_type_conf = float(dt_raw.get("confidence") or 0.90)
    else:
        doc_type = dt_raw or "Clinical Medical Document"
        doc_type_conf = float(raw_data.get("document_type_confidence") or 0.90)

    # --- 2. Patient Info ---
    patient_raw = raw_data.get("patient") or {}
    patient = {
        "name": patient_raw.get("name"),
        "age_or_dob": patient_raw.get("age_or_dob") or (str(patient_raw["age"]) if patient_raw.get("age") is not None else None),
        "gender": patient_raw.get("gender"),
        "mrn": patient_raw.get("mrn") or patient_raw.get("patient_id"),
        "date": patient_raw.get("date"),
    }

    # --- 3. Conditions (Negation & ICD-10 Normalization) ---
    conditions_processed = []
    active_condition_names = []
    review_reasons: list[str] = []
    seen_conditions: dict[str, dict[str, Any]] = {}

    for c in raw_data.get("conditions", []):
        if isinstance(c, dict):
            raw_name = (c.get("value") or c.get("name") or "").strip()
            negated = c.get("negated", c.get("is_negated"))
        else:
            raw_name = str(c).strip()
            negated = None

        if not raw_name:
            continue

        if negated is None:
            negated = negation_service.is_negated(raw_name, raw_text)

        # Normalize name & map ICD-10
        canon_name, icd10 = normalization_service.normalize_condition(raw_name)

        if canon_name in seen_conditions:
            if seen_conditions[canon_name]["is_negated"] and not negated:
                seen_conditions[canon_name]["is_negated"] = False
            continue

        # Confidence
        c_conf = (
            float(c.get("confidence"))
            if isinstance(c, dict) and c.get("confidence") is not None
            else confidence_service.calculate_field_confidence(
                canon_name,
                source_method=extraction_method,
                is_pattern_matched=bool(icd10),
            )
        )
        c_tier = confidence_service.get_confidence_tier(c_conf)

        if not negated:
            active_condition_names.append(canon_name)

        if c_conf < confidence_service.CONFIDENCE_MEDIUM:
            review_reasons.append(f"Low confidence condition extraction: '{raw_name}' ({c_conf:.2f})")

        cond_obj = {
            "name": canon_name,
            "icd10": icd10,
            "is_negated": bool(negated),
            "confidence": c_conf,
            "tier": c_tier,
        }
        seen_conditions[canon_name] = cond_obj
        conditions_processed.append(cond_obj)

    # --- 4. Medications (Normalization & Relationship Mapping) ---
    medications_processed = []
    for m in raw_data.get("medications", []):
        if not isinstance(m, dict):
            continue
        raw_name = m.get("name", "").strip()
        if not raw_name:
            continue

        canon_name, parsed_dosage = normalization_service.normalize_medication(raw_name)
        dosage = m.get("dosage") or parsed_dosage
        frequency = m.get("frequency") or "As directed"
        route = m.get("route") or "Oral"

        # Map 'treats' relationship to patient conditions
        treats_condition = relationship_service.link_medication_to_condition(
            canon_name,
            patient_conditions=active_condition_names,
        )

        m_conf = (
            float(m.get("confidence"))
            if m.get("confidence") is not None
            else confidence_service.calculate_field_confidence(
                canon_name,
                source_method=extraction_method,
                is_pattern_matched=True,
                has_exact_units=bool(dosage),
            )
        )
        m_tier = confidence_service.get_confidence_tier(m_conf)

        if m_conf < confidence_service.CONFIDENCE_MEDIUM:
            review_reasons.append(f"Low confidence medication extraction: '{canon_name}' ({m_conf:.2f})")

        medications_processed.append({
            "name": raw_name,
            "canonical_name": canon_name,
            "dosage": dosage,
            "frequency": frequency,
            "route": route,
            "treats": treats_condition,
            "confidence": m_conf,
            "tier": m_tier,
        })

    # --- 5. Allergies (Negation Check) ---
    allergies_processed = []
    raw_allergies = raw_data.get("allergies", [])
    if not raw_allergies:
        # Fallback to direct negation regex detection
        raw_allergies = negation_service.extract_allergies_with_negation(raw_text)

    for a in raw_allergies:
        if isinstance(a, dict):
            a_name = (a.get("allergen") or a.get("name") or "").strip()
            a_negated = a.get("negated", a.get("is_negated", False))
            a_conf = float(a.get("confidence", 0.92))
        else:
            a_name = str(a).strip()
            a_negated = negation_service.is_negated(a_name, raw_text)
            a_conf = 0.90

        if not a_name:
            continue

        a_tier = confidence_service.get_confidence_tier(a_conf)
        allergies_processed.append({
            "name": a_name,
            "is_negated": bool(a_negated),
            "confidence": a_conf,
            "tier": a_tier,
        })

    # --- 6. Lab Results ---
    labs_processed = []
    for lab in raw_data.get("lab_results", []):
        if not isinstance(lab, dict):
            continue
        test_name = lab.get("test_name", "").strip()
        val = str(lab.get("value", "")).strip()
        if not test_name or not val:
            continue

        l_conf = confidence_service.calculate_field_confidence(
            val,
            source_method=extraction_method,
            has_exact_units=bool(lab.get("unit")),
        )
        l_tier = confidence_service.get_confidence_tier(l_conf)

        if lab.get("flag") in ["Critical High", "Critical Low"]:
            review_reasons.append(f"Critical laboratory flag: {test_name} {val} ({lab.get('flag')})")

        labs_processed.append({
            "test_name": test_name,
            "value": val,
            "unit": lab.get("unit"),
            "reference_range": lab.get("reference_range"),
            "flag": lab.get("flag", "Normal"),
            "date": lab.get("date"),
            "confidence": l_conf,
            "tier": l_tier,
        })

    # --- 7. Dates & Doctors ---
    dates_processed = []
    for d in raw_data.get("dates", []):
        if isinstance(d, dict) and d.get("date"):
            dates_processed.append({"date": d["date"], "type": d.get("type", "Encounter")})
        elif isinstance(d, str) and d.strip():
            dates_processed.append({"date": d.strip(), "type": "Encounter"})

    doctors_processed = [str(doc).strip() for doc in raw_data.get("doctors", []) if str(doc).strip()]

    # --- 8. Quality Score Computation ---
    total_entities = (
        len(conditions_processed)
        + len(medications_processed)
        + len(allergies_processed)
        + len(labs_processed)
    )
    quality_score = quality_service.calculate_quality_score(
        text_length=len(raw_text),
        extraction_method=extraction_method,
        document_type=doc_type,
        document_type_confidence=doc_type_conf,
        has_patient_info=bool(patient.get("name")),
        has_dates=bool(dates_processed or patient.get("date")),
        entity_count=total_entities,
    )

    # --- 9. Review Evaluation ---
    requires_review = confidence_service.evaluate_requires_review(
        doc_type_confidence=doc_type_conf,
        conditions=conditions_processed,
        medications=medications_processed,
        lab_results=labs_processed,
    )
    if len(review_reasons) > 0:
        requires_review = True

    summary = raw_data.get("summary")
    if not summary:
        summary = HeuristicClinicalProvider.build_summary(
            doc_type=doc_type,
            diagnoses=set(active_condition_names),
            medications=[],
            vital_signs={},
        )

    return {
        "document_type": doc_type,
        "document_type_confidence": doc_type_conf,
        "patient": patient,
        "conditions": conditions_processed,
        "medications": medications_processed,
        "allergies": allergies_processed,
        "lab_results": labs_processed,
        "dates": dates_processed,
        "doctors": doctors_processed,
        "quality_score": quality_score,
        "requires_review": requires_review,
        "review_reasons": review_reasons,
        "summary": summary,
        "provider_used": provider_used,
    }
