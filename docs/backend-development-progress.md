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

### B6 - JWT 鉴权闭环
- [x] 用户模型：`users`（username 唯一、password_hash、role、is_active）
- [x] Alembic 迁移：`20260207_0002_add_users_table`
- [x] `POST /v1/auth/login` 真实用户名/密码校验 + JWT 签发
- [x] `GET /v1/auth/me` Bearer Token 验签与当前用户解析
- [x] `AuthServiceError` 映射到 Problem JSON
- [x] 开发环境自动 seed admin（`DEV_ADMIN_*`）

### B7 - Jobs 与状态流转
- [x] 任务调度器：RQ 入队 + 内联回退（`ENABLE_ASYNC_JOBS`）
- [x] Job 任务：`generate_board(board_id)`、`evaluate_attempt(attempt_id)`
- [x] 评估结果持久化模型：`evaluations`（payload_json/status/error_message）
- [x] 路由接线：Board 创建后触发生成；文本答案提交后触发评估
- [x] 状态流转：`draft -> queued -> evaluating -> completed/failed`
- [x] 评估详情未就绪返回 409（含状态信息）
- [x] Alembic 迁移：`20260207_0003_add_evaluations_table`

### B8 - WebSocket 实时事件（基础）
- [x] 新增 `/ws/events` WebSocket 入口
- [x] 评估完成后推送 `evaluation.completed` 事件
- [x] 事件基础字段：`type`、`attempt_id`、`occurred_at`、`payload`
- [x] 单元测试覆盖：WS 消费 + 任务触发事件发布

---

## 目录落地

- `backend/app/api/v1/*.py`：业务路由
- `backend/app/schemas/*.py`：请求/响应模型
- `backend/app/services/llm/*.py`：LLM 网关与适配器
- `backend/app/models/*.py`：ORM 数据模型
- `backend/alembic/versions/*.py`：数据库迁移脚本
- `backend/app/services/auth/*.py`：鉴权服务（JWT/密码哈希/依赖）
- `backend/app/jobs/*.py`：任务调度与任务函数

---

## 验证记录

- [x] `PYENV_VERSION=esc_dev pyenv exec ruff check backend`
- [x] `PYENV_VERSION=esc_dev pyenv exec mypy backend`
- [x] `PYENV_VERSION=esc_dev pyenv exec python -m pytest -q backend/tests`
- [x] `DATABASE_URL=sqlite+pysqlite:////tmp/speaksense_migrate_auth.db PYENV_VERSION=esc_dev pyenv exec alembic -c backend/alembic.ini upgrade head`
- [x] `DATABASE_URL=sqlite+pysqlite:////tmp/speaksense_migrate_jobs.db PYENV_VERSION=esc_dev pyenv exec alembic -c backend/alembic.ini upgrade head`

当前结果：`16 passed`

---

## 下一步建议

1. 将 worker 运行态接入真实 Redis/RQ（`ENABLE_ASYNC_JOBS=true`）并补集成测试。
2. 接入至少一个真实 provider（OpenAI / vLLM / Ollama）做联调。
3. 将测试数据库 fixture 从 SQLite 扩展为 PostgreSQL 集成测试。
4. 增加 auth refresh token 与 token revoke（可选增强）。
