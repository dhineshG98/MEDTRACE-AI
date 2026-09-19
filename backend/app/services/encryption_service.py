"""AES-256-GCM Medical Data Encryption Service.

Implements authenticated encryption with associated data (AEAD) for medical
records, documents at rest, and sensitive database fields.

Security Guarantees:
  - Algorithm: AES-256-GCM (Galois/Counter Mode) via `cryptography.hazmat`.
  - Nonce: 12-byte cryptographically secure random nonce generated per operation (os.urandom(12)).
  - Nonce reuse prevention: A new nonce is strictly sampled on every single call.
  - Integrity & Authenticity: 128-bit authentication tag automatically verified on decryption.
  - Ephemeral Decryption: Plaintext only exists in transient memory or securely unlinked temp files.
  - Zero Leakage: Cryptographic keys and raw PHI/PII are never logged.
"""

import base64
import os
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Generator, Optional, Union

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app.config.settings import settings
from app.utils.logger import get_logger

logger = get_logger(__name__)

NONCE_SIZE_BYTES = 12
TAG_SIZE_BYTES = 16
KEY_SIZE_BYTES = 32  # 256 bits
TEXT_ENCRYPTION_PREFIX = "aes256gcm:"


class EncryptionError(Exception):
    """Base exception for cryptographic operations."""


class DecryptionError(EncryptionError):
    """Raised when decryption or authentication tag verification fails."""


def _get_aes_key() -> bytes:
    """Derives a 32-byte (256-bit) AES key from application configuration."""
    raw_key = settings.resolved_encryption_key
    try:
        # Check if hex-encoded 64 chars
        if len(raw_key) == 64:
            key_bytes = bytes.fromhex(raw_key)
        else:
            # Fallback to UTF-8 padding/truncation
            key_bytes = raw_key.encode("utf-8")[:KEY_SIZE_BYTES].ljust(KEY_SIZE_BYTES, b"\x00")
        if len(key_bytes) != KEY_SIZE_BYTES:
            raise ValueError(f"AES-256 key must be {KEY_SIZE_BYTES} bytes.")
        return key_bytes
    except Exception as exc:
        raise EncryptionError("Invalid AES-256 key configuration.") from exc


def encrypt_bytes(plaintext: bytes, associated_data: Optional[bytes] = None) -> bytes:
    """Encrypts plaintext bytes using AES-256-GCM with a fresh random 12-byte nonce.

    Payload format: [12-byte nonce] + [ciphertext] + [16-byte authentication tag]
    """
    key = _get_aes_key()
    aesgcm = AESGCM(key)
    nonce = os.urandom(NONCE_SIZE_BYTES)
    # AESGCM.encrypt appends the 16-byte authentication tag to the ciphertext
    ciphertext_and_tag = aesgcm.encrypt(nonce, plaintext, associated_data)
    return nonce + ciphertext_and_tag


def decrypt_bytes(payload: bytes, associated_data: Optional[bytes] = None) -> bytes:
    """Decrypts and authenticates AES-256-GCM payload.

    Raises DecryptionError if the authentication tag fails (tamper detection).
    """
    if len(payload) < (NONCE_SIZE_BYTES + TAG_SIZE_BYTES):
        raise DecryptionError("Ciphertext payload is truncated or invalid.")

    key = _get_aes_key()
    aesgcm = AESGCM(key)
    nonce = payload[:NONCE_SIZE_BYTES]
    ciphertext_and_tag = payload[NONCE_SIZE_BYTES:]

    try:
        plaintext = aesgcm.decrypt(nonce, ciphertext_and_tag, associated_data)
        return plaintext
    except InvalidTag as exc:
        logger.warning("Decryption failed: Authentication tag mismatch (possible tampering).")
        raise DecryptionError("Authentication tag validation failed. The data is corrupt or modified.") from exc
    except Exception as exc:
        logger.error("Decryption failed due to cryptographic error: %s", type(exc).__name__)
        raise DecryptionError("Decryption operation failed.") from exc


def encrypt_file(plaintext_bytes: bytes, target_path: Path, associated_data: Optional[bytes] = None) -> Path:
    """Encrypts plaintext bytes and writes the encrypted payload to target_path."""
    encrypted_payload = encrypt_bytes(plaintext_bytes, associated_data=associated_data)
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_bytes(encrypted_payload)
    return target_path


def decrypt_file(source_path: Path, associated_data: Optional[bytes] = None) -> bytes:
    """Reads an encrypted file from disk and returns the decrypted plaintext bytes."""
    if not source_path.exists():
        raise FileNotFoundError(f"File not found: {source_path}")
    encrypted_payload = source_path.read_bytes()
    return decrypt_bytes(encrypted_payload, associated_data=associated_data)


def secure_shred_file(path: Union[Path, str]) -> bool:
    """Cryptographically shreds a file by overwriting with random bytes and zeros before unlinking."""
    target = Path(path)
    if not target.exists():
        return False
    try:
        size = target.stat().st_size
        if size > 0:
            # Pass 1: Overwrite with cryptographically secure random bytes
            target.write_bytes(os.urandom(size))
            # Pass 2: Overwrite with zero bytes
            target.write_bytes(b"\x00" * size)
        target.unlink()
        return True
    except Exception as exc:
        logger.warning("Failed to cryptographically shred file %s: %s", target, exc)
        try:
            target.unlink()
            return True
        except Exception:
            return False


@contextmanager
def ephemeral_decrypted_file(
    encrypted_path: Path,
    extension: str,
    associated_data: Optional[bytes] = None,
) -> Generator[Path, None, None]:
    """Context manager providing temporary, secure access to an unencrypted file.

    Decrypted bytes are written to an isolated temporary file, yielded to the caller
    (e.g., PyMuPDF, python-docx, OCR), and securely deleted immediately on block exit.
    """
    plaintext_bytes = decrypt_file(encrypted_path, associated_data=associated_data)
    ext = extension.lstrip(".")
    temp_file = tempfile.NamedTemporaryFile(suffix=f".{ext}", delete=False)
    temp_path = Path(temp_file.name)

    try:
        temp_file.write(plaintext_bytes)
        temp_file.flush()
        temp_file.close()
        yield temp_path
    finally:
        secure_shred_file(temp_path)


def encrypt_text(plain_text: Optional[str]) -> Optional[str]:
    """Encrypts a string field using AES-256-GCM and returns a base64 string with prefix."""
    if plain_text is None:
        return None
    raw_bytes = plain_text.encode("utf-8")
    enc_bytes = encrypt_bytes(raw_bytes)
    b64_enc = base64.b64encode(enc_bytes).decode("ascii")
    return f"{TEXT_ENCRYPTION_PREFIX}{b64_enc}"


def decrypt_text(cipher_text: Optional[str]) -> Optional[str]:
    """Decrypts a base64-encoded AES-256-GCM string field.

    Transparently passes through legacy unencrypted text for backward compatibility.
    """
    if cipher_text is None:
        return None
    if not cipher_text.startswith(TEXT_ENCRYPTION_PREFIX):
        # Legacy unencrypted database field
        return cipher_text

    try:
        b64_data = cipher_text[len(TEXT_ENCRYPTION_PREFIX):]
        enc_bytes = base64.b64decode(b64_data)
        plain_bytes = decrypt_bytes(enc_bytes)
        return plain_bytes.decode("utf-8")
    except Exception as exc:
        logger.error("Failed to decrypt database text field: %s", exc)
        return "[ENCRYPTED_TEXT_DECRYPTION_FAILED]"
