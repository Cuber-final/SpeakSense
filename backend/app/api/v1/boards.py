"""Board routes for MVP backend."""

from __future__ import annotations

import json
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...jobs import dispatch_generate_board
from ...models.board import Board
from ...schemas.boards import (
    BoardCreateRequest,
    BoardQuestion,
    BoardQuestionsResponse,
    BoardResponse,
)

router = APIRouter(prefix="/boards", tags=["boards"])
db_session = Depends(get_db)


def _to_board_response(board: Board) -> BoardResponse:
    """Convert board ORM entity to response schema."""
    return BoardResponse(
        id=board.id,
        title=board.title,
        topic=board.topic,
        level=board.level,
        status=board.status,
        created_at=board.created_at,
    )


@router.post("", response_model=BoardResponse, status_code=status.HTTP_201_CREATED)
async def create_board(
    payload: BoardCreateRequest,
    db: Session = db_session,
) -> BoardResponse:
    """Create a board and dispatch async generation."""
    board = Board(
        id=str(uuid4()),
        title=payload.title,
        topic=payload.topic,
        level=payload.level,
        status="generating",
    )
    db.add(board)
    db.commit()

    dispatch_generate_board(board.id)

    db.refresh(board)
    return _to_board_response(board)


@router.get("", response_model=list[BoardResponse])
async def list_boards(db: Session = db_session) -> list[BoardResponse]:
    """List all boards."""
    query: Select[tuple[Board]] = select(Board).order_by(Board.created_at.desc())
    boards = db.execute(query).scalars().all()
    return [_to_board_response(board) for board in boards]


@router.get("/{board_id}/questions", response_model=BoardQuestionsResponse)
async def get_board_questions(
    board_id: str,
    db: Session = db_session,
) -> BoardQuestionsResponse:
    """Return generated board questions."""
    board = db.get(Board, board_id)
    if board is None:
        raise HTTPException(status_code=404, detail="Board not found")
    if board.status != "ready":
        raise HTTPException(status_code=409, detail="Board is not ready")

    try:
        payload = json.loads(board.questions_json)
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=500,
            detail="Invalid board questions payload",
        ) from exc

    questions = [BoardQuestion.model_validate(item) for item in payload]

    return BoardQuestionsResponse(board_id=board_id, questions=questions)


@router.delete(
    "/{board_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_board(
    board_id: str,
    db: Session = db_session,
) -> Response:
    """Delete one board."""
    board = db.get(Board, board_id)
    if board is None:
        raise HTTPException(status_code=404, detail="Board not found")

    db.delete(board)
    db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)
