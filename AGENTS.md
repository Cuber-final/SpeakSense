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
  - Use `requirements.txt` for dependencies (optionally adopt `pip-tools` later); Poetry not used for now.
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

## Step‑By‑Step Development Plan (Todo)

Status keys: [ ] pending  [x] done  [~] in progress

### M0 — Project Setup

- [ ] Create base repo structure (`/backend`, `/frontend`, `/infra`).
- [ ] Add Python toolchain (`ruff`, `black`, `isort`, `mypy`, `pytest`).
- [ ] Add Makefile tasks: `dev`, `test`, `fmt`, `migrate`.
- [ ] Docker Compose: `api`, `worker`, `redis`, `db`, `rq-dashboard`.
- [ ] Logging scaffold with `X-Request-Id` middleware.
- [ ] Problem JSON error handler and global exception mapping.
- Acceptance: `docker compose up` exposes `GET /healthz` 200 and OpenAPI shell.

### M1 — Backend Core

- [ ] Auth: JWT login (`POST /v1/auth/login`), `GET /v1/auth/me`. Seed admin (dev auto-seed).
- [ ] Boards: `POST /v1/boards`, list, get questions, delete.
- [ ] Jobs: `jobs.generate_board(board_id)` with adapter (dummy LLM); mark board ready.
- [ ] Practice: attempts + answers (text). Word limit validation (≤ 40 words).
- [ ] Evaluation: `jobs.evaluate_attempt(attempt_id)`; JSON result; `GET /attempts/{id}/evaluation` and `/status`.
- [ ] Wordbook: add/list with provenance.
- [ ] Rate limiting + POST idempotency middleware.
- [ ] OpenAPI generation (Makefile target) and ready for CI validation.
- Acceptance: curl flows in CLAUDE.md succeed; RQ dashboard shows jobs; WS event fires once.

### M2 — Voice & Realtime

- [ ] ASR wrapper (faster‑whisper) with 8‑bit quantization option.
- [ ] `POST /answers/voice` (multipart upload) → transcript preview; enforce 90s cap.
- [ ] Hard guard `ASR_DELETE_AUDIO_AFTER=true` (refuse to run if false).
- [ ] WebSocket `/ws/events` push `evaluation.completed`.
- Acceptance: audio upload round‑trip; source audio deleted; WS banner triggered in frontend shell.

### M3 — Flutter Shell & UX

- [ ] Project bootstrap (Material 3, light/dark themes, tokens).
- [ ] Navigation: bottom tabs (4) + evaluation secondary route.
- [ ] Mock toggle (Debug menu) and dio/ws scaffolding.
- [ ] Offline drafts for text answers + 35-word soft hint.
- [ ] Screens: Boards list/detail, Practice (text/voice), Evaluation, Wordbook.
  - [ ] Boards — list grid + skeleton（Mock 数据）。
  - [ ] Boards — detail（问题与 variants 展示 + CTA 开始练习）。
  - [ ] Practice — 文本输入与草稿；35 词软上限提示。
  - [ ] Practice — 语音录制（已实现）+ 上传调用 `/v1/answers/voice`（待接入）+ ASR 预览编辑。
  - [ ] Evaluation — 汇总页 + 详情页骨架；Radar 图组件。
  - [ ] Evaluation — 真实数据绑定，逐题反馈与建议交互。
  - [ ] Wordbook — 列表占位（待数据模型与增删改同步）。
- [ ] Microcopy（中文 UI）与排版细化；空状态与加载骨架完善。
- [ ] Realtime 前端：订阅 `/ws/events` 并显示"评估完成" Banner + 导航跳转。
- [ ] Acceptance: demo 视频（Mock 全流转 + 实 API 切换）。

### M3 — Forui UI Migration (New)

- 目标：在保持可运行和可回退的前提下，用 forui 替换现有 Material 组件，统一主题与组件风格；全程支持 Web 调试。
- 策略：先"接入 forui + 主题共存"，再"逐屏替换组件"，最后"覆盖 Overlay 与导航细节"。

- [ ] Step 1: 接入 forui 与主题共存
  - `forui` 依赖就绪；入口以 `FTheme` 包裹，并通过 `toApproximateMaterialTheme()` 与 Material 共存。
  - 调试菜单新增 "Forui UI：开/关"。
  - Web 启动通过。

- [ ] Step 2: 设计令牌映射到 `FThemeData`
  - `buildForuiTheme()` 保留默认风格并附加品牌色扩展，确保主题共存。

- [ ] Step 3: 屏级替换（第一批：Boards + Practice 文本）
  - Boards：列表卡片与详情页使用 `FCard`、`FBadge`、`FItemGroup`。
  - Practice：文本输入换成 `FTextField`；按钮和反馈全部用 Forui Toast/Dialog。

- [ ] Step 4: Practice 语音页替换与弹层（`FToast`/`FDialog`）。
- [ ] Step 5: Evaluation 交互细化（卡片/反馈等 → Forui；Radar 图保留 fl_chart）。
- [ ] Step 6: Overlay、导航与反馈统一（底部导航改 `FBottomNavigationBar`；全局 Toast/Dialog 使用 Forui）。
- [ ] Step 7: QA（Web 构建通过；本地 Chrome 运行；状态样式保持 Forui 默认，后续按需细化）。
- [ ] Step 8: 文档与回退：
  - 不再支持旧 Material 外观切换，应用固定使用 Forui。
  - 组件映射（示例）：
    - 按钮：FilledButton → FButton；输入：TextField → FTextField；卡片：Card → FCard；
    - 列表项：ListTile → FItem/FItemGroup；提示：SnackBar → showFToast；对话框：AlertDialog → showFDialog；
    - 底部导航：NavigationBar → FBottomNavigationBar。
  - 回退方案：如需临时降级，保持 Forui 主题转 Material 的近似映射（已保留），但默认不再暴露切换入口。

### M4 — Hardening & Ops

- [ ] Security headers (CSP, HSTS, Referrer‑Policy) via ASGI middleware.
- [ ] Observability: structured error logs, counters, `/readyz` checks.
- [ ] Provider failover + timeout/circuit breaker; secondary model fallback.
- [ ] Load test: 100 concurrent users; non‑LLM P95 < 300ms.
- [ ] CI/CD: lint, type, tests, build images, migrations auto‑run；`dev` branch runs full checks; release PR `dev → main` gates on green.

### M5 — Nice‑To‑Have (Post‑MVP)

- [ ] pgvector for semantic dedupe/search.
- [ ] TTS playback (edge‑tts/ElevenLabs/XTTS) for suggestions.
- [ ] Analytics toggle (self‑hosted PostHog), off by default.
- [ ] Multi‑provider AB testing and cost tracking.

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
  - Install deps: `pip install -r backend/requirements.txt`
  - Optional: set local env for this repo `pyenv local esc_dev`
  - Upgrade tooling: `python -m pip install --upgrade pip wheel setuptools`

- Optional (without pyenv): `python3.11 -m venv .venv && source .venv/bin/activate`
  - Then: `pip install -r backend/requirements.txt`
  - Optional dev tools: `pip install ruff black isort mypy pytest pytest-cov`

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
