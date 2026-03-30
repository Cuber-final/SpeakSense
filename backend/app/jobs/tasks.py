"""RQ job task functions."""

from __future__ import annotations

import json
import logging
from uuid import uuid4

from sqlalchemy import select

from ..db.session import SessionLocal
from ..models.attempt import Attempt
from ..models.board import Board
from ..models.evaluation import Evaluation
from ..services.boards import build_board_questions
from ..services.evaluation_builder import build_evaluation_payload
from ..ws import publish_evaluation_completed

logger = logging.getLogger(__name__)


def generate_board(board_id: str) -> None:
    """Mark board as ready after generation finishes."""
    session = SessionLocal()
    try:
        board = session.get(Board, board_id)
        if board is None:
            logger.warning(
                "generate_board skipped: board not found",
                extra={"board_id": board_id},
            )
            return

        questions = build_board_questions(
            board_id=board.id,
            title=board.title,
            topic=board.topic,
            level=board.level,
        )
        board.questions_json = json.dumps(questions)
        board.status = "ready"
        session.add(board)
        session.commit()
    finally:
        session.close()


def evaluate_attempt(attempt_id: str) -> None:
    """Compute and persist evaluation payload for one attempt."""
    session = SessionLocal()
    try:
        attempt = session.get(Attempt, attempt_id)
        if attempt is None:
            logger.warning(
                "evaluate_attempt skipped: attempt not found",
                extra={"attempt_id": attempt_id},
            )
            return

        attempt.status = "evaluating"
        session.add(attempt)
        session.commit()

        payload = build_evaluation_payload(
            attempt_id=attempt.id,
            answer_text=attempt.answer_text,
        )

        evaluation = session.execute(
            select(Evaluation).where(Evaluation.attempt_id == attempt_id)
        ).scalar_one_or_none()

        if evaluation is None:
            evaluation = Evaluation(
                id=str(uuid4()),
                attempt_id=attempt_id,
                status="completed",
                payload_json=payload.model_dump_json(),
            )
        else:
            evaluation.status = "completed"
            evaluation.payload_json = payload.model_dump_json()
            evaluation.error_message = None

        attempt.status = "completed"
        session.add(evaluation)
        session.add(attempt)
        session.commit()

        publish_evaluation_completed(attempt_id)
    except Exception as exc:  # pragma: no cover - defensive path
        session.rollback()

        attempt = session.get(Attempt, attempt_id)
        if attempt is not None:
            attempt.status = "failed"
            session.add(attempt)

        evaluation = session.execute(
            select(Evaluation).where(Evaluation.attempt_id == attempt_id)
        ).scalar_one_or_none()

        if evaluation is None:
            evaluation = Evaluation(
                id=str(uuid4()),
                attempt_id=attempt_id,
                status="failed",
                error_message=str(exc),
                payload_json=json.dumps({"attempt_id": attempt_id}),
            )
        else:
            evaluation.status = "failed"
            evaluation.error_message = str(exc)

        session.add(evaluation)
        session.commit()

        logger.exception("evaluate_attempt failed", extra={"attempt_id": attempt_id})
    finally:
        session.close()
