"""Schemas for evaluation endpoints."""

from __future__ import annotations

from pydantic import BaseModel


class EvaluationStatusResponse(BaseModel):
    """Evaluation status payload."""

    attempt_id: str
    status: str


class EvalDimension(BaseModel):
    """Dimension score model."""

    label: str
    score: float


class EvalMetric(BaseModel):
    """Metric model."""

    key: str
    label: str
    value: str


class EvalQuestion(BaseModel):
    """Question-level evaluation model."""

    question: str
    answer: str
    feedback: str
    suggested_answer: str
    audio_url: str | None
    dimensions: list[EvalDimension]


class EvaluationDetailData(BaseModel):
    """Evaluation detail payload."""

    id: str
    scenario_title: str
    overall_score: float
    level: str
    summary: str
    dimensions: list[EvalDimension]
    metrics: list[EvalMetric]
    questions: list[EvalQuestion]


class EvaluationDetailResponse(BaseModel):
    """Evaluation detail response wrapper."""

    data: EvaluationDetailData
