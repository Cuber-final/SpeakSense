# AGENTS.md

This file defines how agents should work in this repo and the step‑by‑step plan to deliver the MVP. Its scope is the entire repository.

---

## Ground Rules

- Branching (MVP period): `dev` is the integration branch; `main` stays stable. Day‑to‑day work lands on `dev` via PR; release candidates are merged `dev → main` after QA. Short‑lived feature branches are made off `dev`.
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- Keep changes minimal, focused, and documented. Update docs when interfaces change.
- Python 3.11+ only. Flutter stable channel for frontend.
- JSON structured logs with `X-Request-Id` across API and workers.
- API errors use Problem JSON: `{ error: { type, code, message, details } }`.
- No audio persisted at rest. ASR must delete source audio after transcription.

---

## Code Standards

- Backend (FastAPI): use `ruff`, `black`, `isort`, and `mypy` (strict for new/changed code).
- Testing: backend uses `pytest`; Flutter uses widget tests. Coverage target > 70%.
- Types & validation: Pydantic v2; all timestamps in UTC; UUID v4 primary keys.
- API versioning: URL prefix `/v1`; generate and validate OpenAPI in CI.
- Resilience: rate limit by IP + user; POST supports `Idempotency-Key`.
- Data & jobs: PostgreSQL + Alembic; RQ + Redis.
- Providers: OpenAI‑compatible adapters, swappable via env (`LLM_PROVIDER`, etc.).
- Security baseline: tighten CORS in prod; CSP/HSTS/Referrer‑Policy; secrets via env/secret manager.

### Python/FastAPI Style Guide

- General
  - Type hints are mandatory for all functions/classes; include explicit return types.
  - Docstrings: follow PEP 257 for all public functions/classes/modules.
  - Naming: semantic names; booleans prefixed with `is_`/`has_`; files/dirs use `snake_case`.
  - Structure: prefer functional and modular code; avoid duplication; extract utilities.
  - RORO: Receive an object, return an object; avoid hidden global dependencies.

- FastAPI conventions
  - Routers live under `backend/app/api`; each module exports a named `router`.
  - Models: use Pydantic v2 `BaseModel` for input/output; set `response_model` on routes.
  - Dependencies: use FastAPI DI for DB, LLM clients, and other shared resources.
  - Lifecycle: prefer lifespan context over `@app.on_event`.
  - I/O: make DB and external calls async; avoid blocking operations.
  - Middleware: request ID, logging, error handling, and rate limiting as middleware.
  - Errors: use `HTTPException` for expected errors; otherwise return Problem JSON (`code/type/message/details`).
  - Route style: use guard clauses and early returns; minimize nested `else` blocks.

- Layout & files (backend)
  - `api/` routes; `services/` business and adapters; `models/` ORM; `schemas/` Pydantic; `jobs/` RQ; `core/` settings/security/logging/errors.
  - Lowercase file names, resource-oriented naming: e.g., `api/boards.py`, `services/llm/client.py`.

- Errors & logging
  - Handle invalid states up front and return early; place the happy path last.
  - Use structured JSON logs and include `request_id`; include `code`, `status`, `provider` on error logs where applicable.

- Performance & operability
  - Avoid blocking; cache hot data (Redis or in‑memory); lazy‑load large datasets.
  - Prefer Pydantic models for serialization; avoid ad‑hoc deeply nested dicts.

- Dependencies & tooling
  - Use Poetry (`backend/pyproject.toml`) as the primary dependency manager; keep `requirements.txt` as compatibility mirror when needed.
  - Unified checks: `ruff` (E/F/I/UP/ASYNC/B/C4/SIM), `black`, `isort`, `mypy`.

- Testing
  - Use `pytest` and plugins only; do not use `unittest`.
  - Place tests under `backend/tests`; name files `test_*.py` and tests `test_*`.
  - Add type hints and docstrings to tests and fixtures; under `typing.TYPE_CHECKING` import pytest types (e.g., `_pytest.*`, `pytest_mock`) if needed.
  - Cover API contracts, error paths (Problem JSON), middleware (Request‑ID), and health checks.

---

## UI/UX Style

- Design system: Material 3. Chinese UI; content language English.
- Themes: light/dark. Colors: primary blue `#2962FF` (adjust if brand changes).
- Fonts: Noto Sans SC (CJK) + Inter (Latin). Commercial‑safe.
- Spacing: 4pt grid. Corners: 8/12. Min touch target 44×44.
- Icons: Material Symbols Rounded. Animations 120–200ms, subtle.
- Accessibility: text scaling 120%, contrast ≥ 4.5, focus order sensible.
- Performance budgets: first screen ≤ 1.5s; Android < 25MB, iOS < 30MB.

---

## Repository Layout (Target)

```
/backend
  /app
    api/       # FastAPI routers (auth, boards, practice, eval, vocab, ws)
    services/  # llm/, asr/, eval/, boards/
    jobs/      # RQ job functions
    models/    # SQLAlchemy models
    schemas/   # Pydantic schemas
    db/        # session, migrations
    ws/        # websocket events
    core/      # settings, security, logging, errors
  pyproject.toml  requirements.txt  alembic/
  Dockerfile  docker-compose.yml
/frontend     # Flutter app
```

---

## Step‑By‑Step Development Plan

为避免多处进度冲突，状态维护统一收敛到文档目录：

- 里程碑总览（唯一真相源）：`docs/project-roadmap.md`
- 后端详细进度：`docs/backend-development-progress.md`
- Flutter 详细进度：`docs/flutter-development-progress.md`

本文件保留“开发约束、质量标准、命令规范”作为执行上下文，不再承载日常打勾式进度状态。

---

## Acceptance Criteria (Per Feature)

- OpenAPI contract stable and matches implemented endpoints.
- Problem JSON on all non‑2xx responses with meaningful `code`.
- Idempotent POSTs deduplicate within 24h when `Idempotency-Key` is provided.
- Request/Job logs include `request_id`, `user_id` (if any), `attempt_id`.
- Audio never persisted; temporary files auto‑deleted; tests verify deletion.
- All new Python code includes type hints and PEP 257 docstrings.

---

## Review Checklist (PR Template Hints)

- Changes follow Conventional Commits; screenshots for UI changes.
- Updated docs (CLAUDE.md/AGENTS.md) when contracts or flows change.
- Tests added/updated; coverage trend not decreasing for touched areas.
- Security/privacy reviewed (no secrets in logs; audio not stored).
- Rollback notes prepared if schema or contracts change.
- Lint/format/type checks pass (`ruff`, `black`, `isort`, `mypy`).
- New/changed Python code has full type hints and PEP 257 docstrings.

---

## Contact

Ping the maintainer for clarifications on design tokens, env secrets, or provider access.

## Commands

- Create env (pyenv, per Runbook)
  - `pyenv virtualenv 3.11.11 esc_dev && pyenv activate esc_dev`
  - Install deps: `cd backend && poetry install`
  - Optional: set local env for this repo `pyenv local esc_dev`
  - Optional lock refresh: `cd backend && poetry lock`

- Optional (without pyenv): `python3.11 -m venv .venv && source .venv/bin/activate`
  - Then: `cd backend && poetry install`
  - Optional shell entry: `cd backend && poetry shell`

- Run API locally (without Docker)
  - `make api`  # alias for `uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000`

- Run background worker (RQ)
  - `make worker`  # uses `$REDIS_URL` or defaults to local redis

- Database (Alembic)
  - Upgrade: `make migrate`  # alias for `alembic -c backend/alembic.ini upgrade head`
  - New migration: `alembic -c backend/alembic.ini revision --autogenerate -m "message"`
  - Downgrade 1 step: `alembic -c backend/alembic.ini downgrade -1`

- Tests (pytest)
  - All tests: `make test`  or  `pytest -q`
  - With coverage: `pytest --cov=backend --cov-report=term-missing -q`
  - Filter by keyword/node: `pytest -k "health or auth" -q`
  - E2E 核心流：`pytest -k e2e_text_flow -q`
  - 仅语音/WS：`pytest -k "voice or ws_broadcast" -q`

- Linting, formatting, typing
  - One‑shot: `make fmt && make lint && make type`
  - Individually: `ruff check backend` · `black backend` · `isort backend` · `mypy backend`

- Docker Compose (services stack)
  - Up (build): `make dev`  # alias for `docker compose up -d --build`
  - Down (purge volumes): `make dev-down`  or  `docker compose down -v`
  - Logs: `docker compose logs -f api worker redis db rq-dashboard`

- OpenAPI (export to file)
  - `make openapi`  # writes `openapi.json` at repo root

- Environment setup helpers
  - Copy env example: `cp backend/.env.example backend/.env`
  - Print FastAPI OpenAPI URL (when running): `echo http://localhost:8000/openapi.json`

- Frontend (Flutter shell)
  - Setup: `cd frontend && flutter pub get`
  - Enable web (once): `flutter config --enable-web`
  - Run (web): `flutter run -d chrome`
  - Run (Android): `flutter run -d android`  ·  (iOS): `flutter run -d ios`
  - Analyze/format: `flutter analyze`  ·  `dart format .`
  - Tests: `flutter test -r compact`
  - Base URL: edit `frontend/lib/app/env.dart` (`baseUrlProvider`，默认 `http://localhost:8000`)
  - Mock API 开关：应用右上角"开发者"菜单切换（默认开启）

- Git (branching)
  - Create integration branch locally and push: `git switch -c dev && git push -u origin dev`
  - Start a feature: `git switch -c feat/<topic> dev`
  - Open PR to `dev`: `git push -u origin feat/<topic>` → PR target `dev`
  - Release RC: merge `dev → main` via PR after QA passes
  - 本地切换到开发分支：`git switch dev`
