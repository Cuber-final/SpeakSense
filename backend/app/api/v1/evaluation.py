"""Evaluation routes for attempt status and detail."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.attempt import Attempt
from ...schemas.evaluation import (
    EvalDimension,
    EvalMetric,
    EvalQuestion,
    EvaluationDetailData,
    EvaluationDetailResponse,
    EvaluationStatusResponse,
)

router = APIRouter(tags=["evaluation"])
db_session = Depends(get_db)


@router.get("/attempts/{attempt_id}/status", response_model=EvaluationStatusResponse)
async def get_attempt_status(
    attempt_id: str,
    db: Session = db_session,
) -> EvaluationStatusResponse:
    """Return attempt evaluation status."""
    attempt = db.get(Attempt, attempt_id)
    if attempt is None:
        raise HTTPException(status_code=404, detail="Attempt not found")

    status = "completed" if attempt.answer_text else attempt.status
    return EvaluationStatusResponse(attempt_id=attempt_id, status=status)


@router.get(
    "/attempts/{attempt_id}/evaluation",
    response_model=EvaluationDetailResponse,
)
async def get_attempt_evaluation(
    attempt_id: str,
    db: Session = db_session,
) -> EvaluationDetailResponse:
    """Return evaluation detail following frontend contract shape."""
    attempt = db.get(Attempt, attempt_id)
    if attempt is None:
        raise HTTPException(status_code=404, detail="Attempt not found")

    answer = attempt.answer_text or "Can I get a hot latte with oat milk, please?"
    data = EvaluationDetailData(
        id=attempt_id,
        scenario_title="Coffee Shop Ordering",
        overall_score=3.5,
        level="Intermediate High",
        summary=(
            "Great job! You are clearly understood by native "
            "speakers in most contexts."
        ),
        dimensions=[
            EvalDimension(label="Naturalness", score=4.5),
            EvalDimension(label="Richness", score=4.2),
            EvalDimension(label="Grammar", score=3.8),
            EvalDimension(label="Relevance", score=4.0),
        ],
        metrics=[
            EvalMetric(key="duration", label="Duration", value="14m 32s"),
            EvalMetric(key="pace", label="Pace", value="115 wpm"),
            EvalMetric(key="vocabulary", label="Vocabulary", value="B2 Level"),
        ],
        questions=[
            EvalQuestion(
                question="How would you order a latte with oat milk?",
                answer=answer,
                feedback="Clear request, but phrasing can be more natural.",
                suggested_answer="Could I get a hot latte with oat milk, please?",
                audio_url=None,
                dimensions=[
                    EvalDimension(label="Relevance", score=4.8),
                    EvalDimension(label="Naturalness", score=2.5),
                    EvalDimension(label="Grammar", score=3.8),
                    EvalDimension(label="Richness", score=3.2),
                ],
            )
        ],
    )

    return EvaluationDetailResponse(data=data)
