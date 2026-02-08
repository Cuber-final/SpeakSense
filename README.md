# SpeakSense - AI 英语口语教练

> 基于 FastAPI + Flutter 的跨平台英语口语学习应用，提供情景化练习、语音答题、智能评估与实时反馈。

## 项目定位

SpeakSense 面向口语训练场景，聚焦“练习 -> 评估 -> 复盘 -> 词汇沉淀”的完整闭环。

### 核心能力

- 情景化题板：按主题生成可练习的问题集
- 多模态答题：文本与语音上传（ASR 预览）
- 智能评估：LLM 驱动评分与建议
- 生词本：按来源记录词汇与溯源信息
- 实时通知：WebSocket 推送评估完成事件

## 技术栈预览

### 后端

- FastAPI + Pydantic v2
- PostgreSQL + SQLAlchemy + Alembic
- Redis + RQ（异步任务）
- OpenAI-compatible LLM adapter（可接不同 provider）
- pytest / ruff / mypy

### 前端

- Flutter（Web / Android / iOS）
- Material 3 + Forui 组件体系
- Dio + WebSocket
- fl_chart（评估可视化）

### 基础设施

- Docker Compose（开发环境服务编排）
- OpenAPI（接口契约）

## 快速开始

### 环境要求

- Python 3.11+
- Poetry
- Flutter stable
- Docker + Docker Compose（推荐）

### 后端启动

```bash
cd backend
poetry install
cp .env.example .env
cd ..
make api
```

### 前端启动

```bash
cd frontend
flutter pub get
flutter run -d chrome --no-web-resources-cdn
```

### 本地服务编排（可选）

```bash
make dev
docker compose logs -f
```

## 文档入口

- 开发规范与执行约束：`AGENTS.md`
- 项目路线图（唯一进度总览）：`docs/project-roadmap.md`
- 后端详细进度：`docs/backend-development-progress.md`
- Flutter 详细进度：`docs/flutter-development-progress.md`
- 文档目录索引：`docs/README.md`

## 分支策略

- `main`：稳定分支
- `dev`：集成分支（MVP 日常开发）
- `feat/*`：特性分支（从 `dev` 创建）
- `fix/*`：修复分支（从 `dev` 创建）

## 仓库结构

```text
speaksense/
├── backend/              # FastAPI API, models, jobs, migrations
├── frontend/             # Flutter client app
├── frontend-base/        # React 原型（参考）
├── docs/                 # 路线图、计划、进度、设计文档
├── AGENTS.md             # 开发规范与执行上下文
├── Makefile              # 常用开发命令
└── docker-compose.yml    # 开发环境服务编排
```
