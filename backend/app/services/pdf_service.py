"""PDF handling via PyMuPDF.

Two jobs:
  1. pull the embedded text layer out of a digital PDF (fast, accurate)
  2. rasterize pages to PNG when there is no text layer, so ocr_service
     can read a scanned document
"""

from pathlib import Path

from app.config.settings import settings
from app.utils.logger import get_logger

logger = get_logger(__name__)

try:
    try:
        import pymupdf as fitz
    except ImportError:
        import fitz  # PyMuPDF

    _PYMUPDF_OK = True
except ImportError:  # pragma: no cover
    fitz = None  # type: ignore[assignment]
    _PYMUPDF_OK = False

# 200 DPI is the practical sweet spot for OCR accuracy vs. memory on scans.
_OCR_DPI = 200
_MAX_OCR_PAGES = 30


class PdfUnavailableError(Exception):
    """PyMuPDF is not installed."""


class PdfReadError(Exception):
    """The PDF is corrupt, encrypted, or otherwise unreadable."""


def is_available() -> tuple[bool, str]:
    if not _PYMUPDF_OK:
        return False, "PyMuPDF not installed"
    return True, f"PyMuPDF {fitz.__doc__.strip() if fitz.__doc__ else 'ready'}"


def _require_available() -> None:
    if not _PYMUPDF_OK:
        raise PdfUnavailableError("PyMuPDF is not installed on the server.")


def extract_text(path: Path) -> tuple[str, int]:
    """Extract the embedded text layer. Returns (text, page_count).

    An empty or very short result means the PDF is almost certainly a scan --
    the caller then falls back to OCR.
    """
    _require_available()
    try:
        with fitz.open(path) as doc:
            if doc.needs_pass:
                raise PdfReadError("The PDF is password protected.")
            pages = [page.get_text("text").strip() for page in doc]
            return "\n\n".join(p for p in pages if p), doc.page_count
    except PdfReadError:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("PDF read failed: %s", type(exc).__name__)
        raise PdfReadError("The PDF could not be opened. It may be corrupt.") from exc


def needs_ocr(text: str) -> bool:
    """A PDF with little or no text layer is treated as scanned."""
    return len(text.strip()) < settings.PDF_TEXT_MIN_CHARS


def render_pages_to_images(path: Path, max_pages: int = _MAX_OCR_PAGES) -> list[bytes]:
    """Rasterize pages to PNG bytes for OCR."""
    _require_available()
    try:
        images: list[bytes] = []
        with fitz.open(path) as doc:
            if doc.needs_pass:
                raise PdfReadError("The PDF is password protected.")
            for page in doc[:max_pages]:
                pixmap = page.get_pixmap(dpi=_OCR_DPI)
                images.append(pixmap.tobytes("png"))
            if doc.page_count > max_pages:
                logger.warning(
                    "Document has %d pages; OCR limited to the first %d",
                    doc.page_count,
                    max_pages,
                )
        return images
    except PdfReadError:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("PDF rasterization failed: %s", type(exc).__name__)
        raise PdfReadError("The PDF pages could not be rendered for OCR.") from exc
