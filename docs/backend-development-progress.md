# Backend 开发进度

最后更新: 2026-02-07  
项目: SpeakSense API (FastAPI)

---

## 当前里程碑状态

### B1 - 基础骨架
- [x] FastAPI 应用入口与 lifespan
- [x] `/healthz`、`/readyz`
- [x] `/v1` 路由前缀与 system smoke routes
- [x] `X-Request-Id` middleware
- [x] Problem JSON 全局异常映射（404/422/500）
- [x] JSON structured logging 基础

### B2 - LLM 抽象层（基础）
- [x] `GenerateRequest/GenerateResponse` 统一 DTO
- [x] `LLMAdapter` protocol
- [x] `ProviderRegistry` / `ModelRouter`
- [x] `LLMGateway`（能力路由：chat/tool/vision）

### B3 - OpenAI Compatible 适配器
- [x] `OpenAICompatibleAdapter`（chat-completions）
- [x] HTTP 错误归一化（`LLM_AUTH_ERROR`、`LLM_RATE_LIMITED` 等）
- [x] 重试策略（429/timeout/5xx）
- [x] VLM 内容拼装（base64 -> data URL）
- [x] `LLMServiceError` -> Problem JSON 映射

### B4 - 业务路由骨架（MVP stub）
- [x] `POST /v1/auth/login`
- [x] `GET /v1/auth/me`
- [x] `POST /v1/boards`
- [x] `GET /v1/boards`
- [x] `GET /v1/boards/{board_id}/questions`
- [x] `DELETE /v1/boards/{board_id}`
- [x] `POST /v1/attempts`
- [x] `POST /v1/attempts/{attempt_id}/answers/text`（40词硬限制）
- [x] `POST /v1/answers/voice`（MVP preview stub）
- [x] `GET /v1/attempts/{attempt_id}/status`
- [x] `GET /v1/attempts/{attempt_id}/evaluation`
- [x] `POST /v1/wordbook`
- [x] `GET /v1/wordbook`

### B5 - 数据层与迁移
- [x] SQLAlchemy ORM 基础（`Base`/`Session`/`get_db`）
- [x] 核心模型：`boards` / `attempts` / `wordbook_entries`
- [x] 业务路由切换到数据库访问（不再使用内存存储）
- [x] Alembic 初始迁移：`20260207_0001_init_core_tables`
- [x] Alembic 本地迁移验证（SQLite）

---

## 目录落地

- `backend/app/api/v1/*.py`：业务路由
- `backend/app/schemas/*.py`：请求/响应模型
- `backend/app/services/llm/*.py`：LLM 网关与适配器
- `backend/app/models/*.py`：ORM 数据模型
- `backend/alembic/versions/*.py`：数据库迁移脚本

---

## 验证记录

- [x] `PYENV_VERSION=esc_dev pyenv exec ruff check backend`
- [x] `PYENV_VERSION=esc_dev pyenv exec mypy backend`
- [x] `PYENV_VERSION=esc_dev pyenv exec python -m pytest -q backend/tests`

当前结果：`10 passed`

---

## 下一步建议

1. 增加 JWT 鉴权与用户上下文（`/auth/me` 改为真实鉴权）。
2. 增加 RQ job 流程：`generate_board`、`evaluate_attempt`。
3. 补充 WebSocket `/ws/events` 及 `evaluation.completed` 推送。
4. 接入至少一个真实 provider（OpenAI / vLLM / Ollama）做联调。
5. 将测试数据库 fixture 从 SQLite 扩展为 PostgreSQL 集成测试。
