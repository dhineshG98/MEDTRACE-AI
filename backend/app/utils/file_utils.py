"""File validation and safe storage.

Security rules enforced here:
  - the original filename is never used on disk
  - extension is checked against an allowlist
  - magic bytes are checked, so a renamed .exe cannot pass as a .pdf
  - size is capped and empty files are rejected
"""

import hashlib
import re
import unicodedata
import uuid
from pathlib import Path
from typing import Optional

from app.config.settings import settings
from app.utils.logger import get_logger

logger = get_logger(__name__)

# Magic-byte signatures. DOCX is a ZIP container, so it shares PK\x03\x04.
_SIGNATURES: dict[str, tuple[bytes, ...]] = {
    "pdf": (b"%PDF-",),
    "png": (b"\x89PNG\r\n\x1a\n",),
    "jpg": (b"\xff\xd8\xff",),
    "jpeg": (b"\xff\xd8\xff",),
    "docx": (b"PK\x03\x04", b"PK\x05\x06", b"PK\x07\x08"),
}

_MIME_TYPES = {
    "pdf": "application/pdf",
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}

IMAGE_EXTENSIONS = {"png", "jpg", "jpeg"}


class FileValidationError(Exception):
    """Raised when an upload fails validation. Message is safe to show a user."""

    def __init__(self, code: str, message: str):
        self.code = code
        self.message = message
        super().__init__(message)


def sanitize_filename(filename: Optional[str]) -> str:
    """Return a display-safe version of a user-supplied filename.

    This is for display and storage metadata only -- the on-disk name is
    always a generated UUID, never this value.
    """
    if not filename:
        return "untitled"

    name = Path(filename).name  # strips any directory component
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    name = re.sub(r"[^A-Za-z0-9._-]", "_", name)
    name = re.sub(r"_{2,}", "_", name).strip("._-")
    return name[:200] or "untitled"


def get_extension(filename: Optional[str]) -> str:
    return Path(filename or "").suffix.lower().lstrip(".")


def validate_extension(filename: Optional[str]) -> str:
    ext = get_extension(filename)
    allowed = settings.allowed_extensions
    if not ext:
        raise FileValidationError(
            "missing_extension", "The file has no extension, so its type cannot be determined."
        )
    if ext not in allowed:
        raise FileValidationError(
            "unsupported_file_type",
            f"'{ext.upper()}' is not supported. Accepted types: {', '.join(e.upper() for e in allowed)}.",
        )
    return ext


def validate_size(size_bytes: int) -> None:
    if size_bytes == 0:
        raise FileValidationError("empty_file", "The uploaded file is empty.")
    if size_bytes > settings.max_upload_size_bytes:
        raise FileValidationError(
            "file_too_large",
            f"File exceeds the {settings.MAX_UPLOAD_SIZE_MB} MB limit.",
        )


def validate_magic_bytes(content: bytes, ext: str) -> None:
    """Confirm the file's real type matches its extension."""
    signatures = _SIGNATURES.get(ext)
    if not signatures:
        return
    if not any(content.startswith(sig) for sig in signatures):
        raise FileValidationError(
            "content_mismatch",
            f"The file contents do not look like a valid {ext.upper()} file.",
        )


def mime_for_extension(ext: str) -> str:
    return _MIME_TYPES.get(ext, "application/octet-stream")


def content_hash(content: bytes) -> str:
    """SHA-256 of the file. Used to detect re-uploads of the same document."""
    return hashlib.sha256(content).hexdigest()


def build_storage_path(document_id: uuid.UUID, ext: str) -> Path:
    """Generated on-disk path. The user's filename never touches the filesystem.

    All files are stored encrypted at rest with the .enc extension.
    """
    return settings.UPLOAD_DIR / f"{document_id}.enc"


def save_upload(content: bytes, document_id: uuid.UUID, ext: str) -> Path:
    from app.services import encryption_service

    path = build_storage_path(document_id, ext)
    encryption_service.encrypt_file(content, path)
    logger.info("Stored AES-256-GCM encrypted document %s (%s, %d bytes plaintext)", document_id, ext, len(content))
    return path


def delete_stored_file(path: Optional[str]) -> bool:
    """Cryptographically shreds and deletes a stored file from the upload directory."""
    if not path:
        return False
    target = Path(path)
    try:
        # Refuse to delete anything outside the upload directory.
        target.resolve().relative_to(settings.UPLOAD_DIR.resolve())
    except ValueError:
        logger.warning("Refused to delete a path outside the upload directory")
        return False
    if target.exists():
        from app.services.encryption_service import secure_shred_file
        return secure_shred_file(target)
    return False
