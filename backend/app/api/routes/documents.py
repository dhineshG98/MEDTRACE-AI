"""Document endpoints: upload, process, list, fetch, delete."""

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, File, HTTPException, Query, Request, Response, UploadFile, status
from sqlalchemy import func, select

from app.api.dependencies import DbSession
from app.config.settings import settings
from app.models.document import Document, DocumentStatus
from app.models.extraction import Extraction
from app.models.audit_log import AuditLog
from app.schemas.document import (
    AllergyItem,
    ClinicalAnalysisResponse,
    ClinicalEntities,
    ConditionItem,
    CopilotChatRequest,
    CopilotChatResponse,
    DateItem,
    DeleteResponse,
    DocumentDetail,
    DocumentListResponse,
    DocumentSummary,
    LabResultItem,
    MedicationItem,
    PatientInfo,
    PatientTimelineResponse,
    StructuredExtractionResponse,
    TextExtractionResponse,
    UploadResponse,
)
from app.services import ai_service, audit_service, document_service, extraction_service, phi_sanitizer
from app.utils import file_utils
from app.utils.file_utils import FileValidationError
from app.utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/documents", tags=["documents"])


def _get_or_404(db: DbSession, document_id: uuid.UUID) -> Document:
    document = db.get(Document, document_id)
    if document is None:
        raise HTTPException(status_code=404, detail="Document not found.")
    return document


@router.post(
    "/upload",
    response_model=UploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a medical document",
)
async def upload_document(
    db: DbSession,
    file: UploadFile = File(...),
    request: Request = None,
) -> UploadResponse:
    """Validate and store an uploaded document.

    Upload only -- no text extraction happens here, so the client gets a fast
    response and can show its own progress state. Call the process endpoint next.
    """
    try:
        ext = file_utils.validate_extension(file.filename)
        content = await file.read()
        file_utils.validate_size(len(content))
        file_utils.validate_magic_bytes(content, ext)
    except FileValidationError as exc:
        raise HTTPException(status_code=400, detail=exc.message) from exc
    finally:
        await file.close()

    digest = file_utils.content_hash(content)
    existing = db.scalar(select(Document).where(Document.content_hash == digest))

    document_id = uuid.uuid4()
    stored_path = file_utils.save_upload(content, document_id, ext)

    document = Document(
        id=document_id,
        filename=file_utils.sanitize_filename(file.filename),
        stored_path=str(stored_path),
        file_type=ext,
        mime_type=file_utils.mime_for_extension(ext),
        file_size=len(content),
        content_hash=digest,
        status=DocumentStatus.UPLOADED,
    )
    db.add(document)
    db.commit()
    db.refresh(document)

    audit_service.record_audit_event(
        db,
        action="DOCUMENT_UPLOAD",
        document_id=document.id,
        document_name=document.filename,
        details=f"Stored AES-256-GCM encrypted ({len(content)} bytes, {ext})",
        request=request,
    )

    return UploadResponse(
        document_id=document.id,
        filename=document.filename,
        file_type=document.file_type,
        file_size=document.file_size,
        status=document.status,
        duplicate_of=existing.id if existing else None,
    )


@router.post(
    "/upload-batch",
    response_model=list[UploadResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Upload multiple medical documents simultaneously",
)
async def upload_documents_batch(
    db: DbSession,
    files: list[UploadFile] = File(...),
    request: Request = None,
) -> list[UploadResponse]:
    """Validate and store multiple uploaded documents.

    Each document is individually validated, encrypted with AES-256-GCM,
    persisted to disk, and recorded with an audit event.
    """
    if not files:
        raise HTTPException(status_code=400, detail="No files provided for batch upload.")

    responses: list[UploadResponse] = []

    for file in files:
        try:
            ext = file_utils.validate_extension(file.filename)
            content = await file.read()
            file_utils.validate_size(len(content))
            file_utils.validate_magic_bytes(content, ext)
        except FileValidationError as exc:
            raise HTTPException(
                status_code=400,
                detail=f"Validation failed for '{file.filename}': {exc.message}",
            ) from exc
        finally:
            await file.close()

        digest = file_utils.content_hash(content)
        existing = db.scalar(select(Document).where(Document.content_hash == digest))

        document_id = uuid.uuid4()
        stored_path = file_utils.save_upload(content, document_id, ext)

        document = Document(
            id=document_id,
            filename=file_utils.sanitize_filename(file.filename),
            stored_path=str(stored_path),
            file_type=ext,
            mime_type=file_utils.mime_for_extension(ext),
            file_size=len(content),
            content_hash=digest,
            status=DocumentStatus.UPLOADED,
        )
        db.add(document)
        db.commit()
        db.refresh(document)

        audit_service.record_audit_event(
            db,
            action="DOCUMENT_UPLOAD",
            document_id=document.id,
            document_name=document.filename,
            details=f"Batch upload: Stored AES-256-GCM encrypted ({len(content)} bytes, {ext})",
            request=request,
        )

        responses.append(
            UploadResponse(
                document_id=document.id,
                filename=document.filename,
                file_type=document.file_type,
                file_size=document.file_size,
                status=document.status,
                duplicate_of=existing.id if existing else None,
            )
        )

    return responses


@router.post(
    "/{document_id}/process",
    response_model=TextExtractionResponse,
    summary="Extract text from an uploaded document",
)
async def process_document(
    db: DbSession,
    document_id: uuid.UUID,
    request: Request = None,
) -> TextExtractionResponse:
    """Run text extraction, with OCR fallback for scanned documents.

    On failure the document and its file are preserved and the status is set
    to `failed` with a safe error message -- nothing is discarded.
    """
    document = _get_or_404(db, document_id)

    path = Path(document.stored_path)
    if not path.exists():
        document.status = DocumentStatus.FAILED
        document.error_code = "file_missing"
        document.error_message = "The stored file could not be found on the server."
        db.commit()
        audit_service.record_audit_event(
            db,
            action="DOCUMENT_PROCESS",
            document_id=document.id,
            document_name=document.filename,
            status="FAILURE",
            details="File missing from storage",
            request=request,
        )
        raise HTTPException(status_code=410, detail=document.error_message)

    document.status = DocumentStatus.PROCESSING
    document.error_code = None
    document.error_message = None
    db.commit()

    try:
        result = document_service.extract_text(path, document.file_type)
    except document_service.ExtractionError as exc:
        document.status = DocumentStatus.FAILED
        document.error_code = exc.code
        document.error_message = exc.message
        document.processed_at = datetime.now(timezone.utc)
        db.commit()

        audit_service.record_audit_event(
            db,
            action="DOCUMENT_PROCESS",
            document_id=document.id,
            document_name=document.filename,
            status="FAILURE",
            details=f"Extraction failed: {exc.code} - {exc.message}",
            request=request,
        )

        # OCR/PDF support missing is a server capability problem -> 503.
        # A bad or unreadable file is the client's -> 422.
        http_status = 503 if exc.code.endswith("_unavailable") else 422
        raise HTTPException(status_code=http_status, detail=exc.message) from exc

    document.raw_text = result.text
    document.extraction_method = result.extraction_method
    document.page_count = result.page_count
    document.char_count = result.char_count
    document.word_count = result.word_count
    document.status = DocumentStatus.EXTRACTED
    document.processed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(document)

    audit_service.record_audit_event(
        db,
        action="DOCUMENT_PROCESS",
        document_id=document.id,
        document_name=document.filename,
        status="SUCCESS",
        details=f"Extracted {result.word_count} words via {result.extraction_method}",
        request=request,
    )

    return TextExtractionResponse(
        document_id=document.id,
        status=document.status,
        text=result.text,
        extraction_method=result.extraction_method,
        page_count=result.page_count,
        ocr_pages=result.ocr_pages,
        char_count=result.char_count,
        word_count=result.word_count,
        warnings=result.warnings,
    )


@router.get("", response_model=DocumentListResponse, summary="List documents")
async def list_documents(
    db: DbSession,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    status_filter: Optional[DocumentStatus] = Query(default=None, alias="status"),
) -> DocumentListResponse:
    """Newest first. Powers the dashboard's recent activity feed."""
    query = select(Document)
    count_query = select(func.count()).select_from(Document)

    if status_filter is not None:
        query = query.where(Document.status == status_filter)
        count_query = count_query.where(Document.status == status_filter)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(Document.created_at.desc()).limit(limit).offset(offset)
    ).all()

    return DocumentListResponse(
        total=total,
        limit=limit,
        offset=offset,
        documents=[DocumentSummary.model_validate(row) for row in rows],
    )


@router.get(
    "/timeline",
    response_model=PatientTimelineResponse,
    summary="Get synthesized longitudinal patient timeline",
)
async def get_patient_timeline(db: DbSession, request: Request = None) -> PatientTimelineResponse:
    """Aggregates all ingested documents and generates a chronological patient timeline."""
    docs_query = select(Document).order_by(Document.created_at.asc())
    documents = db.scalars(docs_query).all()
    res = ai_service.synthesize_patient_timeline(list(documents))
    audit_service.record_audit_event(
        db,
        action="TIMELINE_VIEW",
        details=f"Synthesized timeline for {len(documents)} clinical events",
        request=request,
    )
    return res


@router.get("/{document_id}", response_model=DocumentDetail, summary="Get one document")
async def get_document(db: DbSession, document_id: uuid.UUID) -> DocumentDetail:
    doc = _get_or_404(db, document_id)
    detail = DocumentDetail.model_validate(doc)
    if doc.structured_entities:
        try:
            detail.clinical_analysis = ClinicalEntities.model_validate_json(doc.structured_entities)
        except Exception:
            pass
    return detail


@router.get(
    "/{document_id}/content",
    summary="Securely view or download the decrypted original medical document",
)
async def get_document_content(
    db: DbSession,
    document_id: uuid.UUID,
    download: bool = Query(default=False, description="If true, trigger download attachment; otherwise view inline"),
    request: Request = None,
) -> Response:
    """Decrypts the stored AES-256-GCM file in memory and streams it to authorized users.

    Security rules enforced:
      - Plaintext is never permanently written to disk
      - Content-Disposition matches requested view/download action
      - Content-Type is locked to the original validated MIME type
      - Tampered or corrupted files are rejected before returning
    """
    doc = _get_or_404(db, document_id)
    path = Path(doc.stored_path)

    if not path.exists():
        raise HTTPException(status_code=410, detail="Document file is missing from storage.")

    try:
        if path.suffix == ".enc":
            from app.services import encryption_service
            content = encryption_service.decrypt_file(path)
        else:
            content = path.read_bytes()
    except Exception as exc:
        logger.error("Failed to decrypt document %s: %s", document_id, exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to authenticate and decrypt stored medical document.",
        ) from exc

    disposition = "attachment" if download else "inline"
    safe_filename = doc.filename.replace('"', '\\"')

    audit_service.record_audit_event(
        db,
        action="DOCUMENT_DOWNLOAD" if download else "DOCUMENT_VIEW_CONTENT",
        document_id=doc.id,
        document_name=doc.filename,
        details=f"Decrypted original in memory ({len(content)} bytes, {doc.mime_type})",
        request=request,
    )

    return Response(
        content=content,
        media_type=doc.mime_type or "application/octet-stream",
        headers={
            "Content-Disposition": f'{disposition}; filename="{safe_filename}"',
            "Cache-Control": "no-store, no-cache, must-revalidate, private",
            "X-Content-Type-Options": "nosniff",
        },
    )


def _build_extraction_response(extraction: Extraction) -> StructuredExtractionResponse:
    return StructuredExtractionResponse(
        id=extraction.id,
        document_id=extraction.document_id,
        document_type=extraction.document_type,
        document_type_confidence=extraction.document_type_confidence,
        patient=PatientInfo.model_validate(extraction.get_patient_info()),
        conditions=[ConditionItem.model_validate(c) for c in extraction.get_conditions()],
        medications=[MedicationItem.model_validate(m) for m in extraction.get_medications()],
        allergies=[AllergyItem.model_validate(a) for a in extraction.get_allergies()],
        lab_results=[LabResultItem.model_validate(l) for l in extraction.get_lab_results()],
        dates=[DateItem.model_validate(d) for d in extraction.get_dates()],
        doctors=extraction.get_doctors(),
        quality_score=extraction.quality_score,
        requires_review=extraction.requires_review,
        review_reasons=extraction.get_review_reasons(),
        summary=extraction.summary,
        provider_used=extraction.provider_used,
        created_at=extraction.created_at,
    )


@router.post(
    "/{document_id}/extract",
    response_model=StructuredExtractionResponse,
    summary="Extract structured clinical entities with negation, normalization, and confidence",
)
async def extract_document(db: DbSession, document_id: uuid.UUID) -> StructuredExtractionResponse:
    """Runs clinical NLP extraction, negation, normalization, relationships, confidence, and quality scoring."""
    document = _get_or_404(db, document_id)
    if not document.raw_text:
        raise HTTPException(
            status_code=400,
            detail="Document has no extracted text. Call /process first before extraction.",
        )

    pipeline_result = extraction_service.run_clinical_extraction_pipeline(
        raw_text=document.raw_text,
        extraction_method=document.extraction_method or "pdf_text",
    )

    # Upsert extraction record
    extraction = db.scalar(select(Extraction).where(Extraction.document_id == document_id))
    if not extraction:
        extraction = Extraction(
            id=uuid.uuid4(),
            document_id=document_id,
        )
        db.add(extraction)

    extraction.document_type = pipeline_result["document_type"]
    extraction.document_type_confidence = pipeline_result["document_type_confidence"]
    extraction.patient_info = json.dumps(pipeline_result["patient"])
    extraction.conditions = json.dumps(pipeline_result["conditions"])
    extraction.medications = json.dumps(pipeline_result["medications"])
    extraction.allergies = json.dumps(pipeline_result["allergies"])
    extraction.lab_results = json.dumps(pipeline_result["lab_results"])
    extraction.dates = json.dumps(pipeline_result["dates"])
    extraction.doctors = json.dumps(pipeline_result["doctors"])
    extraction.quality_score = pipeline_result["quality_score"]
    extraction.requires_review = pipeline_result["requires_review"]
    extraction.review_reasons = json.dumps(pipeline_result["review_reasons"])
    extraction.summary = pipeline_result["summary"]
    extraction.provider_used = pipeline_result["provider_used"]

    # Update document status and summary attributes
    document.document_type = pipeline_result["document_type"]
    document.quality_score = pipeline_result["quality_score"]
    document.structured_entities = json.dumps(pipeline_result)
    document.status = DocumentStatus.COMPLETED
    document.processed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(extraction)
    db.refresh(document)

    return _build_extraction_response(extraction)


@router.get(
    "/{document_id}/extraction",
    response_model=StructuredExtractionResponse,
    summary="Get structured clinical extraction for a document",
)
async def get_extraction(db: DbSession, document_id: uuid.UUID) -> StructuredExtractionResponse:
    """Returns the full structured extraction for the specified document."""
    _get_or_404(db, document_id)
    extraction = db.scalar(select(Extraction).where(Extraction.document_id == document_id))
    if not extraction:
        raise HTTPException(
            status_code=404,
            detail="No structured extraction found for this document. Call /extract first.",
        )
    return _build_extraction_response(extraction)


@router.post(
    "/{document_id}/analyze",
    response_model=ClinicalAnalysisResponse,
    summary="Run AI clinical classification and entity extraction",
)
async def analyze_document(db: DbSession, document_id: uuid.UUID) -> ClinicalAnalysisResponse:
    """Classifies the medical document, extracts entities, and computes quality score."""
    document = _get_or_404(db, document_id)
    if not document.raw_text:
        raise HTTPException(
            status_code=400,
            detail="Document has no extracted text. Run /process first before clinical AI analysis.",
        )

    # Use the unified extraction pipeline
    pipeline_result = extraction_service.run_clinical_extraction_pipeline(
        raw_text=document.raw_text,
        extraction_method=document.extraction_method or "pdf_text",
    )

    # Upsert extraction record
    extraction = db.scalar(select(Extraction).where(Extraction.document_id == document_id))
    if not extraction:
        extraction = Extraction(
            id=uuid.uuid4(),
            document_id=document_id,
        )
        db.add(extraction)

    extraction.document_type = pipeline_result["document_type"]
    extraction.document_type_confidence = pipeline_result["document_type_confidence"]
    extraction.patient_info = json.dumps(pipeline_result["patient"])
    extraction.conditions = json.dumps(pipeline_result["conditions"])
    extraction.medications = json.dumps(pipeline_result["medications"])
    extraction.allergies = json.dumps(pipeline_result["allergies"])
    extraction.lab_results = json.dumps(pipeline_result["lab_results"])
    extraction.dates = json.dumps(pipeline_result["dates"])
    extraction.doctors = json.dumps(pipeline_result["doctors"])
    extraction.quality_score = pipeline_result["quality_score"]
    extraction.requires_review = pipeline_result["requires_review"]
    extraction.review_reasons = json.dumps(pipeline_result["review_reasons"])
    extraction.summary = pipeline_result["summary"]
    extraction.provider_used = pipeline_result["provider_used"]

    document.document_type = pipeline_result["document_type"]
    document.quality_score = pipeline_result["quality_score"]
    document.structured_entities = json.dumps(pipeline_result)
    document.status = DocumentStatus.COMPLETED
    document.processed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(extraction)
    db.refresh(document)

    clinical_entities = ClinicalEntities(
        document_type=pipeline_result["document_type"],
        quality_score=pipeline_result["quality_score"],
        summary=pipeline_result.get("summary") or "",
        diagnoses=[c["name"] for c in pipeline_result.get("conditions", []) if not c.get("is_negated")],
        medications=[
            MedicationEntity(
                name=m["canonical_name"] or m["name"],
                dosage=m.get("dosage"),
                frequency=m.get("frequency"),
                route=m.get("route"),
            )
            for m in pipeline_result.get("medications", [])
        ],
        vital_signs={},
        critical_flags=pipeline_result.get("review_reasons", []),
        patient_info=pipeline_result.get("patient", {}),
    )

    return ClinicalAnalysisResponse(
        document_id=document.id,
        status=document.status,
        document_type=document.document_type,
        quality_score=document.quality_score or 50,
        entities=clinical_entities,
        provider_used=pipeline_result["provider_used"],
    )


@router.post(
    "/copilot",
    response_model=CopilotChatResponse,
    summary="Ask the MedTrace AI clinical copilot",
)
async def copilot_chat(
    db: DbSession,
    req: CopilotChatRequest,
    request: Request = None,
) -> CopilotChatResponse:
    """Answers clinical questions grounded in the user's ingested documents."""
    docs_query = select(Document)
    if req.document_id:
        docs_query = docs_query.where(Document.id == req.document_id)
    else:
        docs_query = docs_query.order_by(Document.created_at.desc()).limit(10)

    documents = db.scalars(docs_query).all()
    response_text, sources, tags, snippet = ai_service.answer_copilot_query(
        req.query, list(documents)
    )

    audit_service.record_audit_event(
        db,
        action="COPILOT_QUERY",
        document_id=req.document_id,
        details=f"Copilot answered query: {req.query[:100]}",
        request=request,
    )

    return CopilotChatResponse(
        query=req.query,
        response=response_text,
        source_documents=sources,
        tags=tags,
        code_snippet=snippet,
    )


@router.delete("/{document_id}", response_model=DeleteResponse, summary="Delete a document")
async def delete_document(
    db: DbSession,
    document_id: uuid.UUID,
    request: Request = None,
) -> DeleteResponse:
    """Removes the database row and cryptographically shreds the stored file."""
    document = _get_or_404(db, document_id)
    doc_name = document.filename
    file_removed = file_utils.delete_stored_file(document.stored_path)

    db.delete(document)
    db.commit()

    audit_service.record_audit_event(
        db,
        action="DOCUMENT_DELETE",
        document_id=document_id,
        document_name=doc_name,
        details=f"Cryptographically shredded file: {file_removed}",
        request=request,
    )

    logger.info("Deleted document %s (file shredded: %s)", document_id, file_removed)
    return DeleteResponse(document_id=document_id, deleted=True, file_removed=file_removed)


@router.get(
    "/{document_id}/redacted",
    summary="Get Safe Harbor de-identified clinical text and entities",
)
async def get_redacted_document(
    db: DbSession,
    document_id: uuid.UUID,
    request: Request = None,
) -> dict:
    """Returns de-identified clinical text and structured entities conforming to HIPAA Safe Harbor."""
    doc = _get_or_404(db, document_id)
    raw_text = doc.raw_text or ""
    sanitized_text = phi_sanitizer.sanitize_text(raw_text)

    entities_dict = {}
    if doc.structured_entities:
        try:
            entities_dict = json.loads(doc.structured_entities)
        except Exception:
            pass
    sanitized_ent = phi_sanitizer.sanitize_entities(entities_dict)

    audit_service.record_audit_event(
        db,
        action="EXPORT_REDACTED",
        document_id=doc.id,
        document_name=doc.filename,
        details="Generated HIPAA Safe Harbor de-identified clinical view",
        request=request,
    )

    return {
        "document_id": str(doc.id),
        "filename": doc.filename,
        "is_deidentified": True,
        "redacted_text": sanitized_text,
        "sanitized_entities": sanitized_ent,
    }


@router.get(
    "/audit-logs/recent",
    summary="Retrieve HIPAA compliance audit access logs",
)
async def get_audit_logs(
    db: DbSession,
    limit: int = Query(default=50, ge=1, le=500),
    action: Optional[str] = Query(default=None),
) -> list[dict]:
    """Returns immutable audit logs tracking all PHI data access and cryptographic operations."""
    stmt = select(AuditLog).order_by(AuditLog.timestamp.desc()).limit(limit)
    if action:
        stmt = stmt.where(AuditLog.action == action)
    logs = db.scalars(stmt).all()
    return [log.to_dict() for log in logs]
