"""Typed DTOs for LLM/VLM abstraction layer."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class ContentText(BaseModel):
    """Text segment for multimodal messages."""

    type: Literal["text"] = "text"
    text: str


class ContentImageUrl(BaseModel):
    """Image URL segment for multimodal messages."""

    type: Literal["image_url"] = "image_url"
    image_url: str


class ContentImageBase64(BaseModel):
    """Base64 image segment for multimodal messages."""

    type: Literal["image_base64"] = "image_base64"
    mime_type: str
    data: str


MessageContent = ContentText | ContentImageUrl | ContentImageBase64


class ChatMessage(BaseModel):
    """Unified chat message model."""

    role: Literal["system", "user", "assistant", "tool"]
    content: list[MessageContent]


class ToolSpec(BaseModel):
    """Tool specification metadata."""

    name: str
    description: str | None = None
    json_schema: dict[str, Any] = Field(default_factory=dict)


class GenerateRequest(BaseModel):
    """Unified generation request."""

    request_id: str
    model: str
    messages: list[ChatMessage]
    stream: bool = False
    provider_hint: str | None = None
    temperature: float | None = None
    top_p: float | None = None
    max_output_tokens: int | None = None
    timeout_ms: int = 30000
    tools: list[ToolSpec] = Field(default_factory=list)
    response_format: dict[str, Any] | None = None
    metadata: dict[str, str] = Field(default_factory=dict)


class Usage(BaseModel):
    """Token usage metadata."""

    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0


class ToolCall(BaseModel):
    """Structured tool call output."""

    name: str
    arguments: dict[str, Any] = Field(default_factory=dict)


class GenerateResponse(BaseModel):
    """Unified generation response."""

    provider: str
    model: str
    output_text: str
    finish_reason: str
    usage: Usage = Field(default_factory=Usage)
    tool_calls: list[ToolCall] = Field(default_factory=list)
    raw_response: dict[str, Any] = Field(default_factory=dict)


class StreamChunk(BaseModel):
    """Unified streaming chunk model."""

    delta_text: str = ""
    done: bool = False
