# Flutter Frontend Development Plan

## 概述

本文档详细说明了使用Flutter + Forui复现 `frontend-base` UI界面的开发计划。

---

## 设计理念

基于 AGENTS.md 的UI/UX Style规范：
- **设计系统**: Material 3 + Forui组件库
- **界面语言**: 中文UI
- **内容语言**: 英语
- **主题**: 支持浅色/深色模式切换
- **主色调**: 蓝色 #2962FF
- **字体**: Noto Sans SC (CJK) + Inter (Latin)
- **间距**: 4pt grid系统
- **圆角**: 8/12px
- **最小触摸目标**: 44×44
- **图标**: Material Symbols Rounded
- **动画**: 120–200ms，微妙效果
- **可访问性**: 文本缩放120%，对比度≥4.5

---

## 技术栈

### 核心
- **Flutter**: Stable channel
- **Dart**: 3.x
- **Forui**: UI组件库（替代部分Material组件）

### 状态管理
- **Provider**: 全局状态管理
- **Riverpod** (可选): 更高级的状态管理

### 网络
- **Dio**: HTTP客户端
- **WebSocket**: 实时通信

### 数据持久化
- **Hive**: 本地存储（草稿、设置）
- **Shared Preferences**: 简单键值存储

### 图表
- **fl_chart**: 雷达图和统计图表

### 其他
- **Audio Recorder**: 语音录制
- **Audio Player**: 音频播放
- **Image Picker**: 图片选择（如需要）
- **Path Provider**: 文件路径访问

---

## 项目结构

```
frontend/
  lib/
    app/
      env.dart              # 环境配置（API base URL等）
      routes.dart          # 路由定义
    models/
      scenario.dart        # Scenario模型
      vocabulary_word.dart  # VocabularyWord模型
      evaluation.dart      # EvaluationSession模型
      attempt.dart         # Attempt模型
    screens/
      home/
        home_screen.dart         # 场景选择页面
      practice/
        practice_screen.dart      # 练习页面
      evaluation/
        evaluation_list_screen.dart    # 评估历史列表
        evaluation_detail_screen.dart   # 评估详情
      wordbook/
        wordbook_screen.dart    # 生词本
    widgets/
      common/
        custom_card.dart       # 自定义卡片
        custom_button.dart     # 自定义按钮
        scenario_card.dart     # 场景卡片
        stats_widget.dart      # 统计小部件
        radar_chart.dart       # 雷达图组件
        word_item.dart         # 生词项
      navigation/
        bottom_nav.dart        # 底部导航栏
    services/
      api_service.dart        # API服务
      websocket_service.dart   # WebSocket服务
      audio_service.dart      # 音频服务
    theme/
      app_theme.dart          # 应用主题
      color_palette.dart      # 颜色调色板
      text_theme.dart        # 文本主题
      forui_theme.dart       # Forui主题配置
    utils/
      constants.dart          # 常量定义
      validators.dart         # 验证器
      formatters.dart        # 格式化器
  pubspec.yaml
  analysis_options.yaml
```

---

## 开发阶段

### Phase 1: 项目初始化 (1-2天)

**目标**: 搭建基础项目结构

**任务**:
1. [ ] 创建Flutter项目
2. [ ] 配置pubspec.yaml依赖
3. [ ] 配置Forui集成
4. [ ] 设置设计系统（颜色、字体、间距）
5. [ ] 创建基础主题（浅色/深色）
6. [ ] 配置路由结构

**验收标准**:
- 项目可正常运行
- Forui主题正确加载
- 支持深色/浅色模式切换
- 路由基础配置完成

---

### Phase 2: 导航和基础布局 (1天)

**目标**: 实现底部导航和页面容器

**任务**:
1. [ ] 创建BottomNavigationBar组件
2. [ ] 实现4个标签页：Home, Practice, Evaluation, Wordbook
3. [ ] 创建基础页面框架
4. [ ] 添加页面切换动画
5. [ ] 实现导航高亮状态

**验收标准**:
- 底部导航正常工作
- 页面切换流畅
- 当前页面高亮显示
- 深色/浅色模式下样式正确

---

### Phase 3: Home页面 - 场景选择 (2天)

**目标**: 复现场景选择界面

**任务**:
1. [ ] 创建ScenarioCard组件
   - 场景图标和渐变背景
   - 难度标签
   - 标题和描述
   - 题目数量
   - 启动按钮
2. [ ] 实现搜索框组件
3. [ ] 实现分类筛选按钮
4. [ ] 实现场景网格布局
5. [ ] 添加hover/点击动画
6. [ ] 实现锁定状态显示

**组件**:
- `ScenarioCard`: 场景卡片
- `SearchBar`: 搜索框
- `FilterChips`: 分类筛选
- `ScenarioGrid`: 场景网格

**验收标准**:
- 场景卡片样式与React版本一致
- 搜索和筛选UI正常显示
- 点击跳转到Practice页面
- 锁定场景正确显示

---

### Phase 4: Practice页面 - 练习界面 (3天)

**目标**: 复现练习页面

**任务**:
1. [ ] 实现顶部进度条和进度指示器
2. [ ] 创建TaskCard组件
   - 题目显示
   - 指导语
3. [ ] 创建ContextCard组件
   - 背景图片
   - 场景名称
   - 角色扮演说明
   - 标签（Speed, Tone）
4. [ ] 实现输入区域
   - Voice Mode指示器
   - 文本输入框（大字体）
   - 音频波形可视化
   - 字数统计
   - Redo Recording按钮
   - Submit Answer按钮
5. [ ] 集成音频录制功能
6. [ ] 实现字数验证（≤ 40词）
7. [ ] 添加草稿自动保存（Hive）

**组件**:
- `ProgressBar`: 进度条
- `TaskCard`: 任务卡片
- `ContextCard`: 上下文卡片
- `InputArea`: 输入区域
- `WaveVisualizer`: 音频波形可视化
- `WordCounter`: 字数统计

**验收标准**:
- 页面布局与React版本一致
- 音频录制功能正常
- 字数验证正确
- 草稿自动保存
- Submit跳转到EvaluationDetail

---

### Phase 5: EvaluationList页面 - 评估历史 (2天)

**目标**: 复现评估历史列表

**任务**:
1. [ ] 创建StatsWidget组件
   - Overall Performance
   - Total Sessions
   - Global Avg. Score
2. [ ] 实现评估历史列表
   - 评估项卡片
   - 场景图标和标题
   - 日期时间
   - Fluency和Avg Score
   - View Detail按钮
3. [ ] 实现筛选和排序UI（占位）
4. [ ] 创建TipBanner组件
5. [ ] 实现Load More功能

**组件**:
- `StatsWidget`: 统计小部件
- `EvaluationItem`: 评估历史项
- `TipBanner`: 提示横幅
- `FilterSortBar`: 筛选排序栏

**验收标准**:
- 统计小部件正确显示
- 评估历史列表样式一致
- 点击跳转到EvaluationDetail
- 提示横幅显示

---

### Phase 6: EvaluationDetail页面 - 评估详情 (3天)

**目标**: 复现评估详情页面

**任务**:
1. [ ] 实现深色主题布局
2. [ ] 创建OverallScoreCard组件
   - 圆环进度条（SVG或CustomPaint）
   - 评分显示
   - 等级标签
   - 评语
3. [ ] 使用fl_chart实现RadarChart
   - Naturalness, Richness, Grammar, Relevance
   - 交互式效果
4. [ ] 创建KeyMetrics组件
   - Duration
   - Pace
   - Vocabulary Level
5. [ ] 实现Question Breakdown
   - 问题卡片（展开/收起）
   - 用户答案展示
   - 音频播放器
   - 评分细项进度条
   - AI Feedback
   - Suggested Answers（可复制）
6. [ ] 添加导出和分享功能（占位）

**组件**:
- `OverallScoreCard`: 总体评分卡片
- `RadarChartWidget`: 雷达图
- `KeyMetricsStack`: 关键指标
- `QuestionBreakdown`: 问题细分
- `AudioPlayer`: 音频播放器
- `ScoreProgressBar`: 评分进度条
- `SuggestedAnswers`: 建议答案

**验收标准**:
- 深色主题正确
- 雷达图正常显示和交互
- 问题展开/收起功能正常
- 音频播放器功能正常
- 建议答案可复制

---

### Phase 7: Wordbook页面 - 生词本 (2天)

**目标**: 复现生词本

**任务**:
1. [ ] 实现搜索框
2. [ ] 实现Filter和Sort按钮
3. [ ] 创建FilterChips组件
   - All Levels
   - A1-A2, B1-B2, C1-C2
   - Mastered, To Review
4. [ ] 创建WordItem组件
   - 状态图标
   - 单词和音标
   - 词性和等级标签
   - 中文翻译
   - 来源信息
   - 复选框
5. [ ] 实现单词发音播放
6. [ ] 实现Load More功能

**组件**:
- `WordItem`: 生词项
- `FilterChip`: 筛选标签
- `WordList`: 生词列表

**验收标准**:
- 筛选功能正常
- 生词列表样式一致
- 发音播放功能正常
- 复选框标记状态正确

---

### Phase 8: 网络集成和数据绑定 (2天)

**目标**: 连接后端API

**任务**:
1. [ ] 创建Dio配置
2. [ ] 与后端冻结 MVP 字段契约（先对齐 `docs/evaluation-detail-contract.md`）
3. [ ] 实现API Service
   - 获取场景列表
   - 获取评估历史
   - 获取评估详情
   - 获取生词列表
   - 提交答案
   - 上传音频
4. [ ] 实现WebSocket Service
   - 连接管理
   - 订阅评估完成事件
   - 显示"评估完成"Banner
5. [ ] 实现错误处理和重试逻辑
6. [ ] 添加加载状态和骨架屏

**服务**:
- `ApiService`: API服务
- `WebSocketService`: WebSocket服务
- `NetworkInterceptor`: 网络拦截器

**验收标准**:
- API调用正常
- WebSocket连接稳定
- 错误处理完善
- 加载状态正确

---

### Phase 9: WebSocket实时更新 (1天)

**目标**: 实现实时评估完成通知

**任务**:
1. [ ] 实现WebSocket连接管理
2. [ ] 订阅`evaluation.completed`事件
3. [ ] 实现Banner通知组件
4. [ ] 点击Banner跳转到EvaluationDetail
5. [ ] 断线重连逻辑

**组件**:
- `EvaluationBanner`: 评估完成横幅
- `WebSocketManager`: WebSocket管理器

**验收标准**:
- WebSocket连接稳定
- 评估完成时显示Banner
- 点击正确跳转
- 断线自动重连

---

### Phase 10: 深色模式和主题切换 (1天)

**目标**: 完善主题系统

**任务**:
1. [ ] 实现主题切换按钮
2. [ ] 完善深色模式样式
3. [ ] 添加主题持久化（Shared Preferences）
4. [ ] 确保所有组件支持深色模式
5. [ ] 添加主题切换动画

**验收标准**:
- 深色/浅色模式切换流畅
- 所有页面样式正确
- 主题设置持久化

---

### Phase 11: 测试和优化 (2天)

**目标**: 确保质量和性能

**任务**:
1. [ ] 编写Widget测试
2. [ ] 性能优化
   - 列表懒加载
   - 图片缓存
   - 内存优化
3. [ ] 动画优化
4. [ ] 用户体验优化
   - 加载状态
   - 错误提示
   - 空状态
5. [ ] 跨平台测试
   - Web
   - Android
   - iOS

**验收标准**:
- 测试覆盖率>70%
- 性能指标达标
- 无明显bug
- 跨平台表现一致

---

## 组件映射表（React → Flutter + Forui）

| React组件 | Flutter + Forui组件 |
|---------|-------------------|
| Button | FButton / ElevatedButton |
| TextField | FTextField / TextField |
| Card | FCard / Card |
| ListTile | FItem / FItemGroup / ListTile |
| Snackbar | showFToast / SnackBar |
| AlertDialog | showFDialog / AlertDialog |
| BottomNavigationBar | FBottomNavigationBar |
| NavigationBar | FBottomNavigationBar |
| SearchBar | FTextField + prefixIcon |
| FilterChip | ChoiceChip / FilterChip |
| Badge | FBadge / Badge |
| Progress | LinearProgressIndicator |
| Circular Progress | CircularProgressIndicator |
| Slider | Slider |

---

## Forui 固定外观与回退说明

- 当前 App 已固定使用 Forui 主题（不再提供运行时切换入口）。
- Material 主题仍通过 `toApproximateMaterialTheme()` 保留近似映射，用于潜在回退或调试。
- 如需临时降级：在 `frontend/lib/app/app.dart` 中替换为 `AppTheme.lightTheme / AppTheme.darkTheme`。

---

## Evaluation Detail API Contract（Draft）

> 该契约用于约束后端字段，避免后续前端大改。

### Endpoint
```
GET /v1/attempts/{attempt_id}/evaluation
```

兼容候选：
```
GET /v1/evaluations/{attempt_id}
```

### Success Response (示例)
```json
{
  "data": {
    "id": "att_123",
    "scenario_title": "Coffee Shop Ordering",
    "overall_score": 3.5,
    "level": "Intermediate High",
    "summary": "Great job! You are clearly understood by native speakers in most contexts.",
    "dimensions": [
      { "label": "Naturalness", "score": 4.5 },
      { "label": "Richness", "score": 4.2 },
      { "label": "Grammar", "score": 3.8 },
      { "label": "Relevance", "score": 4.0 }
    ],
    "metrics": [
      { "key": "duration", "label": "Duration", "value": "14m 32s" },
      { "key": "pace", "label": "Pace", "value": "115 wpm" },
      { "key": "vocabulary", "label": "Vocabulary", "value": "B2 Level" }
    ],
    "questions": [
      {
        "question": "How would you order a latte with oat milk?",
        "answer": "Can I get a latte? ...",
        "feedback": "Clear request, but \"oat milk inside\" sounds unnatural.",
        "suggested_answer": "Could I get a hot latte with oat milk, please?",
        "audio_url": "https://.../audio.wav",
        "dimensions": [
          { "label": "Relevance", "score": 4.8 },
          { "label": "Naturalness", "score": 2.5 },
          { "label": "Grammar", "score": 3.8 },
          { "label": "Richness", "score": 3.2 }
        ]
      }
    ]
  }
}
```

### 最小字段说明
- `id` (string) 评估/attempt ID
- `scenario_title` (string) 场景标题
- `overall_score` (number) 总分 (0–5)
- `level` (string) 等级描述
- `summary` (string) 总结
- `dimensions[]` (label/score)
- `metrics[]` (key/label/value)
- `questions[]` (question/answer/feedback/suggested_answer/audio_url/dimensions)

### 错误响应
遵循 Problem JSON：
```json
{
  "error": {
    "type": "validation_error",
    "code": "EVAL_NOT_FOUND",
    "message": "Evaluation not found",
    "details": { "attempt_id": "att_123" }
  }
}
```

---

## 后端联调前置（新增）

- LLM/VLM 抽象层调研与落地草案：`docs/llm-vlm-adapter-research.md`
- 建议后端先完成统一 provider 抽象（含 OpenAI compatible/Ollama/vLLM）再推进前端 API 实连。
- 前后端字段对齐顺序：
  1. 先冻结评估详情契约（`docs/evaluation-detail-contract.md`）
  2. 再接入 Practice 语音上传与 WS 实时事件
  3. 最后收敛错误码与 Problem JSON 映射

---

## 设计令牌映射

### 颜色
```dart
class AppColors {
  // Primary
  static const primary = Color(0xFF2962FF);
  static const primaryLight = Color(0xFF5C92FF);
  static const primaryDark = Color(0xFF0039CB);

  // Background
  static const backgroundLight = Color(0xFFFFFFFF);
  static const backgroundDark = Color(0xFF0F1423);

  // Surface
  static const surfaceDark = Color(0xFF151922);
  static const surfaceBorder = Color(0xFF1F2937);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Text
  static const textLight = Color(0xFF0F172A);
  static const textDark = Color(0xFFF9FAFB);
  static const textSecondary = Color(0xFF64748B);
}
```

### 间距
```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

### 圆角
```dart
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 9999.0;
}
```

### 字体大小
```dart
class AppFontSize {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double base = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 30.0;
}
```

---

## 优先级和依赖关系

```
Phase 1 (基础) → Phase 2 (导航) → Phase 3-7 (页面)
                                              ↓
                                    Phase 8 (API集成)
                                              ↓
                                    Phase 9 (WebSocket)
                                              ↓
                                    Phase 10 (主题)
                                              ↓
                                    Phase 11 (测试)
```

---

## 风险和缓解措施

### 风险1: Forui集成问题
**缓解**: 逐步迁移，保留Material作为fallback

### 风险2: 图表库兼容性
**缓解**: 提前测试fl_chart，准备备选方案

### 风险3: WebSocket稳定性
**缓解**: 实现断线重连和心跳机制

### 风险4: 跨平台兼容性
**缓解**: 优先Web开发，测试Android/iOS

---

## 交付标准

1. 所有页面UI与React版本一致
2. 支持深色/浅色模式切换
3. WebSocket实时通知功能正常
4. API集成完成，数据正确展示
5. 测试覆盖率>70%
6. 性能达标（首屏≤1.5s）
7. 代码通过lint和format检查

---

## 参考资料

- AGENTS.md - 项目规范和UI/UX风格
- docs/frontend-dev-detail.md - React实现细节
- Flutter官方文档
- Forui文档
- fl_chart文档
