"""Document ORM model.

`raw_text` is kept on the document row; structured extraction lands in its own
table in Phase 4, so re-running AI never risks the source text.
"""

import enum
import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import CHAR, TypeDecorator

from app.database.database import Base


class GUID(TypeDecorator):
    """UUID column that works on both PostgreSQL and SQLite."""

    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            from sqlalchemy.dialects.postgresql import UUID as PGUUID

            return dialect.type_descriptor(PGUUID(as_uuid=True))
        return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        if dialect.name == "postgresql":
            return value
        return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        return value if isinstance(value, uuid.UUID) else uuid.UUID(str(value))


class EncryptedText(TypeDecorator):
    """AES-256-GCM encrypted text column.

    Transparently encrypts sensitive clinical text before persisting to disk
    and decrypts upon retrieval. Falls back to plaintext for legacy unencrypted data.
    """

    impl = Text
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        from app.services.encryption_service import encrypt_text
        return encrypt_text(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        from app.services.encryption_service import decrypt_text
        return decrypt_text(value)


class DocumentStatus(str, enum.Enum):
    UPLOADED = "uploaded"
    PROCESSING = "processing"
    EXTRACTED = "extracted"   # text read; AI extraction pending (Phase 3)
    COMPLETED = "completed"
    FAILED = "failed"


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)

    # Sanitized original name, for display only. Never used as a disk path.
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    stored_path: Mapped[str] = mapped_column(String(512), nullable=False)
    file_type: Mapped[str] = mapped_column(String(16), nullable=False)
    mime_type: Mapped[str] = mapped_column(String(128), nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False)
    content_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)

    status: Mapped[DocumentStatus] = mapped_column(
        Enum(DocumentStatus, native_enum=False, length=20),
        default=DocumentStatus.UPLOADED,
        nullable=False,
        index=True,
    )
    error_code: Mapped[str | None] = mapped_column(String(64), nullable=True)
    error_message: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # --- extraction output (encrypted at rest) ---
    raw_text: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)
    extraction_method: Mapped[str | None] = mapped_column(String(32), nullable=True)
    page_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    char_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    word_count: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # --- filled in Phase 3/4 (encrypted at rest) ---
    document_type: Mapped[str | None] = mapped_column(String(64), nullable=True)
    quality_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    structured_entities: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, nullable=False)
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    def __repr__(self) -> str:
        return f"<Document {self.id} {self.filename} {self.status.value}>"
