"""Evaluation routes for attempt status and detail."""

from __future__ import annotations

import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.attempt import Attempt
from ...models.evaluation import Evaluation
from ...schemas.evaluation import (
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

    return EvaluationStatusResponse(attempt_id=attempt_id, status=attempt.status)


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

    evaluation = db.execute(
        select(Evaluation).where(Evaluation.attempt_id == attempt_id)
    ).scalar_one_or_none()

    if evaluation is None:
        raise HTTPException(
            status_code=409,
            detail={
                "message": "Evaluation is not ready",
                "status": attempt.status,
            },
        )

    if evaluation.status != "completed" or evaluation.payload_json is None:
        raise HTTPException(
            status_code=409,
            detail={
                "message": "Evaluation is not ready",
                "status": evaluation.status,
            },
        )

    payload = json.loads(evaluation.payload_json)
    data = EvaluationDetailData.model_validate(payload)
    return EvaluationDetailResponse(data=data)
