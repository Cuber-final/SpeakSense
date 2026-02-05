# Flutter 开发进度

最后更新: 2026-02-05
项目: SpeakSense AI English Coach (Flutter)

---

## 当前里程碑状态

### Phase 1 - 项目初始化
- [x] Flutter 项目可运行
- [x] 基础主题接线（light/dark）
- [x] 迁移执行路线文档：`docs/flutter-migration-execution-route.md`

### Phase 2 - 导航与应用外壳
- [x] 响应式外壳（桌面侧栏 + 移动底部导航）
- [x] 四主页面接线（Home / Practice / Evaluation / Wordbook）

### Phase 3 - Home 页面
- [x] 搜索框与分类筛选
- [x] 场景卡片网格
- [x] 锁定态（Premium / Locked）
- [x] 点击可跳转到 Practice

### Phase 4 - Practice 页面
- [x] 顶部进度区（Question / Progress）
- [x] Task Card + Context Card
- [x] 输入区、波形模拟、词数统计
- [x] Submit 跳转到 EvaluationDetail

### Phase 5 - EvaluationList 页面
- [x] 统计卡片（3个）
- [x] 历史列表项
- [x] Tip Banner

### Phase 6 - EvaluationDetail 页面
- [x] 深色详情页
- [x] Overall Score 区块
- [x] 维度分数区块
- [x] Question Breakdown 区块

### Phase 7 - Wordbook 页面
- [x] 搜索与状态筛选
- [x] 单词列表与状态展示

---

## 已完成的迁移步骤（按执行路线）

- [x] Step 1: 方案与骨架
- [x] Step 2: 应用外壳与导航
- [x] Step 3: 核心页面迁移（第一批）
- [x] Step 4: 核心页面迁移（第二批）
- [x] Step 5: 数据层与验收（Mock + analyze + run）
- [x] Step 6: API 数据源接线（Dio + 开发者 Mock/API 切换）
- [x] Step 7: Realtime 通知（`/ws/events` + evaluation.completed Banner）
- [x] Step 8: Practice 语音上传与 ASR 预览编辑（`/v1/answers/voice`）

---

## 本次新增代码（Flutter）

- `frontend/lib/app/app.dart`
- `frontend/lib/app/app_shell.dart`
- `frontend/lib/app/app_state.dart`
- `frontend/lib/app/env.dart`
- `frontend/lib/data/mock_data.dart`
- `frontend/lib/models/scenario.dart`
- `frontend/lib/models/evaluation_session.dart`
- `frontend/lib/models/vocabulary_word.dart`
- `frontend/lib/screens/home/home_screen.dart`
- `frontend/lib/screens/practice/practice_screen.dart`
- `frontend/lib/screens/evaluation/evaluation_list_screen.dart`
- `frontend/lib/screens/evaluation/evaluation_detail_screen.dart`
- `frontend/lib/screens/wordbook/wordbook_screen.dart`
- `frontend/lib/services/api_service.dart`
- `frontend/lib/services/content_repository.dart`
- `frontend/lib/services/websocket_service.dart`
- `frontend/lib/widgets/data_source_banner.dart`
- `frontend/lib/widgets/scenario_card.dart`
- `frontend/lib/utils/material_icon_mapper.dart`
- `frontend/assets/fonts/inter/Inter-Variable.ttf`
- `frontend/assets/fonts/inter/Inter-Italic-Variable.ttf`
- `frontend/assets/fonts/noto_sans_sc/NotoSansSC-Variable.ttf`

---

## 验证记录

- [x] `cd frontend && flutter analyze`
- [x] `cd frontend && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8787`
- [x] `cd frontend && flutter run -d chrome --no-web-resources-cdn`
- [x] `cd frontend && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8787 --no-web-resources-cdn --dart-define=USE_MOCK_API=true`

---

## 下一阶段（M3 后续）

- [x] 记录 Flutter Web 外网依赖与替代路线：`docs/flutter-web-external-resources.md`
- [x] 完成本地字体替换（Inter + Noto Sans SC，assets 打包）
- [x] 将 Web 启动参数固化到 `Makefile`（`--no-web-resources-cdn`）
- [x] 接入 API Service（Dio）替换 Mock 数据源
- [x] 开发者菜单新增 Mock/API 开关（默认 Mock）
- [x] 接入 `/ws/events` 并展示“评估完成”Banner
- [x] Banner 点击后导航至 Evaluation，并支持详情跳转
- [x] Practice 语音上传 `/v1/answers/voice` 与 ASR 预览编辑
- [x] 语音上传增强：格式/大小/时长校验、进度、取消与重试
- [x] Practice 新增“点击说话（Mock）”录音按钮与模拟识别闭环（演示用）
- [~] 页面骨架态/空态与错误态打磨（Home/Evaluation/Wordbook 已接入）
- [ ] 组件迁移到 Forui（按 M3 Forui 计划）
