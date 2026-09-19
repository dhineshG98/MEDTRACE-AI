"""Database schema initialization."""

from app.database.database import Base, engine
import app.models.document  # noqa: F401 - ensure Document table is registered
import app.models.extraction  # noqa: F401 - ensure Extraction table is registered
import app.models.audit_log  # noqa: F401 - ensure AuditLog table is registered


def init_db() -> None:
    """Create database tables if they do not already exist."""
    Base.metadata.create_all(bind=engine)
