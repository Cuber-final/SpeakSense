# SpeakSense 项目路线图（Roadmap）

最后更新: 2026-02-08  
范围: MVP 开发阶段（`dev` 分支）

---

## 文档定位

本文件是项目里程碑状态的唯一真相源（source of truth），用于回答“当前做到哪一步、下一步做什么”。

- 后端详细实现记录: `docs/backend-development-progress.md`
- 前端详细实现记录: `docs/flutter-development-progress.md`
- 开发规范与执行约束: `AGENTS.md`

---

## 里程碑总览

状态说明: `pending` / `in_progress` / `done`

| Milestone | 状态 | 说明 |
|---|---|---|
| M0 项目初始化 | done | 基础工程、工具链、健康检查与错误处理框架已可运行 |
| M1 后端核心 | in_progress | 认证、boards/practice/evaluation/wordbook 主链路已落地，正在做联调收口 |
| M2 语音与实时 | in_progress | 语音上传/ASR 删除策略与 WS 事件已具备，待补真实 e2e 边界验证 |
| M3 Flutter Shell 与 UX | in_progress | 主页面、Mock/API 切换、Forui 迁移、Radar 图与语音交互已完成大部分 |
| M4 硬化与运维 | pending | 安全头、观测性、性能压测、CI/CD 强化待执行 |
| M5 增强能力 | pending | pgvector、TTS、AB 测试与成本追踪（MVP 后） |

---

## 当前阶段结论

- 前端已具备完整演示闭环，可继续联调真实后端接口。
- 后端已完成 MVP 主链路与真实 LLM provider smoke 联通。
- 当前优先级已经从“能力搭建”转入“生产收口与回归测试”。

---

## 下一步优先级（执行顺序）

1. LLM provider 矩阵联调（OpenAI-compatible / vLLM / Ollama）与超时、重试回归测试。
2. `Idempotency-Key` 与限流收口为 Redis-only 生产模式（关闭内存回退）。
3. `POST /v1/answers/voice` 的真实 `faster-whisper` e2e 与大文件边界测试。
4. boards/questions 引入版本号与再生成机制（支持刷新与差异追踪）。

---

## 维护规则

- 根目录 `README.md` 只保留项目概要、技术栈、快速启动和文档入口。
- `AGENTS.md` 只保留开发约束、标准与命令，不做日常进度打勾。
- 每次阶段性里程碑变更时，优先更新本文件，再更新对应后端/前端详细进度文件。
