"""Build evaluation payloads for attempts."""

from __future__ import annotations

from ..schemas.evaluation import (
    EvalDimension,
    EvalMetric,
    EvalQuestion,
    EvaluationDetailData,
)


def build_evaluation_payload(
    *,
    attempt_id: str,
    answer_text: str | None,
) -> EvaluationDetailData:
    """Build deterministic MVP evaluation payload for one attempt."""
    answer = answer_text or "Could I get a hot latte with oat milk, please?"

    return EvaluationDetailData(
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
