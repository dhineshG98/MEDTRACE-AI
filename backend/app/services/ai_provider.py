"""Provider-agnostic AI abstraction for Phase 3 structured extraction.

Architecture:
  AIProvider (ABC)
    ├── GeminiProvider   — Google Gemini (primary, with tenacity retry)
    ├── ClaudeProvider   — Anthropic Claude (stub)
    ├── OpenAIProvider   — OpenAI GPT (stub)
    └── HeuristicProvider — Offline fallback (no API key needed)

Factory:
  get_ai_provider() reads settings.AI_PROVIDER and returns the correct instance.
  Falls back to HeuristicProvider when no API key is configured.
"""

import json
import logging
import re
import urllib.error
import urllib.request
from abc import ABC, abstractmethod
from typing import Any, Optional

from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
    before_sleep_log,
)

from app.config.settings import settings
from app.services.prompts import SYSTEM_PROMPT, CORRECTION_PROMPT, build_user_prompt

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Retry decorator — shared by all cloud providers
# ---------------------------------------------------------------------------
_RETRYABLE = (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, ConnectionError)


def _make_retry():
    return retry(
        retry=retry_if_exception_type(_RETRYABLE),
        stop=stop_after_attempt(settings.AI_MAX_RETRIES),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True,
    )


# ---------------------------------------------------------------------------
# Abstract base
# ---------------------------------------------------------------------------
class AIProvider(ABC):
    """Abstract interface every AI provider must implement."""

    @abstractmethod
    def extract(self, raw_text: str) -> dict[str, Any]:
        """Extract a structured medical record from raw_text.

        Returns a plain dict matching the StructuredMedicalRecord schema.
        Raises RuntimeError on unrecoverable failure so callers can log and
        fall back to the heuristic engine.
        """

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Human-readable provider identifier (e.g. 'gemini', 'heuristic')."""


# ---------------------------------------------------------------------------
# Gemini provider
# ---------------------------------------------------------------------------
class GeminiProvider(AIProvider):
    """Google Gemini with retry + correction-prompt fallback."""

    def __init__(self, api_key: str, model: str):
        self._api_key = api_key
        self._model = model

    @property
    def provider_name(self) -> str:
        return "gemini"

    # --- low-level call (tenacity decorates at call time) ----------------
    def _call_gemini_raw(self, full_prompt: str) -> str:
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self._model}:generateContent?key={self._api_key}"
        )
        headers = {"Content-Type": "application/json"}
        gen_config: dict[str, Any] = {
            "temperature": 0.1,
            "maxOutputTokens": 2048,
            "response_mime_type": "application/json",
        }
        data = {
            "contents": [{"parts": [{"text": full_prompt}]}],
            "generationConfig": gen_config,
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=settings.AI_TIMEOUT_SECONDS) as resp:
                res = json.loads(resp.read().decode("utf-8"))
                return res["candidates"][0]["content"]["parts"][0]["text"]
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            logger.warning("Gemini HTTP %s: %s", exc.code, body[:200])
            raise

    # --- retry-wrapped version -------------------------------------------
    def _call_with_retry(self, full_prompt: str) -> str:
        decorated = _make_retry()(self._call_gemini_raw)
        return decorated(full_prompt)

    # --- JSON cleanup & parse --------------------------------------------
    @staticmethod
    def _clean_and_parse(raw: str) -> dict[str, Any]:
        clean = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw.strip(), flags=re.MULTILINE)
        return json.loads(clean)

    # --- public extract method -------------------------------------------
    def extract(self, raw_text: str) -> dict[str, Any]:
        user_prompt = build_user_prompt(raw_text)
        full_prompt = f"{SYSTEM_PROMPT}\n\n{user_prompt}"

        # --- First attempt -----------------------------------------------
        try:
            raw = self._call_with_retry(full_prompt)
            return self._clean_and_parse(raw)
        except (json.JSONDecodeError, KeyError, ValueError) as exc:
            logger.warning("Gemini first-pass JSON parse failed (%s). Retrying with correction prompt.", exc)
        except Exception as exc:
            logger.error("Gemini LLM call failed after retries: %s", exc)
            raise RuntimeError(f"Gemini extraction failed: {exc}") from exc

        # --- Correction attempt ------------------------------------------
        correction_prompt = f"{SYSTEM_PROMPT}\n\n{CORRECTION_PROMPT}\n\n{user_prompt}"
        try:
            raw = self._call_with_retry(correction_prompt)
            return self._clean_and_parse(raw)
        except (json.JSONDecodeError, KeyError, ValueError) as exc:
            logger.error("Gemini correction-prompt also produced invalid JSON: %s", exc)
            raise RuntimeError(f"Gemini extraction failed after correction: {exc}") from exc
        except Exception as exc:
            logger.error("Gemini correction call failed: %s", exc)
            raise RuntimeError(f"Gemini correction failed: {exc}") from exc


# ---------------------------------------------------------------------------
# Claude stub
# ---------------------------------------------------------------------------
class ClaudeProvider(AIProvider):
    """Anthropic Claude — not yet implemented."""

    @property
    def provider_name(self) -> str:
        return "claude"

    def extract(self, raw_text: str) -> dict[str, Any]:
        raise NotImplementedError(
            "ClaudeProvider is not yet implemented. "
            "Set AI_PROVIDER=gemini or AI_PROVIDER=heuristic in .env."
        )


# ---------------------------------------------------------------------------
# OpenAI stub
# ---------------------------------------------------------------------------
class OpenAIProvider(AIProvider):
    """OpenAI GPT — not yet implemented."""

    @property
    def provider_name(self) -> str:
        return "openai"

    def extract(self, raw_text: str) -> dict[str, Any]:
        raise NotImplementedError(
            "OpenAIProvider is not yet implemented. "
            "Set AI_PROVIDER=gemini or AI_PROVIDER=heuristic in .env."
        )


# ---------------------------------------------------------------------------
# Heuristic (offline) fallback
# ---------------------------------------------------------------------------
class HeuristicProvider(AIProvider):
    """Offline rule-based provider — no API key required."""

    @property
    def provider_name(self) -> str:
        return "heuristic"

    def extract(self, raw_text: str) -> dict[str, Any]:
        # Import here to avoid circular; extraction_service uses this module
        from app.services.extraction_service import _extract_heuristic_raw
        return _extract_heuristic_raw(raw_text)


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------
def get_ai_provider() -> AIProvider:
    """Return the correct AIProvider instance based on settings.

    Priority:
    1. If AI_PROVIDER=gemini and GEMINI_API_KEY is set → GeminiProvider
    2. If AI_PROVIDER=anthropic and ANTHROPIC_API_KEY is set → ClaudeProvider
    3. If AI_PROVIDER=openai and OPENAI_API_KEY is set → OpenAIProvider
    4. Fallback → HeuristicProvider
    """
    prov = settings.resolved_ai_provider.lower()
    key = settings.resolved_ai_key
    model = settings.resolved_ai_model

    if prov == "gemini" and key:
        logger.debug("AI provider: GeminiProvider (model=%s)", model)
        return GeminiProvider(api_key=key, model=model)

    if prov == "anthropic" and key:
        logger.debug("AI provider: ClaudeProvider (stub)")
        return ClaudeProvider()

    if prov == "openai" and key:
        logger.debug("AI provider: OpenAIProvider (stub)")
        return OpenAIProvider()

    logger.info("No cloud AI key configured. Using offline HeuristicProvider.")
    return HeuristicProvider()
