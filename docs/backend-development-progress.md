# Backend 开发进度

最后更新: 2026-02-08  
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

### B9 - 限流与幂等中间件（M1 收口）
- [x] IP + user 维度限流（Redis 优先，内存回退）
- [x] `POST` + `Idempotency-Key`（24h 去重）
- [x] 幂等冲突返回 `409 IDEMPOTENCY_KEY_REUSED`
- [x] 限流超额返回 `429 RATE_LIMIT_EXCEEDED`
- [x] OpenAPI 契约基础校验测试

### B10 - LLM mock provider 与环境变量兼容
- [x] 新增 `MockLLMAdapter`，用于离线/联调固定输出
- [x] 增加 `/v1/system/llm/smoke` 自检接口
- [x] 根目录 `.env` + `backend/.env` 双路径加载
- [x] 兼容别名：`MODEL_PROVIDER`/`MODEL_API_BASE`/`MODEL_NAME`
- [x] `LLM_MOCK_RESPONSE_TEXT` 支持可配置 mock 响应

### B11 - 异步队列与 PostgreSQL 集成测试基线
- [x] RQ + Redis 集成测试（worker burst 模式）
- [x] 覆盖 `queued -> completed` 状态流转
- [x] PostgreSQL Alembic 升级 smoke test
- [x] `TEST_DATABASE_URL`/`TEST_POSTGRES_URL` 测试配置入口

### B12 - 语音链路 MVP（M2 基础）
- [x] ASR 服务层：`mock` 与 `faster_whisper` provider 抽象
- [x] `/v1/answers/voice` 支持 multipart 上传（离线解析）
- [x] 90s 时长硬限制（`ASR_MAX_DURATION_SECONDS`）
- [x] 安全硬开关：`ASR_DELETE_AUDIO_AFTER=true` 才允许处理
- [x] 临时音频文件处理完成即删除（含测试验证）

### B13 - Boards 生成策略与 Wordbook Provenance
- [x] 新增 `boards.question_generator`，按 `title/topic/level` 生成固定 4 类问题
- [x] 题目持久化：`boards.questions_json`（由 `generate_board` 任务写入）
- [x] `GET /v1/boards/{id}/questions` 从 DB 读取，未 ready 返回 409
- [x] Provenance 字段：`wordbook_entries.provenance_json`
- [x] `POST/GET /v1/wordbook` 支持 provenance 回写与透传
- [x] Alembic 迁移：`20260208_0004_add_board_questions_and_wordbook_provenance`

### B14 - 真实 LLM Provider 联通验证（当前阶段收口）
- [x] `OpenAICompatibleAdapter` 文本消息序列化与 Chat Completions 对齐（`content` 字符串）
- [x] 运行时加载根目录 `.env` 的 `LLM_*` 配置并生效
- [x] 联通验证：`/v1/system/llm/smoke` 真实请求上游并返回 200
- [x] 新增 `make llm-smoke` 便捷联调命令（支持 `API_BASE`、`PROMPT` 覆盖）

---

## 目录落地

- `backend/app/api/v1/*.py`：业务路由
- `backend/app/schemas/*.py`：请求/响应模型
- `backend/app/services/llm/*.py`：LLM 网关与适配器
- `backend/app/services/asr/*.py`：ASR provider 与转写服务
- `backend/app/services/boards/*.py`：题板问题生成策略
- `backend/app/models/*.py`：ORM 数据模型
- `backend/alembic/versions/*.py`：数据库迁移脚本
- `backend/app/services/auth/*.py`：鉴权服务（JWT/密码哈希/依赖）
- `backend/app/jobs/*.py`：任务调度与任务函数
- `backend/app/core/{rate_limit,idempotency}.py`：流控与幂等中间件

---

## 验证记录

- [x] `PYENV_VERSION=esc_dev poetry run ruff check app tests`（backend）
- [x] `PYENV_VERSION=esc_dev poetry run mypy app tests`（backend）
- [x] `PYENV_VERSION=esc_dev poetry run pytest -q tests`（backend）
- [x] `DATABASE_URL=sqlite+pysqlite:////tmp/speaksense_migrate_auth.db PYENV_VERSION=esc_dev pyenv exec alembic -c backend/alembic.ini upgrade head`
- [x] `DATABASE_URL=sqlite+pysqlite:////tmp/speaksense_migrate_jobs.db PYENV_VERSION=esc_dev pyenv exec alembic -c backend/alembic.ini upgrade head`

当前结果：`28 passed, 2 skipped`
已知告警：JWT dev secret 长度不足 32 字节（测试环境 warning，不影响当前功能）。

---

## 下一步建议

1. 将真实 provider 联调扩展到多后端矩阵（OpenAI-compatible、vLLM、Ollama）并补超时/重试回归测试。
2. 完成 `Idempotency-Key` 和限流状态的 Redis-only 生产模式收口（关闭内存回退）。
3. 补 `POST /answers/voice` 的真实 `faster-whisper` e2e 与大文件边界测试。
4. 为 boards/questions 增加版本号与再生成机制（支持刷新题板与差异追踪）。
