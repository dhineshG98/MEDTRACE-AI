"""Health and system response schemas."""

from typing import Optional
from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    service: str


class ComponentStatus(BaseModel):
    name: str
    available: bool
    detail: Optional[str] = None


class DetailedHealthResponse(BaseModel):
    status: str
    service: str
    version: str
    environment: str
    components: list[ComponentStatus]
