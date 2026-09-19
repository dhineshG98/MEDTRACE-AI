"""Clinical Relationship Mapping Service.

Links medications to the clinical conditions they treat based on pharmacological
indications and document context (e.g., 'Metformin treats Type 2 Diabetes',
'Amlodipine treats Hypertension').
"""

import re
from typing import Optional

# Standard pharmacological indication ontology
_DRUG_INDICATION_MAP = {
    "metformin": "Type 2 Diabetes Mellitus",
    "glipizide": "Type 2 Diabetes Mellitus",
    "insulin": "Diabetes Mellitus",
    "amlodipine": "Essential Hypertension",
    "lisinopril": "Essential Hypertension",
    "losartan": "Essential Hypertension",
    "metoprolol": "Essential Hypertension / Angina",
    "hydrochlorothiazide": "Essential Hypertension",
    "atorvastatin": "Hyperlipidemia",
    "rosuvastatin": "Hyperlipidemia",
    "simvastatin": "Hyperlipidemia",
    "omeprazole": "Gastroesophageal Reflux Disease (GERD)",
    "pantoprazole": "Gastroesophageal Reflux Disease (GERD)",
    "albuterol": "Asthma / Bronchospasm",
    "fluticasone": "Asthma / Allergic Rhinitis",
    "montelukast": "Asthma / Allergic Rhinitis",
    "levothyroxine": "Hypothyroidism",
    "gabapentin": "Neuropathic Pain",
    "furosemide": "Edema / Heart Failure",
    "apixaban": "Thromboembolism Prophylaxis / Atrial Fibrillation",
    "warfarin": "Anticoagulation / Atrial Fibrillation",
    "clopidogrel": "Antiplatelet / Coronary Artery Disease",
    "aspirin": "Coronary Artery Disease / Antiplatelet Prophylaxis",
    "bisoprolol": "Angina Pectoris / Essential Hypertension",
    "glyceryl trinitrate": "Angina Pectoris / Vasodilation",
    "nitroglycerin": "Angina Pectoris / Vasodilation",
    "ticagrelor": "Coronary Artery Disease / Acute Coronary Syndrome",
    "sertraline": "Major Depressive Disorder",
    "prednisone": "Inflammatory / Autoimmune Conditions",
}


def link_medication_to_condition(
    medication_name: str,
    patient_conditions: list[str] | None = None,
) -> Optional[str]:
    """Finds the clinical condition a medication treats.
    
    If patient_conditions are supplied, prioritizes matching one of the patient's
    active diagnoses.
    """
    clean_med = medication_name.strip().lower()

    # 1. Look up primary pharmacological indication
    primary_indication = None
    for drug_key, indication in _DRUG_INDICATION_MAP.items():
        if drug_key in clean_med:
            primary_indication = indication
            break

    if not primary_indication:
        return None

    # 2. If patient has conditions listed, see if any match the indication
    if patient_conditions:
        ind_lower = primary_indication.lower()
        for cond in patient_conditions:
            c_lower = cond.lower()
            # Check overlap like "diabetes" in both, or "hypertension" in both
            key_terms = ["diabetes", "hypertension", "hyperlipidemia", "cholesterol", "asthma", "gerd", "reflux", "kidney", "heart failure", "angina", "coronary"]
            for term in key_terms:
                if term in ind_lower and term in c_lower:
                    return cond

    return primary_indication


def enrich_relationships(record: dict) -> list[dict]:
    """Ensures clinical relationships array is populated with valid confidence and schema.

    Extracts and standardizes relationships:
    - 'treats' (Medication -> Condition)
    - 'prescribed_for' (Medication -> Condition)
    - 'has_dosage' (Medication -> Dosage)
    - 'has_frequency' (Medication -> Frequency)
    """
    if not record:
        return []

    existing: list[dict] = record.get("relationships", [])
    seen_keys: set[tuple[str, str, str]] = set()
    result: list[dict] = []

    # 1. Clean and normalize existing LLM relationships
    for rel in existing:
        if not isinstance(rel, dict):
            continue
        src = str(rel.get("source", "")).strip()
        rtype = str(rel.get("relationship", "")).strip().lower()
        tgt = str(rel.get("target", "")).strip()
        conf = float(rel.get("confidence", 0.90))

        if not src or not tgt:
            continue

        if rtype in ["treats", "indication", "indicates"]:
            rtype = "treats"
        elif rtype in ["has_dosage", "dosage", "dose"]:
            rtype = "has_dosage"
        elif rtype in ["has_frequency", "frequency", "sig"]:
            rtype = "has_frequency"
        elif rtype in ["prescribed_for", "for", "ordered_for"]:
            rtype = "prescribed_for"
        else:
            rtype = "treats"

        key = (src.lower(), rtype, tgt.lower())
        if key not in seen_keys:
            seen_keys.add(key)
            result.append({
                "source": src,
                "relationship": rtype,
                "target": tgt,
                "confidence": conf,
            })

    # 2. Enrich with structured medication properties if not already present
    conditions = [
        c.get("value") if isinstance(c, dict) else str(c)
        for c in record.get("conditions", [])
        if (isinstance(c, dict) and c.get("value")) or (isinstance(c, str) and c)
    ]

    for med in record.get("medications", []):
        if not isinstance(med, dict):
            continue
        m_name = med.get("name", "").strip()
        if not m_name:
            continue

        if med.get("dosage"):
            dosage_val = str(med["dosage"]).strip()
            k = (m_name.lower(), "has_dosage", dosage_val.lower())
            if k not in seen_keys:
                seen_keys.add(k)
                result.append({
                    "source": m_name,
                    "relationship": "has_dosage",
                    "target": dosage_val,
                    "confidence": 0.98,
                })

        if med.get("frequency"):
            freq_val = str(med["frequency"]).strip()
            k = (m_name.lower(), "has_frequency", freq_val.lower())
            if k not in seen_keys:
                seen_keys.add(k)
                result.append({
                    "source": m_name,
                    "relationship": "has_frequency",
                    "target": freq_val,
                    "confidence": 0.95,
                })

        matched_cond = link_medication_to_condition(m_name, conditions)
        if matched_cond:
            k = (m_name.lower(), "treats", matched_cond.lower())
            if k not in seen_keys:
                seen_keys.add(k)
                result.append({
                    "source": m_name,
                    "relationship": "treats",
                    "target": matched_cond,
                    "confidence": 0.92,
                })

    return result

