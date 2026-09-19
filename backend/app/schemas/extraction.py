"""Strict Pydantic output schemas for Phase 3 AI extraction."""

from typing import Optional, Union
from pydantic import BaseModel, Field


class DocumentTypeEntity(BaseModel):
    value: str
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)


class PatientEntity(BaseModel):
    name: Optional[str] = None
    age: Optional[Union[int, str]] = None
    gender: Optional[str] = None
    patient_id: Optional[str] = None


class ConditionEntity(BaseModel):
    value: str
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)
    source_text: Optional[str] = None


class MedicationEntity(BaseModel):
    name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    route: Optional[str] = None
    duration: Optional[str] = None
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)
    source_text: Optional[str] = None


class AllergyEntity(BaseModel):
    allergen: str
    reaction: Optional[str] = None
    negated: bool = False
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)
    source_text: Optional[str] = None


class LabResultEntity(BaseModel):
    test_name: str
    value: str
    unit: Optional[str] = None
    reference_range: Optional[str] = None
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)


class DateEntity(BaseModel):
    type: str
    value: str
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)


class DoctorEntity(BaseModel):
    name: str
    specialty: Optional[str] = None
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)


class RelationshipEntity(BaseModel):
    source: str
    relationship: str  # "treats", "has_dosage", "has_frequency", "prescribed_for"
    target: str
    confidence: float = Field(default=0.90, ge=0.0, le=1.0)


class StructuredMedicalRecord(BaseModel):
    """Exact Phase 3 validated medical extraction record."""
    document_type: DocumentTypeEntity
    patient: Optional[PatientEntity] = Field(default_factory=PatientEntity)
    conditions: list[ConditionEntity] = Field(default_factory=list)
    medications: list[MedicationEntity] = Field(default_factory=list)
    allergies: list[AllergyEntity] = Field(default_factory=list)
    lab_results: list[LabResultEntity] = Field(default_factory=list)
    dates: list[DateEntity] = Field(default_factory=list)
    doctors: list[DoctorEntity] = Field(default_factory=list)
    relationships: list[RelationshipEntity] = Field(default_factory=list)
