"""Document API schemas.

These are the exact shapes the Flutter client receives.
"""

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.document import DocumentStatus


class UploadResponse(BaseModel):
    """Returned immediately after a successful upload."""

    document_id: uuid.UUID
    filename: str
    file_type: str
    file_size: int
    status: DocumentStatus
    duplicate_of: Optional[uuid.UUID] = Field(
        default=None,
        description="Set when an identical file was already uploaded.",
    )


class DocumentSummary(BaseModel):
    """List-view row. Drives the dashboard's recent activity feed.

    Excludes raw_text deliberately -- the list endpoint must never ship
    full medical text to the client.
    """

    model_config = ConfigDict(from_attributes=True)

    document_id: uuid.UUID = Field(validation_alias="id")
    filename: str
    file_type: str
    file_size: int
    status: DocumentStatus
    document_type: Optional[str] = None
    quality_score: Optional[int] = None
    extraction_method: Optional[str] = None
    page_count: Optional[int] = None
    word_count: Optional[int] = None
    created_at: datetime
    processed_at: Optional[datetime] = None
    error_message: Optional[str] = None


class MedicationEntity(BaseModel):
    name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    route: Optional[str] = None


class ClinicalEntities(BaseModel):
    document_type: str = "Unknown Medical Document"
    quality_score: int = 50
    summary: str = ""
    diagnoses: list[str] = Field(default_factory=list)
    medications: list[MedicationEntity] = Field(default_factory=list)
    vital_signs: dict[str, str] = Field(default_factory=dict)
    critical_flags: list[str] = Field(default_factory=list)
    patient_info: dict[str, Optional[str]] = Field(default_factory=dict)


class DocumentDetail(DocumentSummary):
    """Detail view. Includes the extracted text and structured clinical analysis."""

    raw_text: Optional[str] = None
    char_count: Optional[int] = None
    clinical_analysis: Optional[ClinicalEntities] = None


class ClinicalAnalysisResponse(BaseModel):
    """Phase 3 AI classification and entity extraction result."""

    document_id: uuid.UUID
    status: DocumentStatus
    document_type: str
    quality_score: int
    entities: ClinicalEntities
    provider_used: str


class CopilotChatRequest(BaseModel):
    query: str
    document_id: Optional[uuid.UUID] = None


class CopilotChatResponse(BaseModel):
    query: str
    response: str
    source_documents: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    code_snippet: Optional[str] = None


class DocumentListResponse(BaseModel):
    total: int
    limit: int
    offset: int
    documents: list[DocumentSummary]


class TextExtractionResponse(BaseModel):
    """Phase 2 processing result."""

    document_id: uuid.UUID
    status: DocumentStatus
    text: str
    extraction_method: str = Field(
        description="pdf_text | ocr | docx | image_ocr",
        examples=["pdf_text"],
    )
    page_count: Optional[int] = None
    ocr_pages: Optional[int] = None
    char_count: int
    word_count: int
    warnings: list[str] = Field(default_factory=list)


class DeleteResponse(BaseModel):
    document_id: uuid.UUID
    deleted: bool
    file_removed: bool


class TimelineEvent(BaseModel):
    id: str
    date: str
    raw_date: str
    category: str
    icon: str
    title: str
    items: list[str] = Field(default_factory=list)
    document_id: str
    document_name: str
    summary: Optional[str] = None


class PatientTimelineResponse(BaseModel):
    patient_name: Optional[str] = "Patient Record"
    total_events: int = 0
    events: list[TimelineEvent] = Field(default_factory=list)
    ascii_tree: str = ""


class PatientInfo(BaseModel):
    name: Optional[str] = None
    age_or_dob: Optional[str] = None
    gender: Optional[str] = None
    mrn: Optional[str] = None
    date: Optional[str] = None


class ConditionItem(BaseModel):
    name: str
    icd10: Optional[str] = None
    is_negated: bool = False
    confidence: float = 0.90
    tier: str = "High"


class MedicationItem(BaseModel):
    name: str
    canonical_name: Optional[str] = None
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    route: Optional[str] = None
    treats: Optional[str] = None
    confidence: float = 0.90
    tier: str = "High"


class AllergyItem(BaseModel):
    name: str
    is_negated: bool = False
    confidence: float = 0.90
    tier: str = "High"


class LabResultItem(BaseModel):
    test_name: str
    value: str
    unit: Optional[str] = None
    reference_range: Optional[str] = None
    flag: Optional[str] = None
    date: Optional[str] = None
    confidence: float = 0.90
    tier: str = "High"


class DateItem(BaseModel):
    date: str
    type: str = "Encounter"


class StructuredExtractionResponse(BaseModel):
    id: uuid.UUID
    document_id: uuid.UUID
    document_type: str
    document_type_confidence: float = 0.90
    patient: PatientInfo = Field(default_factory=PatientInfo)
    conditions: list[ConditionItem] = Field(default_factory=list)
    medications: list[MedicationItem] = Field(default_factory=list)
    allergies: list[AllergyItem] = Field(default_factory=list)
    lab_results: list[LabResultItem] = Field(default_factory=list)
    dates: list[DateItem] = Field(default_factory=list)
    doctors: list[str] = Field(default_factory=list)
    quality_score: int = 50
    requires_review: bool = False
    review_reasons: list[str] = Field(default_factory=list)
    summary: Optional[str] = None
    provider_used: str = "heuristic"
    created_at: datetime

