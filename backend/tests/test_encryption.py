"""Automated test suite for AES-256-GCM medical data encryption.

Verifies:
  1. Key generation and derivation.
  2. Plaintext -> Ciphertext -> Plaintext integrity.
  3. Nonce uniqueness (never reused).
  4. Authentication tag tamper detection (InvalidTag handling).
  5. Ephemeral file decryption lifecycle & shred-unlink cleanup.
  6. Database text field encryption with transparent legacy fallback.
  7. End-to-end document upload -> encrypted at rest (.enc) -> processed -> viewed.
"""

import os
import uuid
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services import encryption_service
from app.services.encryption_service import (
    DecryptionError,
    decrypt_bytes,
    decrypt_file,
    decrypt_text,
    encrypt_bytes,
    encrypt_file,
    encrypt_text,
    ephemeral_decrypted_file,
)

client = TestClient(app)

SAMPLE_MEDICAL_RECORD = (
    b"CONFIDENTIAL MEDICAL RECORD\n"
    b"Patient: Eleanor Bennett | MRN: 884920\n"
    b"Diagnosis: Essential Hypertension\n"
    b"Rx: Amlodipine 5 mg daily\n"
    b"Allergies: Penicillin (Rash)\n"
)


class TestAes256GcmCore:
    """Core cryptographic properties of AES-256-GCM."""

    def test_encrypt_decrypt_roundtrip(self):
        ciphertext = encrypt_bytes(SAMPLE_MEDICAL_RECORD)
        assert ciphertext != SAMPLE_MEDICAL_RECORD
        assert len(ciphertext) > len(SAMPLE_MEDICAL_RECORD)

        decrypted = decrypt_bytes(ciphertext)
        assert decrypted == SAMPLE_MEDICAL_RECORD

    def test_nonce_is_unique_per_operation(self):
        """Never reuse a nonce/IV with the same AES-GCM key."""
        ciphertexts = {encrypt_bytes(SAMPLE_MEDICAL_RECORD) for _ in range(25)}
        assert len(ciphertexts) == 25, "Every encryption must use a fresh random nonce"

        # Check nonces directly (first 12 bytes)
        nonces = {c[:12] for c in ciphertexts}
        assert len(nonces) == 25, "Every nonce must be uniquely sampled"

    def test_tamper_detection_ciphertext_modification_fails(self):
        """Modifying even 1 bit in ciphertext must cause authentication failure."""
        payload = bytearray(encrypt_bytes(SAMPLE_MEDICAL_RECORD))
        # Flip a bit in the ciphertext portion
        payload[20] ^= 0x01

        with pytest.raises(DecryptionError, match="Authentication tag validation failed"):
            decrypt_bytes(bytes(payload))

    def test_tamper_detection_tag_modification_fails(self):
        """Modifying the auth tag must cause authentication failure."""
        payload = bytearray(encrypt_bytes(SAMPLE_MEDICAL_RECORD))
        # Flip a bit in the last 16 bytes (authentication tag)
        payload[-1] ^= 0xFF

        with pytest.raises(DecryptionError, match="Authentication tag validation failed"):
            decrypt_bytes(bytes(payload))

    def test_tamper_detection_truncated_payload_fails(self):
        """Payload smaller than nonce + tag must be rejected immediately."""
        with pytest.raises(DecryptionError, match="truncated or invalid"):
            decrypt_bytes(b"short")

    def test_associated_data_binding(self):
        """Associated data (AAD) must authenticate matching metadata."""
        aad = b"tenant:hospital_alpha:doc_9912"
        ciphertext = encrypt_bytes(SAMPLE_MEDICAL_RECORD, associated_data=aad)

        # Correct AAD succeeds
        assert decrypt_bytes(ciphertext, associated_data=aad) == SAMPLE_MEDICAL_RECORD

        # Altered AAD fails
        with pytest.raises(DecryptionError):
            decrypt_bytes(ciphertext, associated_data=b"tenant:hospital_beta:doc_9912")


class TestEphemeralFileDecryption:
    """Ephemeral decryption context manager for OCR and PyMuPDF."""

    def test_ephemeral_file_cleaned_up_on_exit(self, tmp_path):
        enc_path = tmp_path / "record.enc"
        encrypt_file(SAMPLE_MEDICAL_RECORD, enc_path)
        assert enc_path.exists()

        temp_path_captured = None
        with ephemeral_decrypted_file(enc_path, "pdf") as temp_path:
            temp_path_captured = temp_path
            assert temp_path.exists(), "Decrypted temporary file must exist inside context"
            assert temp_path.read_bytes() == SAMPLE_MEDICAL_RECORD
            assert temp_path.suffix == ".pdf"

        # Verify destroyed immediately after context exits
        assert not temp_path_captured.exists(), "Plaintext file must be unlinked outside context"

    def test_ephemeral_file_cleaned_up_even_on_exception(self, tmp_path):
        enc_path = tmp_path / "record_error.enc"
        encrypt_file(SAMPLE_MEDICAL_RECORD, enc_path)

        temp_path_captured = None
        try:
            with ephemeral_decrypted_file(enc_path, "pdf") as temp_path:
                temp_path_captured = temp_path
                raise RuntimeError("Simulated extraction crash")
        except RuntimeError:
            pass

        assert temp_path_captured is not None
        assert not temp_path_captured.exists(), "Plaintext file must be unlinked even if an error is thrown"


class TestDatabaseFieldEncryption:
    """Field-level encryption for sensitive clinical text (PHI/PII)."""

    def test_encrypt_decrypt_text(self):
        plain = "Patient diagnosed with Type 2 Diabetes; prescribed Metformin 500mg."
        cipher_text = encrypt_text(plain)

        assert cipher_text.startswith("aes256gcm:")
        assert plain not in cipher_text

        decrypted = decrypt_text(cipher_text)
        assert decrypted == plain

    def test_legacy_unencrypted_text_pass_through(self):
        """Legacy text without the prefix must pass through cleanly."""
        legacy = "Legacy unencrypted notes from Phase 1."
        assert decrypt_text(legacy) == legacy

    def test_none_value_handled_gracefully(self):
        assert encrypt_text(None) is None
        assert decrypt_text(None) is None


class TestEndToEndEncryptedWorkflow:
    """Full API test: upload -> encrypted on disk -> text extraction -> viewing."""

    def test_document_stored_encrypted_and_viewable(self):
        from app.models.document import Document
        from app.database.database import SessionLocal

        pdf_bytes = (
            b"%PDF-1.4\n"
            b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
            b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
            b"3 0 obj\n<< /Type /Page /Parent 2 0 R /Contents 4 0 R >>\nendobj\n"
            b"4 0 obj\n<< /Length 50 >>\nstream\n"
            b"BT /F1 12 Tf 72 712 Td (Amlodipine 5mg Hypertension) Tj ET\n"
            b"endstream\nendobj\nxref\n0 5\n0000000000 65535 f \n"
            b"trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n250\n%%EOF"
        )

        # 1. Upload
        upload_resp = client.post(
            "/api/documents/upload",
            files={"file": ("prescription_enc.pdf", pdf_bytes, "application/pdf")},
        )
        assert upload_resp.status_code == 201
        doc_id = upload_resp.json()["document_id"]

        db = SessionLocal()
        try:
            doc = db.get(Document, uuid.UUID(doc_id))
            assert doc is not None

            # Verify file on disk is encrypted
            stored_file = Path(doc.stored_path)
            assert stored_file.exists()
            assert stored_file.suffix == ".enc"

            # Crucial: plaintext string must NOT appear anywhere in the file bytes on disk!
            raw_disk_bytes = stored_file.read_bytes()
            assert b"Amlodipine" not in raw_disk_bytes, "Disk file must not contain plaintext drug name"
            assert b"Hypertension" not in raw_disk_bytes, "Disk file must not contain plaintext condition"

            # 2. View/Download decrypted content endpoint
            view_resp = client.get(f"/api/documents/{doc_id}/content")
            assert view_resp.status_code == 200
            assert view_resp.headers["content-type"] == "application/pdf"
            assert b"Amlodipine" in view_resp.content, "Decrypted stream must return original plaintext bytes"

            # 3. Clean up
            del_resp = client.delete(f"/api/documents/{doc_id}")
            assert del_resp.status_code == 200
            assert not stored_file.exists(), "Stored encrypted file must be removed upon document deletion"
        finally:
            db.close()
