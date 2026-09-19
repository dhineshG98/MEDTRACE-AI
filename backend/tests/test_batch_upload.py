"""Tests for batch document upload endpoint (POST /api/documents/upload-batch)."""

import io
from pathlib import Path
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.models.document import Document
from app.database.database import SessionLocal
from app.services import encryption_service

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


def test_batch_upload_multiple_valid_files(client, db_session):
    """Test uploading multiple valid medical files simultaneously."""
    # PDF valid magic bytes
    pdf_data = b"%PDF-1.4\n%test multi upload 1\n%%EOF"
    # PNG valid magic bytes
    png_data = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"

    files = [
        ("files", ("batch_report_1.pdf", io.BytesIO(pdf_data), "application/pdf")),
        ("files", ("batch_scan_2.png", io.BytesIO(png_data), "image/png")),
    ]

    response = client.post("/api/documents/upload-batch", files=files)
    assert response.status_code == 201
    results = response.json()
    assert len(results) == 2
    assert results[0]["filename"] == "batch_report_1.pdf"
    assert results[0]["file_type"] == "pdf"
    assert results[1]["filename"] == "batch_scan_2.png"
    assert results[1]["file_type"] == "png"

    # Verify both documents are encrypted on disk
    for res in results:
        doc = db_session.get(Document, res["document_id"])
        assert doc is not None
        file_path = Path(doc.stored_path)
        assert file_path.exists()
        assert file_path.suffix == ".enc"

        # Verify decryption works
        decrypted = encryption_service.decrypt_file(file_path)
        assert len(decrypted) > 0


def test_batch_upload_rejects_invalid_extension(client):
    """Test that batch upload rejects files with invalid extensions."""
    files = [
        ("files", ("test.exe", io.BytesIO(b"MZ\x90\x00"), "application/octet-stream")),
    ]
    response = client.post("/api/documents/upload-batch", files=files)
    assert response.status_code == 400
    assert "not supported" in response.json()["message"].lower()
