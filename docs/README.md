# 项目文档

本文档目录包含 SpeakSense 项目的所有设计规范、技术文档和开发指南。

## 📚 文档列表

| 文档 | 说明 | 最后更新 |
|------|------|----------|
| [项目路线图](project-roadmap.md) | 项目里程碑状态唯一总览（source of truth） | 2026-02-09 |
| [UI 原型设计规范](UI-Prototype-Design-Spec.md) | UI/UX 设计系统、页面布局、交互规范 | 2025-02-03 |
| [前端开发细则](frontend-dev-detail.md) | 页面功能、交互流程与实现约束 | 2025-02-04 |
| [Flutter 开发计划](flutter-development-plan.md) | Flutter 分阶段开发路线与契约草案 | 2026-02-06 |
| [Flutter 开发进度](flutter-development-progress.md) | 已完成事项与验证记录 | 2026-02-06 |
| [Flutter 迁移执行路线](flutter-migration-execution-route.md) | 从 `frontend-base` 迁移到现有 Flutter 工程的步骤 | 2026-02-05 |
| [Evaluation Detail 字段契约](evaluation-detail-contract.md) | 前后端联调字段最小契约（MVP） | 2026-02-06 |
| [Flutter Web 外网资源依赖记录](flutter-web-external-resources.md) | Flutter Web 启动依赖的外网 CDN、规避方案与替代路线 | 2026-02-05 |
| [LLM/VLM 抽象层调研与落地草案](llm-vlm-adapter-research.md) | 后端模型网关设计、能力矩阵与实施顺序 | 2026-02-07 |
| [Backend 开发进度](backend-development-progress.md) | 后端里程碑完成情况与下一步实施建议（含 ASR provider 网关化） | 2026-02-09 |

## 📖 文档说明

### UI 原型设计规范

本文档详细描述了 SpeakSense 应用的界面设计规范，包括：

- **设计系统**: 色彩、排版、间距、圆角、阴影等基础设计元素
- **核心页面**: 首页、题板详情、练习页、评估页、生词本页的布局结构
- **交互设计**: 动画过渡、加载状态、错误处理等交互细节
- **响应式设计**: 移动端、平板、桌面的适配方案
- **无障碍设计**: 对比度、触控、屏幕阅读器支持

适用人群：UI/UX 设计师、前端开发、产品经理

---

## 🤝 贡献文档

如需添加或更新文档，请遵循以下规范：

1. 文档命名使用英文，使用 kebab-case 格式（如 `api-design-spec.md`）
2. 在本文档中添加文档条目和简短说明
3. 在文档开头添加文档版本、更新日期、作者信息
4. 使用 Markdown 格式编写，保持格式统一

---

**最后更新**: 2026-02-09
