# Flutter Migration Execution Route

最后更新: 2026-02-05
目标: 基于 `frontend-base` 的 React 原型，迁移为可运行的 Flutter 前端工程。

---

## 迁移原则

- 先可运行，再精修视觉，再接入真实 API。
- 保持信息架构一致：Home / Practice / Evaluation / Wordbook。
- 先 Mock 数据闭环，再做网络层替换。
- 每完成一步，同步更新 `docs/flutter-development-progress.md`。

---

## 执行路线（可勾选）

### Step 1 - 方案与骨架
- [x] 明确页面映射与组件映射（React -> Flutter）
- [x] 定义 Flutter 目录结构（app/models/screens/widgets）
- [x] 产出迁移执行路线文档（本文档）

### Step 2 - 应用外壳与导航
- [x] 建立 `MaterialApp` 入口与主题接线
- [x] 实现响应式导航容器（桌面侧栏 + 移动底部导航）
- [x] 接入四主页面路由与切换状态

### Step 3 - 核心页面迁移（第一批）
- [x] Home：搜索、分类、场景卡片网格、锁定态
- [x] Practice：进度、任务卡、上下文卡、输入区、提交动作

### Step 4 - 核心页面迁移（第二批）
- [x] EvaluationList：统计卡、历史列表、提示横幅
- [x] EvaluationDetail：深色详情页、评分区、维度区、拆题区
- [x] Wordbook：搜索、筛选标签、单词列表、状态项

### Step 5 - 数据层与验收
- [x] 抽离 Mock 数据（模型 + data source）
- [x] `flutter analyze` 通过
- [x] `flutter run -d web-server` 可启动并稳定访问
- [x] 更新进度文档与下一阶段任务（API/WS 接入）

### Step 6 - API 数据源接线（高优先级）
- [x] 新增 `Dio` API 服务层（boards / attempts / wordbook）
- [x] 新增 Repository（API 失败自动回退 Mock）
- [x] 新增开发者菜单（Mock/API 切换，默认 Mock）
- [x] Home / Evaluation / Wordbook 接入异步加载、空态和刷新
- [x] `flutter analyze` 与 `flutter run -d web-server` 启动验证通过

### Step 7 - Realtime 通知（高优先级）
- [x] 新增 WebSocket 服务（`/ws/events` 连接与重连）
- [x] 订阅 `evaluation.completed` 事件
- [x] 顶部 Banner 提示“评估完成”
- [x] 点击 Banner 跳转 Evaluation（存在 `attempt_id` 时直达详情）
- [x] 调试菜单新增“模拟 evaluation.completed”用于联调

### Step 8 - Practice 语音上传与 ASR 预览（高优先级）
- [x] 接入 `/v1/answers/voice` Multipart 上传（Dio）
- [x] Practice 页新增“选择并上传音频”交互
- [x] 返回 transcript 后支持在线编辑和“一键应用到答案”
- [x] 支持 Mock / API 双模式（便于无后端联调）
- [x] 增加格式/大小/时长前置校验、上传进度、取消与失败重试
- [x] 新增“点击说话（Mock）”录音按钮（模拟识别结果用于演示）

---

## 页面映射清单

- `frontend-base/pages/Home.tsx` -> `frontend/lib/screens/home/home_screen.dart`
- `frontend-base/pages/Practice.tsx` -> `frontend/lib/screens/practice/practice_screen.dart`
- `frontend-base/pages/EvaluationList.tsx` -> `frontend/lib/screens/evaluation/evaluation_list_screen.dart`
- `frontend-base/pages/EvaluationDetail.tsx` -> `frontend/lib/screens/evaluation/evaluation_detail_screen.dart`
- `frontend-base/pages/Wordbook.tsx` -> `frontend/lib/screens/wordbook/wordbook_screen.dart`
