"""Deterministic board-question generation helpers."""

from __future__ import annotations

from uuid import UUID, uuid5

LEVEL_STYLE_HINTS: dict[str, str] = {
    "A1": "Keep the sentence simple and short.",
    "A2": "Use short connected sentences.",
    "B1": "Give clear reasons and one example.",
    "B2": "Use detailed arguments and natural transitions.",
    "C1": "Use precise and nuanced language.",
}


def _stable_question_id(board_id: str, variant: str) -> str:
    """Build stable question IDs per board and variant."""
    namespace = UUID(board_id)
    return str(uuid5(namespace, variant))


def _style_hint(level: str) -> str:
    """Resolve style hint by CEFR level."""
    return LEVEL_STYLE_HINTS.get(level.upper(), LEVEL_STYLE_HINTS["B1"])


def build_board_questions(
    *,
    board_id: str,
    title: str,
    topic: str,
    level: str,
) -> list[dict[str, str]]:
    """Generate deterministic board questions for one scenario."""
    hint = _style_hint(level)
    normalized_topic = topic.strip()
    normalized_title = title.strip()

    templates: list[tuple[str, str]] = [
        (
            "core",
            (
                f"Scenario {normalized_title}: introduce yourself in a "
                f"{normalized_topic} "
                f"context. {hint}"
            ),
        ),
        (
            "follow_up",
            (
                f"Ask a natural follow-up question to continue the {normalized_topic} "
                "conversation."
            ),
        ),
        (
            "role_play",
            (
                f"Role-play one challenge in {normalized_topic}, then "
                "propose a practical "
                "solution in 2-3 sentences."
            ),
        ),
        (
            "reflection",
            (
                f"Reflect on what went well and what to improve next time in this "
                f"{normalized_topic} scenario."
            ),
        ),
    ]

    return [
        {
            "id": _stable_question_id(board_id, variant),
            "prompt": prompt,
            "variant": variant,
        }
        for variant, prompt in templates
    ]
