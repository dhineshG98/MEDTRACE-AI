"""Seed script for MedTrace AI.

Seeds the 6 clinical journey documents to generate the exact longitudinal patient timeline:
  - 10 JAN 2025: Lab_Report_01.pdf (HbA1c: 8.4%, Fasting Glucose: 168 mg/dL)
  - 15 JAN 2025: Clinical_Note_01.pdf (Diagnosis: Type 2 Diabetes, Hypertension)
  - 15 JAN 2025: Prescription_01.pdf (Metformin 500 mg, Amlodipine 5 mg)
  - 18 JAN 2025: Imaging_Report_01.pdf (Chest X-Ray: No acute abnormality)
  - 20 FEB 2025: Lab_Report_02.pdf (HbA1c: 7.6%, Fasting Glucose: 142 mg/dL)
  - 25 FEB 2025: Clinical_Note_02.pdf (Follow-up: Medication continued)

All files are stored encrypted at rest with AES-256-GCM (.enc) in the uploads directory.
"""

import hashlib
import json
import uuid
from datetime import datetime, timezone
from pathlib import Path

from app.config.settings import settings
from app.database.database import SessionLocal
from app.database.init_db import init_db
from app.models.document import Document, DocumentStatus
from app.models.extraction import Extraction
from app.services import encryption_service

SAMPLE_DOCS = [
    {
        "filename": "Lab_Report_01.pdf",
        "created_at": datetime(2025, 1, 10, 8, 30, tzinfo=timezone.utc),
        "document_type": "Laboratory Report",
        "text": (
            "METROPOLITAN DIAGNOSTIC LABORATORIES\n"
            "Date: 2025-01-10\n"
            "Patient: Eleanor Bennett | Age: 58 | Gender: Female\n"
            "Investigation: Comprehensive Metabolic Panel\n"
            "HbA1c: 8.4%\n"
            "Fasting Glucose: 168 mg/dL\n"
            "Interpretation: Elevated glycemic markers consistent with uncontrolled diabetes."
        ),
        "entities": {
            "lab_results": [
                {"test_name": "HbA1c", "value": "8.4", "unit": "%", "flag": "High"},
                {"test_name": "Fasting Glucose", "value": "168", "unit": "mg/dL", "flag": "High"},
            ],
            "patient": {"name": "Eleanor Bennett", "age": 58, "gender": "Female"},
        },
    },
    {
        "filename": "Clinical_Note_01.pdf",
        "created_at": datetime(2025, 1, 15, 10, 0, tzinfo=timezone.utc),
        "document_type": "Clinical Visit Note",
        "text": (
            "OUTPATIENT CLINICAL ENCOUNTER NOTE\n"
            "Date: 2025-01-15\n"
            "Patient: Eleanor Bennett\n"
            "Attending Physician: Dr. Robert Vance, MD\n"
            "Subjective: Patient presents for review of recent bloodwork showing elevated fasting glucose.\n"
            "Assessment / Diagnoses:\n"
            "1. Diagnosis: Type 2 Diabetes\n"
            "2. Diagnosis: Hypertension\n"
            "Plan: Initiate oral antihyperglycemic and antihypertensive therapy. Order baseline chest radiograph."
        ),
        "entities": {
            "conditions": [
                {"name": "Type 2 Diabetes", "icd10": "E11", "is_negated": False},
                {"name": "Hypertension", "icd10": "I10", "is_negated": False},
            ],
            "patient": {"name": "Eleanor Bennett", "age": 58, "gender": "Female"},
        },
    },
    {
        "filename": "Prescription_01.pdf",
        "created_at": datetime(2025, 1, 15, 11, 15, tzinfo=timezone.utc),
        "document_type": "Prescription Record",
        "text": (
            "PHYSICIAN PRESCRIPTION ORDER\n"
            "Date: 2025-01-15\n"
            "Patient: Eleanor Bennett | MRN: 884920\n"
            "Rx: Metformin 500 mg\n"
            "Sig: Take 1 tablet twice daily with meals\n"
            "Rx: Amlodipine 5 mg\n"
            "Sig: Take 1 tablet once daily in the morning\n"
            "Duration: 30 days\n"
            "Physician: Dr. Robert Vance, MD"
        ),
        "entities": {
            "medications": [
                {"name": "Metformin", "dosage": "500 mg", "frequency": "twice daily", "treats": "Type 2 Diabetes"},
                {"name": "Amlodipine", "dosage": "5 mg", "frequency": "once daily", "treats": "Hypertension"},
            ],
            "patient": {"name": "Eleanor Bennett"},
        },
    },
    {
        "filename": "Imaging_Report_01.pdf",
        "created_at": datetime(2025, 1, 18, 14, 0, tzinfo=timezone.utc),
        "document_type": "Imaging Report",
        "text": (
            "DEPARTMENT OF RADIOLOGY - DIAGNOSTIC REPORT\n"
            "Date: 2025-01-18\n"
            "Examination: Chest X-Ray (PA and Lateral views)\n"
            "Indication: Pre-treatment baseline evaluation\n"
            "Findings: The cardiothoracic ratio is normal. Lung fields are clear with no focal consolidation, pneumothorax, or effusion.\n"
            "Impression: Finding: No acute abnormality. Normal chest radiograph."
        ),
        "entities": {
            "conditions": [],
            "patient": {"name": "Eleanor Bennett"},
        },
    },
    {
        "filename": "Lab_Report_02.pdf",
        "created_at": datetime(2025, 2, 20, 9, 0, tzinfo=timezone.utc),
        "document_type": "Laboratory Report",
        "text": (
            "METROPOLITAN DIAGNOSTIC LABORATORIES\n"
            "Date: 2025-02-20\n"
            "Patient: Eleanor Bennett\n"
            "Investigation: Follow-up Glycemic Monitoring\n"
            "HbA1c: 7.6%\n"
            "Fasting Glucose: 142 mg/dL\n"
            "Interpretation: Improved glycemic control on Metformin therapy."
        ),
        "entities": {
            "lab_results": [
                {"test_name": "HbA1c", "value": "7.6", "unit": "%", "flag": "Moderate"},
                {"test_name": "Fasting Glucose", "value": "142", "unit": "mg/dL", "flag": "Moderate"},
            ],
            "patient": {"name": "Eleanor Bennett"},
        },
    },
    {
        "filename": "Clinical_Note_02.pdf",
        "created_at": datetime(2025, 2, 25, 11, 30, tzinfo=timezone.utc),
        "document_type": "Clinical Visit Note",
        "text": (
            "CLINICAL FOLLOW-UP VISIT NOTE\n"
            "Date: 2025-02-25\n"
            "Patient: Eleanor Bennett\n"
            "Attending Physician: Dr. Robert Vance, MD\n"
            "Status: Routine follow-up post 4 weeks of medical therapy.\n"
            "Clinical Assessment:\n"
            "Patient tolerating therapy well. Glycemic markers improving.\n"
            "Plan:\n"
            "Medication continued at current dosages. Next routine follow-up in 3 months."
        ),
        "entities": {
            "conditions": [{"name": "Type 2 Diabetes", "is_negated": False}],
            "patient": {"name": "Eleanor Bennett"},
        },
    },
]


def create_minimal_pdf(text: str) -> bytes:
    """Generates a minimal valid PDF containing the clinical text."""
    import fitz
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((50, 72), text, fontsize=11)
    pdf_bytes = doc.tobytes()
    doc.close()
    return pdf_bytes


def seed(clean: bool = False):
    init_db()
    db = SessionLocal()
    settings.UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        print("Cleaning up previous test records...")
        db.query(Extraction).delete()
        db.query(Document).delete()
        db.commit()

    print("Seeding 6 timeline documents with AES-256-GCM encryption...")

    for item in SAMPLE_DOCS:
        # Check if already exists
        existing = db.query(Document).filter(Document.filename == item["filename"]).first()
        if existing and not clean:
            print(f"  - {item['filename']} already exists, skipping.")
            continue
        elif existing and clean:
            db.delete(existing)
            db.commit()

        doc_id = uuid.uuid4()
        pdf_bytes = create_minimal_pdf(item["text"])

        # 1. Encrypt and save to disk (.enc)
        stored_path = settings.UPLOAD_DIR / f"{doc_id}.enc"
        encryption_service.encrypt_file(pdf_bytes, stored_path)

        # 2. Compute hash of plaintext
        chash = hashlib.sha256(pdf_bytes).hexdigest()

        # 3. Create Document DB record
        doc = Document(
            id=doc_id,
            filename=item["filename"],
            stored_path=str(stored_path),
            file_type="pdf",
            mime_type="application/pdf",
            file_size=len(pdf_bytes),
            content_hash=chash,
            status=DocumentStatus.COMPLETED,
            raw_text=item["text"],  # EncryptedText automatically encrypts with AES-256-GCM
            extraction_method="pdf_text",
            page_count=1,
            word_count=len(item["text"].split()),
            char_count=len(item["text"]),
            document_type=item["document_type"],
            quality_score=95,
            structured_entities=json.dumps(item["entities"]),
            created_at=item["created_at"],
            processed_at=item["created_at"],
        )
        db.add(doc)

        # 4. Create Extraction DB record
        ext = Extraction(
            id=uuid.uuid4(),
            document_id=doc_id,
            document_type=item["document_type"],
            document_type_confidence=0.98,
            patient_info=json.dumps(item["entities"].get("patient", {})),
            conditions=json.dumps(item["entities"].get("conditions", [])),
            medications=json.dumps(item["entities"].get("medications", [])),
            lab_results=json.dumps(item["entities"].get("lab_results", [])),
            quality_score=95,
            requires_review=False,
            summary=f"Clinical record for {item['filename']}",
            provider_used="gemini",
            created_at=item["created_at"],
        )
        db.add(ext)

        print(f"  + Seeded {item['filename']} ({doc_id}) [AES-256-GCM Encrypted]")

    db.commit()
    db.close()
    print("\nDatabase seeded successfully!")


if __name__ == "__main__":
    import sys
    do_clean = "--clean" in sys.argv
    seed(clean=do_clean)
