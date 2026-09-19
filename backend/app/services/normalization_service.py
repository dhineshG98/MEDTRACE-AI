"""Clinical Normalization Service.

Standardizes drug names, formulations, dosage units, and condition terminologies
(e.g., 'AMLODIPINE BESYLATE 5MG TABS' -> 'Amlodipine', 'HTN' -> 'Essential Hypertension').
"""

import re

_PHARMA_SALTS = [
    r"\bbesylate\b", r"\bhcl\b", r"\bhydrochloride\b", r"\bsodium\b",
    r"\bpotassium\b", r"\bsuccinate\b", r"\btartrate\b", r"\bmaleate\b",
    r"\bmonohydrate\b", r"\bfumarate\b", r"\bcalcium\b", r"\bacetate\b",
    r"\bvalerate\b", r"\bdipropionate\b", r"\bmesylate\b",
]

_DOSAGE_FORMS = [
    r"\btabs?\b", r"\btablets?\b", r"\bcaps?\b", r"\bcapsules?\b",
    r"\boral\b", r"\bsolution\b", r"\bsuspension\b", r"\binjection\b",
    r"\ber\b", r"\bxr\b", r"\bsr\b", r"\bcr\b", r"\bla\b", r"\bdr\b",
]

# Common brand-to-generic mapping
_BRAND_TO_GENERIC = {
    "norvasc": "Amlodipine",
    "glucophage": "Metformin",
    "zestril": "Lisinopril",
    "prinivil": "Lisinopril",
    "lipitor": "Atorvastatin",
    "lopressor": "Metoprolol",
    "toprol": "Metoprolol",
    "prilosec": "Omeprazole",
    "cozaar": "Losartan",
    "proair": "Albuterol",
    "ventolin": "Albuterol",
    "neurontin": "Gabapentin",
    "synthroid": "Levothyroxine",
    "lasix": "Furosemide",
    "plavix": "Clopidogrel",
    "zoloft": "Sertraline",
    "eliquis": "Apixaban",
    "coumadin": "Warfarin",
}

# Standard ICD-10 condition map
_CONDITION_MAP = [
    (r"\b(t2dm|type\s+2\s+diabetes(?:\s+mellitus)?|type\s+ii\s+diabetes)\b", "Type 2 Diabetes Mellitus", "E11.9"),
    (r"\b(t1dm|type\s+1\s+diabetes(?:\s+mellitus)?|type\s+i\s+diabetes)\b", "Type 1 Diabetes Mellitus", "E10.9"),
    (r"\b(htn|essential\s+hypertension|hypertension(?:\s+stage\s+\d+)?)\b", "Essential Hypertension", "I10"),
    (r"\b(hyperlipidemia|dyslipidemia|high\s+cholesterol)\b", "Hyperlipidemia", "E78.5"),
    (r"\b(ckd(?:\s+stage\s+\d+)?|chronic\s+kidney\s+disease)\b", "Chronic Kidney Disease", "N18.9"),
    (r"\b(cad|coronary\s+artery\s+disease|ischemic\s+heart\s+disease)\b", "Coronary Artery Disease", "I25.10"),
    (r"\b(chf|congestive\s+heart\s+failure|heart\s+failure)\b", "Heart Failure", "I50.9"),
    (r"\b(afib|a-fib|atrial\s+fibrillation)\b", "Atrial Fibrillation", "I48.91"),
    (r"\b(gerd|acid\s+reflux|gastroesophageal\s+reflux)\b", "Gastroesophageal Reflux Disease (GERD)", "K21.9"),
    (r"\b(copd|chronic\s+obstructive\s+pulmonary\s+disease)\b", "Chronic Obstructive Pulmonary Disease (COPD)", "J44.9"),
    (r"\b(asthma|bronchial\s+asthma)\b", "Asthma", "J45.909"),
    (r"\b(hypothyroidism)\b", "Hypothyroidism", "E03.9"),
    (r"\b(osteoarthritis|oa)\b", "Osteoarthritis", "M19.90"),
    (r"\b(angina(?:\s+pectoris)?|stable\s+angina|unstable\s+angina)\b", "Angina Pectoris", "I20.9"),
    (r"\b(left\s+ventricular\s+hypertrophy|lvh)\b", "Left Ventricular Hypertrophy", "I51.7"),
    (r"\b(hypertensive\s+heart\s+disease)\b", "Hypertensive Heart Disease", "I11.9"),
]


def normalize_medication(raw_name: str) -> tuple[str, str | None]:
    """Normalizes medication string.
    
    Returns: (canonical_name, extracted_dosage)
    Example: 'AMLODIPINE BESYLATE 5MG TABS' -> ('Amlodipine', '5 mg')
    """
    clean = raw_name.strip()
    lower = clean.lower()

    # Check brand mapping
    for brand, generic in _BRAND_TO_GENERIC.items():
        if re.search(rf"\b{brand}\b", lower):
            clean = re.sub(rf"\b{brand}\b", generic, clean, flags=re.IGNORECASE)

    # Extract dosage if present (e.g. 5mg, 500 mg, 10 mcg)
    dosage_match = re.search(r"(\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|units?))\b", clean, re.IGNORECASE)
    dosage = dosage_match.group(1).lower() if dosage_match else None
    if dosage:
        # Standardize spacing like "5 mg"
        dosage = re.sub(r"(\d+)(mg|mcg|g|ml)", r"\1 \2", dosage)

    # Remove dosage from name
    clean = re.sub(r"\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|units?)\b", "", clean, flags=re.IGNORECASE)

    # Strip pharmaceutical salts
    for salt_pat in _PHARMA_SALTS:
        clean = re.sub(salt_pat, "", clean, flags=re.IGNORECASE)

    # Strip dosage forms
    for form_pat in _DOSAGE_FORMS:
        clean = re.sub(form_pat, "", clean, flags=re.IGNORECASE)

    # Clean punctuation and excess whitespace
    clean = re.sub(r"[,;()/-]", " ", clean)
    clean = re.sub(r"\s+", " ", clean).strip()

    canonical = clean.title() if clean else "Unknown Medication"
    return canonical, dosage


def normalize_condition(raw_condition: str) -> tuple[str, str | None]:
    """Normalizes clinical condition and maps to ICD-10.
    
    Returns: (standard_name, icd10_code)
    Example: 'HTN Stage 2' -> ('Essential Hypertension', 'I10')
    """
    text = raw_condition.strip()
    for pat, standard_name, icd10 in _CONDITION_MAP:
        if re.search(pat, text, re.IGNORECASE):
            return standard_name, icd10

    # Default to cleaned title case
    clean = re.sub(r"[;:]+", "", text).strip()
    return clean.title(), None


def normalize_medication_name(raw_name: str) -> str:
    """Normalizes medication casing without substituting one drug for another.

    Example: 'AMLODIPINE' -> 'Amlodipine', 'METFORMIN HCL' -> 'Metformin HCL'
    """
    if not raw_name:
        return ""
    words = raw_name.strip().split()
    normalized_words = []
    for w in words:
        w_lower = w.lower()
        if w_lower in ["hcl", "cr", "er", "xr", "sr", "dr", "la"]:
            normalized_words.append(w.upper())
        else:
            normalized_words.append(w.capitalize())
    return " ".join(normalized_words)


def normalize_dosage(raw_dosage: str | None) -> str | None:
    """Standardizes dosage spacing and casing (e.g., '5MG' -> '5 mg', '500MG' -> '500 mg')."""
    if not raw_dosage:
        return None
    clean = raw_dosage.strip()
    # Insert space between number and unit (e.g. 5mg -> 5 mg, 500mg -> 500 mg)
    clean = re.sub(r"(?i)(\d+(?:\.\d+)?)\s*([a-z%]+)", r"\1 \2", clean)
    return clean.lower()


def normalize_date_to_iso(date_str: str | None) -> str | None:
    """Parses clinical date strings into ISO format YYYY-MM-DD."""
    if not date_str:
        return None
    clean = date_str.strip()
    if re.match(r"^\d{4}-\d{2}-\d{2}$", clean):
        return clean

    from datetime import datetime
    formats = [
        "%Y-%m-%d",
        "%B %d, %Y",
        "%b %d, %Y",
        "%d %B %Y",
        "%d %b %Y",
        "%m/%d/%Y",
        "%d/%m/%Y",
        "%Y/%m/%d",
    ]
    for fmt in formats:
        try:
            dt = datetime.strptime(clean, fmt)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            continue
    return clean


def normalize_extraction_record(record: dict) -> dict:
    """Applies deterministic normalization to extracted medical record."""
    if not record:
        return record

    for med in record.get("medications", []):
        if "name" in med and med["name"]:
            med["name"] = normalize_medication_name(med["name"])
        if "dosage" in med and med["dosage"]:
            med["dosage"] = normalize_dosage(med["dosage"])

    for d in record.get("dates", []):
        if "value" in d and d["value"]:
            d["value"] = normalize_date_to_iso(d["value"])

    patient = record.get("patient")
    if patient and isinstance(patient, dict) and "name" in patient and patient["name"]:
        patient["name"] = patient["name"].strip().title()

    return record

