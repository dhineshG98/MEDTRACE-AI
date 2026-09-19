"""AuditLog ORM model.

Records all access, decryption, processing, and modification events
for Protected Health Information (PHI) to satisfy HIPAA §164.312(b) Audit Controls.
"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base
from app.models.document import GUID, _utcnow


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, nullable=False, index=True)

    action: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    # Actions: DOCUMENT_UPLOAD, DOCUMENT_PROCESS, DOCUMENT_VIEW_CONTENT,
    #          DOCUMENT_DOWNLOAD, TIMELINE_VIEW, DOCUMENT_DELETE, COPILOT_QUERY, EXPORT_REDACTED

    document_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), nullable=True, index=True)
    document_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    client_ip: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)

    status: Mapped[str] = mapped_column(String(32), nullable=False, default="SUCCESS")
    details: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    def to_dict(self) -> dict:
        return {
            "id": str(self.id),
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "action": self.action,
            "document_id": str(self.document_id) if self.document_id else None,
            "document_name": self.document_name,
            "client_ip": self.client_ip,
            "user_agent": self.user_agent,
            "status": self.status,
            "details": self.details,
        }

    def __repr__(self) -> str:
        return f"<AuditLog {self.action} doc={self.document_id} status={self.status} at {self.timestamp}>"
