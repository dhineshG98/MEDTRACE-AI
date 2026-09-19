"""Phase 2 tests: upload validation, text extraction, OCR fallback, CRUD."""

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import app

SAMPLES = Path(__file__).parent / "sample_data"


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def _upload(client, path: Path, mime: str, name: str | None = None):
    with path.open("rb") as fh:
        return client.post(
            "/api/documents/upload",
            files={"file": (name or path.name, fh, mime)},
        )


# --- validation ---------------------------------------------------------

def test_rejects_unsupported_extension(client):
    response = client.post(
        "/api/documents/upload",
        files={"file": ("notes.exe", b"MZ\x90\x00binary", "application/octet-stream")},
    )
    assert response.status_code == 400
    assert "not supported" in response.json()["message"].lower()


def test_rejects_empty_file(client):
    response = client.post(
        "/api/documents/upload",
        files={"file": ("empty.pdf", b"", "application/pdf")},
    )
    assert response.status_code == 400
    assert "empty" in response.json()["message"].lower()


def test_rejects_file_with_mismatched_magic_bytes(client):
    """An executable renamed to .pdf must not get through."""
    response = _upload(client, SAMPLES / "fake.pdf", "application/pdf")
    assert response.status_code == 400
    assert "do not look like" in response.json()["message"]


def test_original_filename_is_sanitized(client):
    """A path-traversal filename must not reach the filesystem."""
    response = _upload(
        client, SAMPLES / "sample_prescription.pdf", "application/pdf",
        name="../../etc/pass wd.pdf",
    )
    assert response.status_code == 201

    stored_name = response.json()["filename"]
    assert "/" not in stored_name and "\\" not in stored_name
    assert ".." not in stored_name


# --- extraction ---------------------------------------------------------

def test_digital_pdf_uses_text_layer(client):
    upload = _upload(client, SAMPLES / "sample_prescription.pdf", "application/pdf")
    assert upload.status_code == 201
    doc_id = upload.json()["document_id"]

    result = client.post(f"/api/documents/{doc_id}/process")
    assert result.status_code == 200

    body = result.json()
    assert body["extraction_method"] == "pdf_text"
    assert body["status"] == "extracted"
    assert "Amlodipine" in body["text"]
    assert "Hypertension" in body["text"]
    assert body["word_count"] > 0


def test_scanned_pdf_falls_back_to_ocr(client):
    """A PDF with no text layer must route through OCR, not fail."""
    upload = _upload(client, SAMPLES / "sample_scanned.pdf", "application/pdf")
    doc_id = upload.json()["document_id"]

    result = client.post(f"/api/documents/{doc_id}/process")

    if result.status_code == 503:
        pytest.skip("Tesseract not installed on this machine")

    assert result.status_code == 200
    body = result.json()
    assert body["extraction_method"] == "ocr"
    assert body["ocr_pages"] >= 1
    assert "Amlodipine" in body["text"]


def test_docx_extracts_paragraphs_and_tables(client):
    upload = _upload(
        client,
        SAMPLES / "sample_prescription.docx",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    )
    doc_id = upload.json()["document_id"]

    result = client.post(f"/api/documents/{doc_id}/process")
    assert result.status_code == 200

    body = result.json()
    assert body["extraction_method"] == "docx"
    assert "Amlodipine" in body["text"]
    # table content must be captured, not just paragraphs
    assert "148/92" in body["text"]


def test_image_is_read_via_ocr(client):
    upload = _upload(client, SAMPLES / "scan.png", "image/png")
    doc_id = upload.json()["document_id"]

    result = client.post(f"/api/documents/{doc_id}/process")
    if result.status_code == 503:
        pytest.skip("Tesseract not installed on this machine")

    assert result.status_code == 200
    assert result.json()["extraction_method"] == "image_ocr"


def test_sample_prescription_fields_are_present_in_text(client):
    """The Step 22 sample must survive extraction intact, ready for Phase 3 AI."""
    upload = _upload(client, SAMPLES / "sample_prescription.pdf", "application/pdf")
    doc_id = upload.json()["document_id"]
    text = client.post(f"/api/documents/{doc_id}/process").json()["text"]

    for expected in ["John Doe", "52", "Hypertension", "Amlodipine", "5 mg",
                     "once daily", "30 days", "Penicillin", "skin rash"]:
        assert expected in text, f"missing from extracted text: {expected}"


# --- lifecycle ----------------------------------------------------------

def test_duplicate_upload_is_flagged_not_rejected(client):
    first = _upload(client, SAMPLES / "sample_prescription.docx",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    second = _upload(client, SAMPLES / "sample_prescription.docx",
                     "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    assert second.status_code == 201
    assert second.json()["duplicate_of"] is not None


def test_list_excludes_raw_text(client):
    """The list endpoint must never ship medical text to the client."""
    body = client.get("/api/documents?limit=5").json()
    assert body["total"] >= 1
    for row in body["documents"]:
        assert "raw_text" not in row


def test_detail_includes_raw_text(client):
    upload = _upload(client, SAMPLES / "sample_prescription.pdf", "application/pdf")
    doc_id = upload.json()["document_id"]
    client.post(f"/api/documents/{doc_id}/process")

    body = client.get(f"/api/documents/{doc_id}").json()
    assert "Amlodipine" in body["raw_text"]
    assert body["file_type"] == "pdf"


def test_unknown_document_returns_404(client):
    response = client.get("/api/documents/00000000-0000-0000-0000-000000000000")
    assert response.status_code == 404


def test_delete_removes_document_and_file(client):
    upload = _upload(client, SAMPLES / "sample_prescription.pdf", "application/pdf")
    doc_id = upload.json()["document_id"]

    deleted = client.delete(f"/api/documents/{doc_id}")
    assert deleted.status_code == 200
    assert deleted.json()["file_removed"] is True
    assert client.get(f"/api/documents/{doc_id}").status_code == 404


def test_failure_preserves_document_row(client):
    """A corrupt file must leave the document stored with a safe error."""
    corrupt = b"%PDF-1.4\n garbage that is not a real pdf body"
    upload = client.post(
        "/api/documents/upload",
        files={"file": ("broken.pdf", corrupt, "application/pdf")},
    )
    doc_id = upload.json()["document_id"]

    result = client.post(f"/api/documents/{doc_id}/process")
    assert result.status_code in (422, 503)

    row = client.get(f"/api/documents/{doc_id}").json()
    assert row["status"] == "failed"
    assert row["error_message"]
    assert "Traceback" not in row["error_message"]
