# SpeakSense - AI 英语口语教练

> 基于 FastAPI + Flutter 的英语口语学习应用，通过 AI 驱动的情景对话练习帮助用户提升口语能力。

## 📋 项目概述

SpeakSense 是一个跨平台的英语口语学习应用，支持用户通过情景化对话练习提升口语能力。系统提供智能评估、语音识别和个性化反馈等功能。

### 核心特性

- **情景化练习题板**: AI 生成真实生活场景的对话题目
- **多模态答题**: 支持文本输入和语音录制两种答题模式
- **智能评估**: 基于 LLM 的多维度评分（语义相关性、自然度、语法、丰富度）
- **生词本管理**: 自动提取关键词汇，支持标记和复习
- **多平台支持**: Web、Android、iOS、macOS、Windows、Linux

## 🗂️ 文档导航

| 文档 | 说明 |
|------|------|
| [AGENTS.md](AGENTS.md) | 项目开发计划、代码规范、里程碑进度 |
| [UI 原型设计规范](docs/UI-Prototype-Design-Spec.md) | UI/UX 设计系统、页面布局、交互规范 |

## 🚀 快速开始

### 环境要求

- Python 3.11+
- Flutter 3.35.0+
- Docker & Docker Compose（可选）

### 后端开发

```bash
# 创建虚拟环境
python3.11 -m venv .venv
source .venv/bin/activate

# 安装依赖
pip install -r backend/requirements.txt

# 启动 API 服务
make api

# 启动 RQ Worker
make worker

# 运行测试
make test
```

### 前端开发

```bash
cd frontend

# 安装依赖
flutter pub get

# 启动 Web 版本
flutter run -d chrome

# 启动 Android 版本
flutter run -d android

# 启动 iOS 版本
flutter run -d ios
```

### 使用 Docker

```bash
# 启动所有服务
make dev

# 查看日志
docker compose logs -f api worker redis db

# 停止并清理
make dev-down
```

## 📁 项目结构

```
speaksense/
├── backend/           # FastAPI 后端
│   ├── app/
│   │   ├── api/      # API 路由
│   │   ├── models/   # SQLAlchemy 模型
│   │   ├── schemas/  # Pydantic 数据模型
│   │   ├── services/ # 业务逻辑
│   │   ├── jobs/     # RQ 任务
│   │   └── core/     # 核心配置
│   ├── tests/        # 测试文件
│   └── alembic/     # 数据库迁移
├── frontend/         # Flutter 前端
│   ├── lib/
│   │   ├── features/ # 功能模块
│   │   ├── theme/    # 主题配置
│   │   └── app/      # 应用入口
│   └── test/         # 测试文件
├── docs/             # 项目文档
├── infra/            # 基础设施配置
└── docker-compose.yml # 服务编排
```

## 🔧 技术栈

### 后端

- **框架**: FastAPI + Pydantic v2
- **数据库**: PostgreSQL + SQLAlchemy 2.0
- **任务队列**: RQ + Redis
- **语音识别**: faster-whisper（本地部署）
- **AI 评估**: OpenAI 兼容接口（支持 DeepSeek、Qwen、GLM、Kimi）

### 前端

- **框架**: Flutter 3.35.0+
- **状态管理**: Riverpod
- **路由**: go_router
- **网络**: dio
- **UI 组件**: forui
- **图表**: fl_chart

## 📊 开发进度

- [x] M0: 项目初始化
- [x] M1: 后端核心功能
- [x] M2: 语音与实时通信
- [ ] M3: Flutter 界面（进行中）
- [ ] M4: 硬化与运维

详细进度请查看 [AGENTS.md](AGENTS.md)。

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feat/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feat/amazing-feature`)
5. 开启 Pull Request

请遵循项目代码规范：
- 后端: `ruff`, `black`, `isort`, `mypy`
- 前端: `flutter analyze`, `dart format`

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件至项目维护者

---

**Made with ❤️ by SpeakSense Team**
