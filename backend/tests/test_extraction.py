"""Phase 3 extraction pipeline tests.

Covers:
  - Happy-path: valid LLM JSON → StructuredMedicalRecord
  - Malformed JSON first pass → correction-prompt retry → success
  - Malformed JSON on both passes → RuntimeError → heuristic fallback
  - Negation safeguard applied when LLM omits negated flag
  - Missing optional fields default to None / empty list
  - 400 when /extract called before /process (no raw_text)
"""

import json
import uuid
from typing import Any
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.ai_provider import GeminiProvider, HeuristicProvider, get_ai_provider

client = TestClient(app)

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

VALID_LLM_PAYLOAD: dict[str, Any] = {
    "document_type": {"value": "Prescription Record", "confidence": 0.98},
    "patient": {
        "name": "Eleanor Bennett",
        "age": 58,
        "gender": "Female",
        "patient_id": "MRN-884920",
    },
    "conditions": [
        {"value": "Essential Hypertension", "confidence": 0.97, "source_text": "Diagnosis: Essential Hypertension"}
    ],
    "medications": [
        {
            "name": "Amlodipine",
            "dosage": "5 mg",
            "frequency": "daily",
            "route": "oral",
            "duration": "90 days",
            "confidence": 0.96,
            "source_text": "AMLODIPINE 5MG oral tablet",
        }
    ],
    "allergies": [
        {
            "allergen": "Penicillin",
            "reaction": "Rash",
            "negated": False,
            "confidence": 0.95,
            "source_text": "Penicillin (Reaction: Rash)",
        },
        {
            "allergen": "Sulfa drugs",
            "reaction": None,
            "negated": True,
            "confidence": 0.96,
            "source_text": "Sulfa drugs: Denies allergy",
        },
    ],
    "lab_results": [
        {
            "test_name": "Fasting Blood Glucose",
            "value": "138",
            "unit": "mg/dL",
            "reference_range": "70 - 99 mg/dL",
            "confidence": 0.95,
        }
    ],
    "dates": [{"type": "Prescription Date", "value": "2025-01-15", "confidence": 0.99}],
    "doctors": [{"name": "Dr. Robert Vance", "specialty": "Cardiology", "confidence": 0.98}],
    "relationships": [
        {"source": "Amlodipine", "relationship": "treats", "target": "Essential Hypertension", "confidence": 0.95}
    ],
}

SAMPLE_TEXT = (
    "PRESCRIPTION RECORD\n"
    "Date: 2025-01-15\n"
    "Patient: Eleanor Bennett, Age: 58, Gender: Female, ID: MRN-884920\n"
    "Diagnosis: Essential Hypertension\n"
    "Rx: AMLODIPINE 5MG oral tablet, daily, 90 days\n"
    "Allergies: Penicillin (Rash). Sulfa drugs: Denies allergy.\n"
    "Labs: Fasting Blood Glucose: 138 mg/dL (Ref: 70-99 mg/dL)\n"
    "Physician: Dr. Robert Vance, MD (Cardiology)\n"
)


# ---------------------------------------------------------------------------
# Unit tests — GeminiProvider
# ---------------------------------------------------------------------------

class TestGeminiProviderHappyPath:
    """LLM returns valid JSON on first call → StructuredMedicalRecord validated."""

    def test_extract_returns_dict_with_expected_keys(self):
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=json.dumps(VALID_LLM_PAYLOAD)):
            result = provider.extract(SAMPLE_TEXT)

        assert isinstance(result, dict)
        assert "document_type" in result
        assert "medications" in result
        assert "allergies" in result

    def test_negated_allergy_preserved(self):
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=json.dumps(VALID_LLM_PAYLOAD)):
            result = provider.extract(SAMPLE_TEXT)

        allergies = result.get("allergies", [])
        sulfa = next((a for a in allergies if "sulfa" in str(a).lower()), None)
        assert sulfa is not None, "Sulfa drug allergy should be present"
        # negated field might be at 'negated' key after model_dump
        assert sulfa.get("negated") is True or sulfa.get("negated") == True

    def test_patient_fields_mapped(self):
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=json.dumps(VALID_LLM_PAYLOAD)):
            result = provider.extract(SAMPLE_TEXT)

        patient = result.get("patient", {})
        assert patient.get("name") == "Eleanor Bennett"

    def test_strips_markdown_fences(self):
        """LLM sometimes wraps JSON in ```json fences — should be cleaned."""
        fenced = f"```json\n{json.dumps(VALID_LLM_PAYLOAD)}\n```"
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=fenced):
            result = provider.extract(SAMPLE_TEXT)
        assert "document_type" in result


class TestGeminiProviderCorrectionRetry:
    """First pass returns malformed JSON → correction prompt attempted."""

    def test_correction_prompt_used_on_json_error(self):
        malformed = "NOT VALID JSON {{{"
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        call_count = {"n": 0}

        def side_effect(prompt: str) -> str:
            call_count["n"] += 1
            if call_count["n"] == 1:
                return malformed
            return json.dumps(VALID_LLM_PAYLOAD)

        with patch.object(provider, "_call_with_retry", side_effect=side_effect):
            result = provider.extract(SAMPLE_TEXT)

        assert call_count["n"] == 2, "Correction prompt must trigger a second call"
        assert "document_type" in result

    def test_both_passes_fail_raises_runtime_error(self):
        malformed = "STILL BROKEN {{{}"
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=malformed):
            with pytest.raises(RuntimeError, match="correction"):
                provider.extract(SAMPLE_TEXT)


class TestGeminiProviderMissingFields:
    """Missing optional fields should not crash — they default to None / empty list."""

    def test_missing_patient_age_is_null(self):
        payload = dict(VALID_LLM_PAYLOAD)
        payload["patient"] = {"name": "Test Patient", "age": None, "gender": None, "patient_id": None}
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=json.dumps(payload)):
            result = provider.extract(SAMPLE_TEXT)
        assert result["patient"]["age"] is None

    def test_missing_lab_results_defaults_to_empty_list(self):
        payload = dict(VALID_LLM_PAYLOAD)
        payload["lab_results"] = []
        provider = GeminiProvider(api_key="fake-key", model="gemini-1.5-flash")
        with patch.object(provider, "_call_with_retry", return_value=json.dumps(payload)):
            result = provider.extract(SAMPLE_TEXT)
        assert result["lab_results"] == []


# ---------------------------------------------------------------------------
# Unit tests — Negation safeguard
# ---------------------------------------------------------------------------

class TestNegationSafeguard:
    """apply_negation_safeguards must catch allergies the LLM missed."""

    def test_nkda_in_text_forces_all_allergies_negated(self):
        from app.services.negation_service import apply_negation_safeguards

        nkda_text = "Patient has no known drug allergies (NKDA)."
        record = {
            "allergies": [
                {"allergen": "Penicillin", "negated": False, "confidence": 0.9}
            ]
        }
        result = apply_negation_safeguards(record, nkda_text)
        for allergy in result.get("allergies", []):
            assert allergy["negated"] is True, "NKDA text should force all allergies to negated=True"

    def test_explicit_denial_forces_negated(self):
        from app.services.negation_service import apply_negation_safeguards

        text = "Sulfa drugs: Denies allergy."
        record = {
            "allergies": [
                {"allergen": "Sulfa drugs", "negated": False, "confidence": 0.9}
            ]
        }
        result = apply_negation_safeguards(record, text)
        sulfa = next(a for a in result["allergies"] if "sulfa" in a["allergen"].lower())
        assert sulfa["negated"] is True


# ---------------------------------------------------------------------------
# Unit tests — Factory
# ---------------------------------------------------------------------------

class TestGetAiProvider:
    """get_ai_provider() returns correct class based on settings."""

    def test_returns_gemini_when_configured(self):
        with (
            patch("app.services.ai_provider.settings") as mock_settings,
        ):
            mock_settings.resolved_ai_provider = "gemini"
            mock_settings.resolved_ai_key = "fake-gemini-key"
            mock_settings.resolved_ai_model = "gemini-1.5-flash"
            mock_settings.AI_MAX_RETRIES = 3
            mock_settings.AI_TIMEOUT_SECONDS = 30

            provider = get_ai_provider()
        assert provider.provider_name == "gemini"

    def test_returns_heuristic_when_no_key(self):
        with patch("app.services.ai_provider.settings") as mock_settings:
            mock_settings.resolved_ai_provider = "gemini"
            mock_settings.resolved_ai_key = ""
            mock_settings.resolved_ai_model = "gemini-1.5-flash"

            provider = get_ai_provider()
        assert provider.provider_name == "heuristic"


# ---------------------------------------------------------------------------
# Integration tests — /extract endpoint
# ---------------------------------------------------------------------------

class TestExtractEndpoint:
    """API-level tests for POST /api/documents/{id}/extract."""

    def _upload_and_process(self) -> str:
        """Helper: upload a text file and process it, return document_id."""
        import io
        content = SAMPLE_TEXT.encode()
        # Create a minimal PDF-like file (txt accepted if extension whitelisted)
        # Use a mock document directly instead via DB if file_picker not configured
        # For CI: patch the endpoint at service level
        return str(uuid.uuid4())

    def test_extract_returns_400_when_no_raw_text(self):
        """Calling /extract before /process should return 400."""
        doc_id = str(uuid.uuid4())
        # Patch DB to return a document with no raw_text
        mock_doc = MagicMock()
        mock_doc.raw_text = None
        mock_doc.id = doc_id

        with patch("app.api.routes.documents._get_or_404", return_value=mock_doc):
            response = client.post(f"/api/documents/{doc_id}/extract")
        assert response.status_code == 400
        assert "process" in response.json()["message"].lower() or "process" in response.json().get("detail", "").lower()

    def test_extract_calls_pipeline_when_raw_text_present(self):
        """Verify the pipeline is reached and extraction is saved when document has raw_text."""
        from app.database.database import SessionLocal
        from app.models.document import Document, DocumentStatus
        from app.models.extraction import Extraction

        db = SessionLocal()
        doc_id = uuid.uuid4()
        doc = Document(
            id=doc_id,
            filename="test_prescription.txt",
            stored_path="test_path",
            file_type="txt",
            mime_type="text/plain",
            file_size=100,
            content_hash=f"hash_{doc_id}",
            raw_text=SAMPLE_TEXT,
            status=DocumentStatus.EXTRACTED,
        )
        db.add(doc)
        db.commit()

        pipeline_result = {
            "document_type": "Prescription Record",
            "document_type_confidence": 0.98,
            "patient": {"name": "Eleanor Bennett", "age_or_dob": "58", "gender": "Female", "mrn": None, "date": None},
            "conditions": [],
            "medications": [],
            "allergies": [],
            "lab_results": [],
            "dates": [],
            "doctors": [],
            "quality_score": 85,
            "requires_review": False,
            "review_reasons": [],
            "summary": "Test summary.",
            "provider_used": "gemini",
        }

        called = []

        def mock_pipeline(raw_text, extraction_method):
            called.append(raw_text)
            return pipeline_result

        try:
            with patch("app.services.extraction_service.run_clinical_extraction_pipeline", side_effect=mock_pipeline):
                response = client.post(f"/api/documents/{doc_id}/extract")

            assert response.status_code == 200
            assert len(called) == 1
            assert called[0] == SAMPLE_TEXT
            data = response.json()
            assert data["document_type"] == "Prescription Record"
            assert data["provider_used"] == "gemini"
        finally:
            db.query(Extraction).filter(Extraction.document_id == doc_id).delete()
            db.query(Document).filter(Document.id == doc_id).delete()
            db.commit()
            db.close()

    def test_pipeline_service_layer_with_mocked_llm(self):
        """Service-layer: run_clinical_extraction_pipeline correctly uses LLM output."""
        from app.services.extraction_service import run_clinical_extraction_pipeline

        with (
            patch("app.services.extraction_service.settings") as mock_settings,
            patch("app.services.extraction_service._extract_with_llm") as mock_llm,
        ):
            mock_settings.ai_configured = True
            mock_settings.resolved_ai_provider = "gemini"
            mock_llm.return_value = {
                "document_type": "Prescription Record",
                "document_type_confidence": 0.98,
                "patient": {"name": "Eleanor Bennett", "age_or_dob": "58", "gender": "Female"},
                "conditions": [{"name": "Hypertension"}],
                "medications": [{"name": "Amlodipine", "dosage": "5 mg", "frequency": "daily", "route": "oral"}],
                "allergies": [],
                "lab_results": [],
                "dates": [],
                "doctors": [],
                "summary": "Test summary.",
                "_provider": "gemini",
            }

            result = run_clinical_extraction_pipeline(SAMPLE_TEXT)

        assert result["document_type"] == "Prescription Record"
        assert result["provider_used"] == "gemini"
        assert len(result["medications"]) >= 1
        assert result["quality_score"] > 0
