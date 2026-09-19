"""Extraction ORM model.

Stores structured clinical entity extractions, per-field confidence scores,
normalized ontologies, relationships, and review flags.
"""

import json
import uuid
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base
from app.models.document import GUID, EncryptedText, _utcnow


class Extraction(Base):
    __tablename__ = "extractions"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    document_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("documents.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )

    document_type: Mapped[str] = mapped_column(String(128), nullable=False, default="Clinical Medical Document")
    document_type_confidence: Mapped[float] = mapped_column(Float, nullable=False, default=0.90)

    # Structured JSON stored as EncryptedText (AES-256-GCM encrypted at rest for PHI security)
    patient_info: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="{}")
    conditions: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")
    medications: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")
    allergies: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")
    lab_results: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")
    dates: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")
    doctors: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")

    quality_score: Mapped[int] = mapped_column(Integer, nullable=False, default=50)
    requires_review: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    review_reasons: Mapped[str] = mapped_column(EncryptedText, nullable=False, default="[]")
    summary: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)
    provider_used: Mapped[str] = mapped_column(String(64), nullable=False, default="heuristic")

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, nullable=False)

    def get_patient_info(self) -> dict[str, Any]:
        try:
            return json.loads(self.patient_info)
        except Exception:
            return {}

    def get_conditions(self) -> list[dict[str, Any]]:
        try:
            return json.loads(self.conditions)
        except Exception:
            return []

    def get_medications(self) -> list[dict[str, Any]]:
        try:
            return json.loads(self.medications)
        except Exception:
            return []

    def get_allergies(self) -> list[dict[str, Any]]:
        try:
            return json.loads(self.allergies)
        except Exception:
            return []

    def get_lab_results(self) -> list[dict[str, Any]]:
        try:
            return json.loads(self.lab_results)
        except Exception:
            return []

    def get_dates(self) -> list[dict[str, Any]]:
        try:
            return json.loads(self.dates)
        except Exception:
            return []

    def get_doctors(self) -> list[str]:
        try:
            return json.loads(self.doctors)
        except Exception:
            return []

    def get_review_reasons(self) -> list[str]:
        try:
            return json.loads(self.review_reasons)
        except Exception:
            return []

    def __repr__(self) -> str:
        return f"<Extraction {self.id} doc={self.document_id} type={self.document_type} review={self.requires_review}>"
