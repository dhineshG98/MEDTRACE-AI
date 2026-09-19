"""Tesseract OCR service.

Deliberately kept free of any AI/LLM concern -- this converts pixels to text
and nothing more.

If Tesseract is not installed, this module does not crash the application.
`is_available()` reports the situation and callers raise OcrUnavailableError,
which the API turns into a clear 503 message.
"""

import io
import shutil
from pathlib import Path
from typing import Optional

from app.config.settings import settings
from app.utils.logger import get_logger

logger = get_logger(__name__)

try:
    import pytesseract
    from PIL import Image, ImageOps

    _IMPORTS_OK = True
except ImportError:  # pragma: no cover - only when Phase 2 deps are missing
    pytesseract = None  # type: ignore[assignment]
    Image = None  # type: ignore[assignment]
    ImageOps = None  # type: ignore[assignment]
    _IMPORTS_OK = False


class OcrUnavailableError(Exception):
    """Tesseract is not installed or not reachable."""


class OcrFailedError(Exception):
    """Tesseract ran but could not produce text."""


def _configure_binary() -> Optional[str]:
    """Point pytesseract at the configured binary, or find it on PATH."""
    if not _IMPORTS_OK:
        return None
    if settings.TESSERACT_PATH:
        pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_PATH
        return settings.TESSERACT_PATH
    found = shutil.which("tesseract")
    if found:
        pytesseract.pytesseract.tesseract_cmd = found
    return found


def gemini_vision_ocr(image_bytes: bytes, mime_type: str = "image/png") -> str:
    """Uses Google Gemini Multimodal Vision to transcribe text from medical images."""
    import base64
    import json
    import urllib.request

    b64_img = base64.b64encode(image_bytes).decode("utf-8")
    model = settings.resolved_ai_model or "gemini-3.1-flash-lite"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={settings.resolved_ai_key}"

    payload = {
        "contents": [{
            "parts": [
                {
                    "text": (
                        "Transcribe all legible text from this clinical medical document or prescription image verbatim. "
                        "Do not summarize or interpret. Include patient details, dates, diagnoses, medication names, dosages, "
                        "frequencies, routes, and laboratory results as written."
                    )
                },
                {
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": b64_img,
                    }
                }
            ]
        }],
        "generationConfig": {
            "temperature": 0.0,
            "maxOutputTokens": 2048,
        }
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=settings.AI_TIMEOUT_SECONDS) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            parts = res.get("candidates", [{}])[0].get("content", {}).get("parts", [])
            if parts and "text" in parts[0]:
                return parts[0]["text"].strip()
            return ""
    except Exception as exc:
        logger.error("Gemini Vision OCR unavailable: %s", exc)
        raise OcrUnavailableError(f"AI Vision OCR unavailable: {exc}") from exc


def is_available() -> tuple[bool, str]:
    """Return (available, detail). Never raises."""
    if not _IMPORTS_OK:
        if settings.ai_configured and settings.resolved_ai_provider == "gemini":
            return True, f"AI Vision ({settings.resolved_ai_model})"
        return False, "pytesseract/Pillow not installed"
    binary = _configure_binary()
    if not binary:
        if settings.ai_configured and settings.resolved_ai_provider == "gemini":
            return True, f"AI Vision ({settings.resolved_ai_model})"
        return False, "Tesseract binary not found (set TESSERACT_PATH in .env)"
    try:
        version = pytesseract.get_tesseract_version()
        return True, f"Tesseract {version}"
    except Exception as exc:  # noqa: BLE001
        if settings.ai_configured and settings.resolved_ai_provider == "gemini":
            return True, f"AI Vision ({settings.resolved_ai_model})"
        return False, f"Tesseract not runnable: {type(exc).__name__}"


def _require_available() -> None:
    available, detail = is_available()
    if not available:
        raise OcrUnavailableError(detail)


def _preprocess(image: "Image.Image") -> "Image.Image":
    """Light preprocessing. Grayscale and autocontrast measurably help
    Tesseract on scanned medical documents without distorting the text."""
    image = image.convert("L")
    image = ImageOps.autocontrast(image)
    return image


def image_bytes_to_text(data: bytes, mime_type: str = "image/png") -> str:
    """Run OCR over a single image held in memory via Tesseract or Gemini Vision fallback."""
    _require_available()
    binary = _configure_binary()
    if binary:
        try:
            with Image.open(io.BytesIO(data)) as img:
                processed = _preprocess(img)
                text = pytesseract.image_to_string(
                    processed, lang=settings.OCR_LANGUAGES
                ).strip()
                if text:
                    return text
        except Exception as exc:
            logger.warning("Local Tesseract OCR failed (%s); attempting AI Vision fallback", exc)

    if settings.ai_configured and settings.resolved_ai_provider == "gemini":
        return gemini_vision_ocr(data, mime_type)

    raise OcrFailedError("Could not read text from the image.")


def image_file_to_text(path: Path) -> str:
    return image_bytes_to_text(Path(path).read_bytes())


def images_to_text(pages: list[bytes]) -> tuple[str, int]:
    """OCR a list of page images.

    Returns (combined_text, pages_that_produced_text). A page that fails is
    skipped rather than failing the whole document -- a partial read is more
    useful than none.
    """
    _require_available()
    parts: list[str] = []
    succeeded = 0

    for index, page in enumerate(pages, start=1):
        try:
            text = image_bytes_to_text(page)
        except OcrFailedError:
            logger.warning("OCR skipped page %d", index)
            continue
        if text:
            parts.append(text)
            succeeded += 1

    if succeeded == 0:
        raise OcrFailedError("No readable text was found in the document.")

    return "\n\n".join(parts), succeeded
