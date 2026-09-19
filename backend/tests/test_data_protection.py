"""Comprehensive Data Protection & HIPAA Compliance Tests.

Tests:
  1. Extraction entity AES-256-GCM encryption at rest in database.
  2. Cryptographic zero-shredding on file deletion.
  3. PHI / PII Safe Harbor de-identification & redaction.
  4. Audit logging on medical data access.
  5. HTTP security and anti-caching response headers.
"""

import json
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config.settings import settings
from app.database.database import SessionLocal
from app.main import app
from app.models.audit_log import AuditLog
from app.models.document import Document, DocumentStatus
from app.models.extraction import Extraction
from app.services import audit_service, encryption_service, phi_sanitizer
from app.utils import file_utils


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ---------------------------------------------------------------------------
# 1. Extraction Table Encryption at Rest
# ---------------------------------------------------------------------------
class TestExtractionEncryptionAtRest:
    def test_extraction_fields_encrypted_in_database(self, db_session):
        """Verifies structured entities in `extractions` are saved with aes256gcm: prefix."""
        doc_id = uuid.uuid4()
        doc = Document(
            id=doc_id,
            filename="phi_test_doc.pdf",
            stored_path="uploads/phi_test_doc.pdf.enc",
            file_type="pdf",
            mime_type="application/pdf",
            file_size=500,
            content_hash="abc123hash",
            status=DocumentStatus.COMPLETED,
            raw_text="Patient: Alice Smith, SSN: 000-12-3456",
        )
        db_session.add(doc)
        db_session.commit()

        ext_id = uuid.uuid4()
        patient_data = json.dumps({"name": "Alice Smith", "mrn": "MRN-9988"})
        conditions_data = json.dumps([{"name": "Type 2 Diabetes"}])
        meds_data = json.dumps([{"name": "Metformin", "dosage": "500 mg"}])

        ext = Extraction(
            id=ext_id,
            document_id=doc_id,
            document_type="Clinical Visit",
            patient_info=patient_data,
            conditions=conditions_data,
            medications=meds_data,
            allergies="[]",
            lab_results="[]",
            dates="[]",
            doctors='["Dr. Vance"]',
            quality_score=95,
            requires_review=False,
            summary="Confidential clinical summary for Alice Smith",
        )
        db_session.add(ext)
        db_session.commit()

        # Check raw SQLite table: verify ciphertext starts with aes256gcm:
        raw_db_path = settings.DATABASE_URL.replace("sqlite:///", "")
        conn = sqlite3.connect(raw_db_path)
        cur = conn.cursor()
        cur.execute("SELECT patient_info, conditions, medications, summary FROM extractions WHERE id = ?", (str(ext_id),))
        row = cur.fetchone()
        conn.close()

        assert row is not None, "Extraction row must exist in database"
        raw_patient, raw_conditions, raw_meds, raw_summary = row

        # Raw DB text MUST start with aes256gcm: and NOT contain plaintext
        assert raw_patient.startswith("aes256gcm:"), "patient_info must be AES-256-GCM encrypted in raw DB"
        assert "Alice Smith" not in raw_patient, "Plaintext name must not exist in raw DB table"
        assert raw_conditions.startswith("aes256gcm:"), "conditions must be AES-256-GCM encrypted"
        assert raw_meds.startswith("aes256gcm:"), "medications must be AES-256-GCM encrypted"
        assert raw_summary.startswith("aes256gcm:"), "summary must be AES-256-GCM encrypted"

        # ORM query MUST transparently decrypt
        db_session.expire_all()
        loaded = db_session.get(Extraction, ext_id)
        assert loaded is not None
        assert loaded.get_patient_info()["name"] == "Alice Smith"
        assert loaded.get_conditions()[0]["name"] == "Type 2 Diabetes"
        assert loaded.get_medications()[0]["name"] == "Metformin"
        assert "Alice Smith" in loaded.summary

        # Clean up
        db_session.delete(loaded)
        db_session.delete(doc)
        db_session.commit()


# ---------------------------------------------------------------------------
# 2. Cryptographic Zero-Shredding on Deletion
# ---------------------------------------------------------------------------
class TestCryptographicFileShredding:
    def test_shred_file_removes_file(self):
        """Verifies secure_shred_file deletes the file."""
        test_file = settings.UPLOAD_DIR / f"test_shred_{uuid.uuid4().hex}.dat"
        test_file.write_bytes(b"SECRET MEDICAL DATA THAT MUST BE SHREDDED")
        assert test_file.exists()

        result = encryption_service.secure_shred_file(test_file)
        assert result is True
        assert not test_file.exists()

    def test_delete_stored_file_path_traversal_guard(self):
        """Refuses to delete paths outside the upload directory."""
        outside_path = Path("C:/Windows/System32/drivers/etc/hosts")
        assert file_utils.delete_stored_file(str(outside_path)) is False

    def test_delete_stored_file_nonexistent(self):
        """Handles nonexistent path gracefully."""
        nonexistent = settings.UPLOAD_DIR / "does_not_exist_12345.enc"
        assert file_utils.delete_stored_file(str(nonexistent)) is False


# ---------------------------------------------------------------------------
# 3. PHI / PII De-identification & Redaction
# ---------------------------------------------------------------------------
class TestPhiSanitizer:
    def test_redact_ssn(self):
        text = "Patient SSN is 123-45-6789, please keep confidential."
        res = phi_sanitizer.sanitize_text(text)
        assert "123-45-6789" not in res
        assert "[REDACTED_SSN]" in res

    def test_redact_phone_and_email(self):
        text = "Contact: (555) 234-5678 or dr.smith@hospital.org."
        res = phi_sanitizer.sanitize_text(text)
        assert "(555) 234-5678" not in res
        assert "[REDACTED_PHONE]" in res
        assert "dr.smith@hospital.org" not in res
        assert "[REDACTED_EMAIL]" in res

    def test_redact_mrn_and_dob(self):
        text = "MRN: 9948201, DOB: 1975-08-22, presenting for annual checkup."
        res = phi_sanitizer.sanitize_text(text)
        assert "9948201" not in res
        assert "[REDACTED_MRN]" in res
        assert "1975-08-22" not in res
        assert "[REDACTED_DOB]" in res

    def test_preserve_clinical_values(self):
        text = "HbA1c: 8.4%, Fasting Glucose: 168 mg/dL. Prescribed Metformin 500 mg twice daily."
        res = phi_sanitizer.sanitize_text(text)
        assert "HbA1c: 8.4%" in res
        assert "Fasting Glucose: 168 mg/dL" in res
        assert "Metformin 500 mg" in res

    def test_sanitize_entities_dict(self):
        entities = {
            "patient": {
                "name": "Eleanor Bennett",
                "phone": "555-123-4567",
                "email": "eleanor@example.com",
                "mrn": "MRN-101",
            },
            "conditions": [{"name": "Hypertension"}],
            "medications": [{"name": "Amlodipine", "dosage": "5 mg"}],
            "summary": "Patient Eleanor Bennett with Hypertension.",
        }
        sanitized = phi_sanitizer.sanitize_entities(entities)
        assert sanitized["patient"]["name"] == "[REDACTED_NAME]"
        assert sanitized["patient"]["phone"] == "[REDACTED_PHONE]"
        assert sanitized["patient"]["email"] == "[REDACTED_EMAIL]"
        assert sanitized["patient"]["mrn"] == "[REDACTED_MRN]"
        assert sanitized["conditions"][0]["name"] == "Hypertension"
        assert sanitized["medications"][0]["name"] == "Amlodipine"
        assert "Eleanor Bennett" not in sanitized["summary"]


# ---------------------------------------------------------------------------
# 4. Audit Logging Lifecycle
# ---------------------------------------------------------------------------
class TestAuditLogging:
    def test_audit_event_recorded_on_action(self, db_session):
        doc_id = uuid.uuid4()
        entry = audit_service.record_audit_event(
            db_session,
            action="DOCUMENT_VIEW_CONTENT",
            document_id=doc_id,
            document_name="test_report.pdf",
            status="SUCCESS",
            details="Decrypted 1024 bytes in memory",
        )
        assert entry is not None
        assert entry.action == "DOCUMENT_VIEW_CONTENT"
        assert entry.document_id == doc_id
        assert entry.status == "SUCCESS"

        # Verify queryable via audit-logs endpoint
        client = TestClient(app)
        res = client.get("/api/documents/audit-logs/recent?limit=10")
        assert res.status_code == 200
        logs = res.json()
        assert any(l["action"] == "DOCUMENT_VIEW_CONTENT" for l in logs)


# ---------------------------------------------------------------------------
# 5. Security Headers & Redacted Endpoint
# ---------------------------------------------------------------------------
class TestSecurityHeadersAndEndpoints:
    def test_security_headers_present(self, client):
        res = client.get("/api/health")
        assert res.status_code == 200
        assert res.headers.get("X-Content-Type-Options") == "nosniff"
        assert res.headers.get("X-Frame-Options") == "DENY"
        assert res.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"

    def test_anti_caching_on_documents_api(self, client):
        res = client.get("/api/documents/timeline")
        assert res.status_code == 200
        cache_control = res.headers.get("Cache-Control", "")
        assert "no-store" in cache_control
        assert "no-cache" in cache_control

    def test_redacted_document_endpoint(self, client, db_session):
        # Create a document with PHI
        doc_id = uuid.uuid4()
        doc = Document(
            id=doc_id,
            filename="confidential_patient.pdf",
            stored_path="uploads/confidential_patient.pdf.enc",
            file_type="pdf",
            mime_type="application/pdf",
            file_size=400,
            content_hash=uuid.uuid4().hex,
            status=DocumentStatus.COMPLETED,
            raw_text="Patient: James Wilson | SSN: 333-22-1111 | Diagnosed with Type 2 Diabetes.",
            structured_entities=json.dumps({
                "patient": {"name": "James Wilson", "ssn": "333-22-1111"},
                "conditions": [{"name": "Type 2 Diabetes"}],
            }),
        )
        db_session.add(doc)
        db_session.commit()

        res = client.get(f"/api/documents/{doc_id}/redacted")
        assert res.status_code == 200
        data = res.json()
        assert data["is_deidentified"] is True
        assert "333-22-1111" not in data["redacted_text"]
        assert "[REDACTED_SSN]" in data["redacted_text"]
        assert data["sanitized_entities"]["patient"]["ssn"] == "[REDACTED_SSN]"
        assert data["sanitized_entities"]["conditions"][0]["name"] == "Type 2 Diabetes"

        # Clean up
        db_session.delete(doc)
        db_session.commit()
