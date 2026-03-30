"""OpenAI-compatible ASR provider implementation."""

from __future__ import annotations

from typing import Any

import httpx

from .adapter import ASRAdapter
from .exceptions import ASRServiceError
from .types import ASRRequest, ASRResponse


class OpenAICompatibleASRAdapter(ASRAdapter):
    """Adapter for providers exposing OpenAI audio transcription semantics."""

    provider_name = "openai_compatible"

    def __init__(
        self,
        *,
        base_url: str,
        api_key: str,
        model: str,
        timeout_ms: int,
        max_retries: int,
        provider_name: str = "openai_compatible",
        client: httpx.AsyncClient | None = None,
    ) -> None:
        """Initialize adapter with endpoint and authentication."""
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.model = model
        self.timeout_ms = timeout_ms
        self.max_retries = max_retries
        self.provider_name = provider_name
        self._client = client

    async def transcribe(self, request: ASRRequest) -> ASRResponse:
        """Execute non-streaming ASR via OpenAI-compatible provider."""
        payload = {"model": self.model, "language": request.language}
        headers = self._build_headers()

        attempts = self.max_retries + 1
        last_error: ASRServiceError | None = None
        for attempt in range(attempts):
            try:
                response = await self._post_multipart(
                    path="/audio/transcriptions",
                    payload=payload,
                    headers=headers,
                    request=request,
                )
                text = self._extract_text(response)
                return ASRResponse(
                    transcript=text,
                    provider=self.provider_name,
                    model=self.model,
                )
            except ASRServiceError as exc:
                last_error = exc
                if not self._should_retry(exc, attempt=attempt, attempts=attempts):
                    raise

        if last_error is not None:
            raise last_error

        raise ASRServiceError(
            code="ASR_PROVIDER_UNAVAILABLE",
            message="Provider request failed",
            details={"provider": self.provider_name},
            status_code=503,
        )

    def _build_headers(self) -> dict[str, str]:
        """Build HTTP headers for provider request."""
        headers: dict[str, str] = {}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers

    async def _post_multipart(
        self,
        *,
        path: str,
        payload: dict[str, Any],
        headers: dict[str, str],
        request: ASRRequest,
    ) -> dict[str, Any]:
        """Run multipart post request and parse JSON response."""
        timeout = request_timeout = max(self.timeout_ms / 1000.0, 0.1)
        url = f"{self.base_url}{path}"
        files = {
            "file": (
                request.filename,
                request.file_path.read_bytes(),
                request.content_type or "application/octet-stream",
            )
        }

        if self._client is not None:
            return await self._send_request(
                client=self._client,
                url=url,
                payload=payload,
                headers=headers,
                files=files,
                request_timeout=request_timeout,
            )

        async with httpx.AsyncClient(timeout=timeout) as client:
            return await self._send_request(
                client=client,
                url=url,
                payload=payload,
                headers=headers,
                files=files,
                request_timeout=request_timeout,
            )

    async def _send_request(
        self,
        *,
        client: httpx.AsyncClient,
        url: str,
        payload: dict[str, Any],
        headers: dict[str, str],
        files: dict[str, tuple[str, bytes, str]],
        request_timeout: float,
    ) -> dict[str, Any]:
        """Send request and map provider errors into domain errors."""
        try:
            response = await client.post(
                url,
                data=payload,
                files=files,
                headers=headers,
                timeout=request_timeout,
            )
        except httpx.TimeoutException as exc:
            raise ASRServiceError(
                code="ASR_TIMEOUT",
                message="ASR provider request timed out",
                details={"provider": self.provider_name},
                status_code=504,
            ) from exc
        except httpx.HTTPError as exc:
            raise ASRServiceError(
                code="ASR_PROVIDER_UNAVAILABLE",
                message="Unable to reach ASR provider",
                details={"provider": self.provider_name},
                status_code=503,
            ) from exc

        if response.status_code == 401:
            raise ASRServiceError(
                code="ASR_AUTH_ERROR",
                message="ASR provider authentication failed",
                details={"provider": self.provider_name},
                status_code=401,
            )
        if response.status_code == 429:
            raise ASRServiceError(
                code="ASR_RATE_LIMITED",
                message="ASR provider rate limited the request",
                details={"provider": self.provider_name},
                status_code=429,
            )
        if response.status_code >= 400:
            raise ASRServiceError(
                code="ASR_PROVIDER_ERROR",
                message="ASR provider returned an error response",
                details={
                    "provider": self.provider_name,
                    "status_code": response.status_code,
                    "response_body": response.text,
                },
                status_code=502,
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise ASRServiceError(
                code="ASR_PROVIDER_ERROR",
                message="ASR provider returned non-JSON response",
                details={"provider": self.provider_name},
                status_code=502,
            ) from exc
        if not isinstance(payload, dict):
            raise ASRServiceError(
                code="ASR_PROVIDER_ERROR",
                message="ASR provider returned invalid response payload",
                details={"provider": self.provider_name},
                status_code=502,
            )
        return payload

    def _extract_text(self, payload: dict[str, Any]) -> str:
        """Extract transcript text from provider payload."""
        text = payload.get("text")
        if isinstance(text, str) and text.strip():
            return text.strip()
        raise ASRServiceError(
            code="ASR_EMPTY_TRANSCRIPT",
            message="ASR transcript is empty",
            details={"provider": self.provider_name},
            status_code=502,
        )

    def _should_retry(
        self,
        error: ASRServiceError,
        *,
        attempt: int,
        attempts: int,
    ) -> bool:
        """Return whether request should retry for current failure."""
        if attempt >= attempts - 1:
            return False
        return error.code in {
            "ASR_RATE_LIMITED",
            "ASR_TIMEOUT",
            "ASR_PROVIDER_UNAVAILABLE",
            "ASR_PROVIDER_ERROR",
        }
