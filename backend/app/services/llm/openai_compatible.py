"""OpenAI-compatible provider adapter implementation."""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

import httpx

from .exceptions import LLMServiceError
from .types import (
    ChatMessage,
    ContentImageBase64,
    ContentImageUrl,
    ContentText,
    GenerateRequest,
    GenerateResponse,
    StreamChunk,
    ToolCall,
    Usage,
)


class OpenAICompatibleAdapter:
    """Adapter for providers implementing OpenAI chat-completions semantics."""

    provider_name = "openai_compatible"
    supported_capabilities = {"chat", "vision_input", "tool_call", "json_output"}

    def __init__(
        self,
        *,
        base_url: str,
        api_key: str,
        timeout_ms: int,
        max_retries: int,
        provider_name: str = "openai_compatible",
        client: httpx.AsyncClient | None = None,
    ) -> None:
        """Initialize adapter with endpoint and authentication."""
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.timeout_ms = timeout_ms
        self.max_retries = max_retries
        self.provider_name = provider_name
        self._client = client

    async def generate(self, request: GenerateRequest) -> GenerateResponse:
        """Execute non-streaming text or multimodal generation."""
        if request.stream:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_UNSUPPORTED_CAPABILITY",
                message="This adapter does not support streaming yet",
                details={"provider": self.provider_name},
                status_code=400,
            )

        payload = self._build_payload(request)
        headers = self._build_headers()

        attempts = self.max_retries + 1
        last_error: LLMServiceError | None = None
        for attempt in range(attempts):
            try:
                response = await self._post_json(
                    path="/chat/completions",
                    payload=payload,
                    headers=headers,
                    timeout_ms=request.timeout_ms,
                )
                return self._parse_generate_response(response)
            except LLMServiceError as exc:
                last_error = exc
                if not self._should_retry(exc, attempt=attempt, attempts=attempts):
                    raise

        if last_error is not None:
            raise last_error

        raise LLMServiceError(
            error_type="provider_error",
            code="LLM_PROVIDER_UNAVAILABLE",
            message="Provider request failed",
            details={"provider": self.provider_name},
            status_code=503,
        )

    async def stream(self, request: GenerateRequest) -> AsyncIterator[StreamChunk]:
        """Streaming is not yet implemented for this MVP adapter."""
        _ = request
        raise LLMServiceError(
            error_type="provider_error",
            code="LLM_UNSUPPORTED_CAPABILITY",
            message="Streaming is not implemented",
            details={"provider": self.provider_name},
            status_code=400,
        )

    async def health(self) -> bool:
        """Check provider health by probing models endpoint."""
        try:
            await self._get_json(path="/models", timeout_ms=self.timeout_ms)
        except LLMServiceError:
            return False
        return True

    def _build_headers(self) -> dict[str, str]:
        """Build HTTP headers for provider request."""
        headers: dict[str, str] = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers

    def _build_payload(self, request: GenerateRequest) -> dict[str, Any]:
        """Build OpenAI chat-completions request payload."""
        payload: dict[str, Any] = {
            "model": request.model,
            "messages": [
                self._serialize_message(message) for message in request.messages
            ],
            "stream": False,
        }

        if request.temperature is not None:
            payload["temperature"] = request.temperature
        if request.top_p is not None:
            payload["top_p"] = request.top_p
        if request.max_output_tokens is not None:
            payload["max_tokens"] = request.max_output_tokens
        if request.tools:
            payload["tools"] = [
                {
                    "type": "function",
                    "function": {
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": tool.json_schema,
                    },
                }
                for tool in request.tools
            ]
        if request.response_format is not None:
            payload["response_format"] = request.response_format

        return payload

    def _serialize_message(self, message: ChatMessage) -> dict[str, Any]:
        """Serialize internal message format into OpenAI-compatible format."""
        if all(isinstance(part, ContentText) for part in message.content):
            text_parts: list[str] = []
            for part in message.content:
                if isinstance(part, ContentText):
                    text_parts.append(part.text)
            text_content = "".join(text_parts)
            return {"role": message.role, "content": text_content}

        content = [self._serialize_content(part) for part in message.content]
        return {"role": message.role, "content": content}

    def _serialize_content(
        self,
        part: ContentText | ContentImageUrl | ContentImageBase64,
    ) -> dict[str, Any]:
        """Serialize a single message content part."""
        if isinstance(part, ContentText):
            return {"type": "text", "text": part.text}

        if isinstance(part, ContentImageUrl):
            return {"type": "image_url", "image_url": {"url": part.image_url}}

        data_url = f"data:{part.mime_type};base64,{part.data}"
        return {"type": "image_url", "image_url": {"url": data_url}}

    def _parse_generate_response(self, payload: dict[str, Any]) -> GenerateResponse:
        """Parse provider response into internal DTO."""
        choices = payload.get("choices", [])
        if not choices:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_EMPTY_OUTPUT",
                message="Provider returned empty choices",
                details={"provider": self.provider_name},
                status_code=502,
            )

        first_choice = choices[0]
        message = first_choice.get("message", {})
        finish_reason = first_choice.get("finish_reason", "stop")

        output_text = self._extract_text(message.get("content"))
        tool_calls = self._extract_tool_calls(message.get("tool_calls", []))

        usage_payload = payload.get("usage", {})
        usage = Usage(
            input_tokens=int(usage_payload.get("prompt_tokens", 0)),
            output_tokens=int(usage_payload.get("completion_tokens", 0)),
            total_tokens=int(usage_payload.get("total_tokens", 0)),
        )

        return GenerateResponse(
            provider=self.provider_name,
            model=str(payload.get("model", "unknown")),
            output_text=output_text,
            finish_reason=str(finish_reason),
            usage=usage,
            tool_calls=tool_calls,
            raw_response=payload,
        )

    def _extract_text(self, content: Any) -> str:
        """Extract normalized text from provider message content."""
        if isinstance(content, str):
            return content

        if not isinstance(content, list):
            return ""

        parts: list[str] = []
        for item in content:
            if not isinstance(item, dict):
                continue
            if item.get("type") == "text" and isinstance(item.get("text"), str):
                parts.append(item["text"])

        return "".join(parts)

    def _extract_tool_calls(self, tool_calls: Any) -> list[ToolCall]:
        """Extract tool-calls from provider response."""
        if not isinstance(tool_calls, list):
            return []

        parsed: list[ToolCall] = []
        for tool_call in tool_calls:
            if not isinstance(tool_call, dict):
                continue
            function_data = tool_call.get("function", {})
            if not isinstance(function_data, dict):
                continue

            name = function_data.get("name")
            if not isinstance(name, str):
                continue

            arguments_raw = function_data.get("arguments", "{}")
            arguments: dict[str, Any] = {}
            if isinstance(arguments_raw, str):
                try:
                    decoded = json.loads(arguments_raw)
                    if isinstance(decoded, dict):
                        arguments = decoded
                except json.JSONDecodeError:
                    arguments = {"raw": arguments_raw}
            elif isinstance(arguments_raw, dict):
                arguments = arguments_raw

            parsed.append(ToolCall(name=name, arguments=arguments))

        return parsed

    async def _post_json(
        self,
        *,
        path: str,
        payload: dict[str, Any],
        headers: dict[str, str],
        timeout_ms: int,
    ) -> dict[str, Any]:
        """Execute JSON POST call and normalize errors."""
        url = f"{self.base_url}{path}"
        timeout = httpx.Timeout(timeout_ms / 1000)

        try:
            if self._client is None:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.post(url, json=payload, headers=headers)
            else:
                response = await self._client.post(url, json=payload, headers=headers)
        except httpx.TimeoutException as exc:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_TIMEOUT",
                message="Upstream request timed out",
                details={"provider": self.provider_name, "url": url},
                status_code=504,
            ) from exc
        except httpx.HTTPError as exc:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_PROVIDER_UNAVAILABLE",
                message="Unable to reach upstream provider",
                details={"provider": self.provider_name, "url": url},
                status_code=503,
            ) from exc

        return self._parse_http_response(response)

    async def _get_json(self, *, path: str, timeout_ms: int) -> dict[str, Any]:
        """Execute JSON GET call and normalize errors."""
        url = f"{self.base_url}{path}"
        timeout = httpx.Timeout(timeout_ms / 1000)

        try:
            if self._client is None:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.get(url, headers=self._build_headers())
            else:
                response = await self._client.get(url, headers=self._build_headers())
        except httpx.TimeoutException as exc:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_TIMEOUT",
                message="Upstream request timed out",
                details={"provider": self.provider_name, "url": url},
                status_code=504,
            ) from exc
        except httpx.HTTPError as exc:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_PROVIDER_UNAVAILABLE",
                message="Unable to reach upstream provider",
                details={"provider": self.provider_name, "url": url},
                status_code=503,
            ) from exc

        return self._parse_http_response(response)

    def _parse_http_response(self, response: httpx.Response) -> dict[str, Any]:
        """Convert HTTP response to JSON and map provider errors."""
        if response.status_code >= 400:
            self._raise_http_error(response)

        try:
            payload = response.json()
        except ValueError as exc:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_PROVIDER_UNAVAILABLE",
                message="Provider returned non-JSON response",
                details={"provider": self.provider_name},
                status_code=502,
            ) from exc

        if not isinstance(payload, dict):
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_PROVIDER_UNAVAILABLE",
                message="Provider returned invalid JSON payload",
                details={"provider": self.provider_name},
                status_code=502,
            )

        return payload

    def _raise_http_error(self, response: httpx.Response) -> None:
        """Raise normalized domain exception from upstream status code."""
        status_code = response.status_code

        code = "LLM_PROVIDER_UNAVAILABLE"
        message = "Provider request failed"

        if status_code in {401, 403}:
            code = "LLM_AUTH_ERROR"
            message = "Provider authentication failed"
        elif status_code == 429:
            code = "LLM_RATE_LIMITED"
            message = "Provider rate limit exceeded"
        elif status_code == 400:
            code = "LLM_INVALID_REQUEST"
            message = "Provider rejected request payload"
        elif status_code >= 500:
            code = "LLM_PROVIDER_UNAVAILABLE"
            message = "Provider service unavailable"

        details = {
            "provider": self.provider_name,
            "status": status_code,
            "body": response.text,
        }

        raise LLMServiceError(
            error_type="provider_error",
            code=code,
            message=message,
            details=details,
            status_code=status_code,
        )

    def _should_retry(
        self,
        error: LLMServiceError,
        *,
        attempt: int,
        attempts: int,
    ) -> bool:
        """Decide whether adapter should retry current request."""
        if attempt >= attempts - 1:
            return False

        return error.code in {
            "LLM_TIMEOUT",
            "LLM_PROVIDER_UNAVAILABLE",
            "LLM_RATE_LIMITED",
        }
