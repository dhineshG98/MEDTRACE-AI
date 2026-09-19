"""HIPAA Access & Audit Logging Service.

Provides centralized functions to log data access, decryption,
and modification events across the MedTrace AI platform.
"""

import uuid
from typing import Optional
from fastapi import Request
from sqlalchemy.orm import Session

from app.models.audit_log import AuditLog
from app.utils.logger import get_logger

logger = get_logger(__name__)


def extract_client_info(request: Optional[Request]) -> tuple[Optional[str], Optional[str]]:
    """Extracts client IP and User-Agent from a FastAPI request."""
    if not request:
        return None, None

    client_ip = request.headers.get("X-Forwarded-For")
    if client_ip:
        client_ip = client_ip.split(",")[0].strip()
    elif request.client:
        client_ip = request.client.host

    user_agent = request.headers.get("User-Agent")
    if user_agent and len(user_agent) > 500:
        user_agent = user_agent[:500]

    return client_ip, user_agent


def record_audit_event(
    db: Session,
    action: str,
    document_id: Optional[uuid.UUID] = None,
    document_name: Optional[str] = None,
    status: str = "SUCCESS",
    details: Optional[str] = None,
    request: Optional[Request] = None,
) -> Optional[AuditLog]:
    """Records an audit event into the database.

    Gracefully catches and logs errors so audit failures never interrupt
    clinical workflows.
    """
    try:
        client_ip, user_agent = extract_client_info(request)
        log_entry = AuditLog(
            action=action,
            document_id=document_id,
            document_name=document_name,
            client_ip=client_ip,
            user_agent=user_agent,
            status=status,
            details=details,
        )
        db.add(log_entry)
        db.commit()
        db.refresh(log_entry)
        logger.info(
            "AUDIT [%s] doc=%s name='%s' status=%s ip=%s",
            action,
            document_id,
            document_name,
            status,
            client_ip,
        )
        return log_entry
    except Exception as exc:
        logger.error("Failed to write audit log for action %s: %s", action, exc)
        try:
            db.rollback()
        except Exception:
            pass
        return None
