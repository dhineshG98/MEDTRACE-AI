"""Centralized logging configuration."""

import logging
import sys


def configure_logging(level: int = logging.INFO) -> None:
    """Configure structured console logging for the application."""
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
        force=True,
    )


def get_logger(name: str) -> logging.Logger:
    """Return a configured logger for the given module name."""
    return logging.getLogger(name)


def safe_preview(text: str | None, max_len: int = 80) -> str:
    """Sanitize and truncate text preview to avoid logging raw medical content."""
    if not text:
        return "[empty]"
    preview = " ".join(text.split())
    if len(preview) <= max_len:
        return preview
    return f"{preview[:max_len]}..."
