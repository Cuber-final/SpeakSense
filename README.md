# SpeakSense - AI 英语口语教练

> 基于 FastAPI + Flutter 的英语口语学习应用，通过 AI 驱动的情景对话练习帮助用户提升口语能力。

## 📋 项目概述

SpeakSense 是一个跨平台的英语口语学习应用，支持用户通过情景化对话练习提升口语能力。系统提供智能评估、语音识别和个性化反馈等功能。

### 核心特性

- **情景化练习题板**: AI 生成真实生活场景的对话题目
- **多模态答题**: 支持文本输入和语音录制两种答题模式
- **智能评估**: 基于 LLM 的多维度评分（语义相关性、自然度、语法、丰富度）
- **生词本管理**: 自动提取关键词汇，支持标记和复习
- **实时反馈**: WebSocket 实时推送评估完成通知
- **多平台支持**: Web、Android、iOS

## 🗂️ 文档导航

| 文档 | 说明 |
|------|------|
| [AGENTS.md](AGENTS.md) | 项目开发计划、代码规范、里程碑进度、技术栈 |
| [Flutter 开发计划](docs/flutter-development-plan.md) | Flutter 前端详细开发计划和阶段分解 |
| [Frontend 实现细节](docs/frontend-dev-detail.md) | React 原型实现细节和组件说明 |
| [UI 原型设计规范](docs/UI-Prototype-Design-Spec.md) | UI/UX 设计系统、页面布局、交互规范 |

## 🚀 快速开始

### 环境要求

- Python 3.11+
- Flutter 3.35.0+（需要先安装 Flutter）
- Docker & Docker Compose（可选）
- Node.js 18+（用于 frontend-base 原型开发）

### 环境设置

#### 安装 Flutter（首次使用）

```bash
# macOS 推荐：通过 Homebrew 安装
brew install --cask flutter

# 验证安装
flutter --version
flutter doctor
```

详细安装指南请参考：https://docs.flutter.dev/get-started/install

#### 后端开发环境

```bash
# 进入后端目录
cd backend

# 使用 Poetry 安装依赖（含 dev）
poetry install

# 复制环境变量配置
cp .env.example .env
# 编辑 .env 设置必要的环境变量
```

### 后端开发

```bash
# 启动 API 服务（本地开发）
make api

# 启动 RQ Worker
make worker

# 运行测试
make test

# 数据库迁移
make migrate

# 代码格式化
make fmt

# 类型检查
make type
```

### 前端开发

Flutter 项目正在开发中，当前提供 React 原型参考。

```bash
# 查看前端原型（React + Vite）
cd frontend-base
npm install
npm run dev

# Flutter 项目（待创建）
cd frontend
flutter pub get
flutter run -d chrome
```

### 使用 Docker

```bash
# 启动所有服务（API, Worker, Redis, DB）
make dev

# 查看日志
docker compose logs -f api worker redis db

# 停止并清理
make dev-down
```

## 📁 项目结构

```
speaksense/
├── backend/               # FastAPI 后端（待创建）
│   ├── app/
│   │   ├── api/          # API 路由（auth, boards, practice, eval, vocab, ws）
│   │   ├── services/     # 业务逻辑（llm/, asr/, eval/, boards/）
│   │   ├── jobs/         # RQ 任务函数
│   │   ├── models/       # SQLAlchemy ORM 模型
│   │   ├── schemas/      # Pydantic 数据模型
│   │   ├── db/           # 数据库会话和迁移
│   │   ├── ws/           # WebSocket 事件
│   │   └── core/         # 核心配置（settings, security, logging, errors）
│   ├── tests/            # 测试文件
│   ├── pyproject.toml    # Poetry 依赖与工具配置（主）
│   ├── requirements.txt  # 运行依赖镜像（由 pyproject 同步）
│   ├── requirements-dev.txt # 开发依赖镜像（由 pyproject 同步）
│   └── alembic/         # 数据库迁移
├── frontend/             # Flutter 前端（待创建）
│   ├── lib/
│   │   ├── app/         # 应用入口和路由
│   │   ├── models/      # 数据模型
│   │   ├── screens/     # 页面（Home, Practice, Evaluation, Wordbook）
│   │   ├── widgets/     # 可复用组件
│   │   ├── services/    # 服务层（API, WebSocket, Audio）
│   │   └── theme/      # 主题配置
│   └── pubspec.yaml     # Flutter 依赖
├── frontend-base/         # React 原型（参考实现）
│   ├── components/       # React 组件
│   ├── pages/           # React 页面
│   └── types.ts        # TypeScript 类型定义
├── docs/                # 项目文档
│   ├── flutter-development-plan.md
│   ├── frontend-dev-detail.md
│   └── UI-Prototype-Design-Spec.md
├── .github/
│   └── workflows/
│       └── ci.yml      # CI/CD 配置
├── AGENTS.md           # 开发计划和规范
├── Makefile            # 开发命令快捷方式
├── docker-compose.yml  # 服务编排配置
└── README.md          # 本文件
```

## 🔧 技术栈

### 后端

- **框架**: FastAPI + Pydantic v2
- **数据库**: PostgreSQL + SQLAlchemy 2.0
- **迁移工具**: Alembic
- **任务队列**: RQ (Redis Queue)
- **语音识别**: faster-whisper（支持 8-bit 量化）
- **AI 评估**: OpenAI 兼容接口（支持 DeepSeek、Qwen、GLM、Kimi）
- **代码规范**: ruff, black, isort, mypy
- **测试框架**: pytest

### 前端

- **框架**: Flutter 3.35.0+（Stable Channel）
- **状态管理**: Provider
- **网络**: dio
- **UI 组件**: forui（替代部分 Material 3）
- **图表**: fl_chart
- **本地存储**: Hive, Shared Preferences
- **代码规范**: flutter analyze, dart format

### 基础设施

- **容器化**: Docker & Docker Compose
- **CI/CD**: GitHub Actions
- **API 文档**: OpenAPI (自动生成)

## 📊 开发进度

### 当前进度（2025-02-04）

- [ ] **M0 - 项目初始化**
  - [ ] 创建项目结构
  - [ ] 配置开发工具链
  - [ ] Docker Compose 配置
  - [ ] 日志和错误处理

- [ ] **M1 - 后端核心功能**
  - [ ] 用户认证（JWT）
  - [ ] 练习题板管理
  - [ ] 练习记录和答案
  - [ ] 评估任务和结果
  - [ ] 生词本功能
  - [ ] API 版本控制和限流

- [ ] **M2 - 语音与实时通信**
  - [ ] ASR 语音识别集成
  - [ ] 音频上传和处理
  - [ ] WebSocket 实时推送

- [ ] **M3 - Flutter 界面**
  - [ ] 项目初始化和 Forui 集成
  - [ ] 设计系统和主题配置
  - [ ] 场景选择页面（Home）
  - [ ] 练习页面（Practice）
  - [ ] 评估历史页面（Evaluation）
  - [ ] 生词本页面（Wordbook）
  - [ ] WebSocket 集成

- [ ] **M4 - 硬化与运维**
  - [ ] 安全头和 CSP
  - [ ] 可观测性（日志、监控）
  - [ ] 负载测试
  - [ ] CI/CD 优化

详细开发计划请查看 [AGENTS.md](AGENTS.md) 和 [Flutter 开发计划](docs/flutter-development-plan.md)。

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feat/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feat/amazing-feature`)
5. 开启 Pull Request

### 分支策略（MVP 期间）

- `master` - 稳定分支（生产代码）
- `dev` - 集成分支（日常开发）
- `feat/*` - 特性分支（从 `dev` 创建）
- `fix/*` - 修复分支（从 `dev` 创建）

### 代码规范

#### 提交消息

使用 Conventional Commits 规范：

- `feat`: 新功能
- `fix`: 修复 bug
- `chore`: 构建/工具链配置
- `docs`: 文档更新
- `refactor`: 代码重构
- `test`: 测试相关

示例：
```bash
feat: add user authentication with JWT
fix: resolve audio upload timeout issue
docs: update API documentation
```

#### 后端代码规范

- 使用类型提示（Type Hints）
- 遵循 PEP 257 文档字符串规范
- 函数命名使用 snake_case
- 运行代码检查：
  ```bash
  make fmt && make lint && make type
  ```

#### 前端代码规范

- 使用 Flutter 推荐的目录结构
- 遵循 Effective Dart 指南
- 运行代码检查：
  ```bash
  flutter analyze
  dart format .
  ```

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件至项目维护者

## 🔗 相关资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [FastAPI 官方文档](https://fastapi.tiangolo.com)
- [Forui 组件库](https://forui.dev)
- [AGENTS.md 开发计划](AGENTS.md)

---

**Made with ❤️ by SpeakSense Team**
