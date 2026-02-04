# Frontend Development Detail

本文档记录了 `frontend-base` 目录下现有实现的详细内容，便于后续Flutter开发参考。

---

## 技术栈

- **前端框架**: React 19.2.4
- **路由**: React Router DOM 7.13.0
- **构建工具**: Vite 6.2.0
- **语言**: TypeScript 5.8.2
- **图表库**: Recharts 3.7.0
- **样式**: Tailwind CSS

---

## 页面结构

### 1. App.tsx
- 使用 HashRouter 进行路由管理
- 布局：左侧固定 Sidebar + 右侧主内容区
- 路由配置：
  - `/` → Home（场景选择页面）
  - `/practice` → Practice（练习页面）
  - `/evaluation` → EvaluationList（评估历史列表）
  - `/evaluation/:id` → EvaluationDetail（评估详情）
  - `/wordbook` → Wordbook（生词本）

---

### 2. Sidebar（侧边导航栏）

**功能**：
- 显示应用Logo和名称 "SpeakSense AI English Coach"
- 导航菜单（Home, Practice, Evaluation, Wordbook）
- 用户头像和订阅信息显示
- 当前页面高亮显示

**样式特点**：
- 固定宽度（w-64）
- 白色背景，深色模式适配
- 导航项激活状态使用主题色（primary）高亮
- 使用 Material Symbols Rounded 图标

---

### 3. Home（场景选择页面）

**功能**：
- 搜索框：搜索练习场景
- 分类筛选：All Scenarios, Business, Travel, Daily Life, Academic, Social
- 场景卡片网格展示
- 场景信息：
  - 标题、描述
  - 难度等级（A1-C2）
  - 题目数量
  - 分类
  - 图标和颜色主题

**Mock数据**：
- Coffee Shop Ordering（A2, Daily Life, 10题）
- Job Interview Prep（C1, Business, 15题）
- Airport Check-in（B1, Travel, 8题）
- Daily Standup（B2, Business, 12题）
- Ordering at a Restaurant（A1, Daily Life, 6题）
- Doctor's Appointment（B1, Daily Life, 0题，Premium锁定）

**交互**：
- 卡片hover效果（阴影、图标缩放）
- 点击卡片跳转到Practice页面
- 锁定场景显示"Premium"和"Locked"按钮

---

### 4. Practice（练习页面）

**功能**：
- 顶部进度条显示当前题目进度（Question 1 / 10, 10% Complete）
- 左侧列：
  - **Task Card（任务卡片）**：
    - 显示题目："What would you like to drink today?"
    - 指导语："Respond politely to the barista's question."
  - **Context Card（上下文卡片）**：
    - 场景背景图片
    - 场景名称："Busy Downtown Cafe"
    - 角色扮演说明
    - 标签：Speed: Fast, Tone: Polite

- 右侧列：
  - **Input Area（输入区域）**：
    - 顶部显示"Voice Mode Active"和"Auto-save on"
    - 文本输入框（大字体，多行）
    - 音频波形可视化模拟
    - 字数统计（36/40 words）
    - 按钮："Redo Recording", "Submit Answer"

**交互**：
- 输入框支持文本输入
- 波形动画模拟音频录制
- 字数超限警告（40词上限）
- Submit Answer 跳转到 EvaluationDetail

---

### 5. EvaluationList（评估历史列表）

**功能**：
- 统计小部件（Stats Widgets）：
  - Overall Performance（76%）
  - Total Sessions（24）
  - Global Avg. Score（3.8/5.0）

- 评估历史列表：
  - 场景图标和标题
  - 日期时间
  - Fluency分数
  - Avg. Score分数
  - "View Detail"按钮

- 提示横幅：每日学习建议

**Mock数据**：
- Coffee Shop Ordering（Oct 24, 2023, Fluency: 4.0, Avg: 3.5）
- Job Interview Prep（Oct 22, 2023, Fluency: 4.5, Avg: 4.2）
- Airport Check-in（Oct 19, 2023, Fluency: 2.8, Avg: 3.0）
- Restaurant Reservation（Oct 15, 2023, Fluency: 4.8, Avg: 4.6）

**交互**：
- 列表项hover效果
- 点击跳转到 EvaluationDetail 页面
- 筛选和排序按钮（UI占位）

---

### 6. EvaluationDetail（评估详情页面）

**功能**：
- 深色主题设计（#0f1423背景）

**顶部区域**：
- 返回按钮
- 标题："Coffee Shop Ordering - Evaluation"
- 导出PDF和分享按钮

**主要区域**：
1. **Overall Score Card（总体评分卡片）**：
   - 圆环进度条（SVG）
   - 评分：3.5/5.0
   - 等级："Intermediate High"
   - 评语

2. **Radar Chart（雷达图）**：
   - 使用 Recharts 库
   - 维度：Naturalness, Richness, Grammar, Relevance
   - 交互式悬停效果

3. **Key Metrics Stack（关键指标）**：
   - Duration: 14m 32s
   - Pace: 115 wpm
   - Vocabulary: B2 Level

**Question Breakdown（问题细分）**：
- 展开式问题卡片
- 左侧：
  - 用户答案展示（带引用样式）
  - 音频播放器（进度条、播放按钮、时间显示）
- 右侧：
  - 评分细项（Relevance, Naturalness, Grammar, Richness）
  - 进度条可视化
- 底部：
  - AI Feedback反馈
  - Suggested Answers（建议答案，可复制）

**交互**：
- 问题卡片展开/收起
- 音频播放控制
- 建议答案复制功能

---

### 7. Wordbook（生词本）

**功能**：
- 搜索框：搜索已保存的单词
- 筛选和排序按钮
- 标签页筛选：
  - All Levels
  - A1-A2（Beginner）
  - B1-B2（Intermediate）
  - C1-C2（Advanced）
  - Mastered
  - To Review

- 单词列表卡片：
  - 状态图标（Mastered / Reviewing）
  - 单词和音标
  - 词性和等级标签
  - 中文翻译
  - 来源信息
  - 复选框标记状态

**Mock数据**：
- Latte（/ˈlɑːteɪ/, n., A2, Mastered）
- Paradigm（/ˈpærədaɪm/, n., C1, Reviewing）
- Resilience（/rɪˈzɪliəns/, n., B2, Reviewing）
- Eloquent（/ˈeləkwənt/, adj., C1, Mastered）

**交互**：
- 搜索功能
- 筛选标签切换
- 单词播放发音
- 复选框标记掌握状态
- Load More 按钮

---

## 数据模型

### Scenario
```typescript
interface Scenario {
  id: string;
  title: string;
  description: string;
  level: 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2';
  category: 'Business' | 'Travel' | 'Daily Life' | 'Academic' | 'Social';
  questionCount: number;
  icon: string;
  color: string;
  image?: string;
}
```

### VocabularyWord
```typescript
interface VocabularyWord {
  id: string;
  word: string;
  phonetic: string;
  partOfSpeech: string;
  level: string;
  levelColor: string;
  translation: string;
  source: string;
  status: 'Mastered' | 'Reviewing' | 'New';
}
```

### EvaluationSession
```typescript
interface EvaluationSession {
  id: string;
  scenarioTitle: string;
  date: string;
  fluency: number;
  avgScore: number;
  icon: string;
  color: string;
}
```

### RadarData
```typescript
interface RadarData {
  subject: string;
  A: number;
  fullMark: number;
}
```

---

## 设计系统

### 颜色
- Primary: #2962FF（蓝色）
- Background Light: #FFFFFF
- Background Dark: #0f1423
- Surface Dark: #151922
- Surface Border: #1f2937
- Success: #10b981
- Warning: #f59e0b

### 字体
- Font family: system-ui, -apple-system, sans-serif
- 字重：bold, semibold, medium, normal
- 字号：xs(12px), sm(14px), base(16px), lg(18px), xl(20px), 2xl(24px), 3xl(30px), 4xl(36px)

### 间距
- 4pt grid系统
- Padding: p-2(8px), p-4(16px), p-6(24px), p-8(32px)
- Gap: gap-2(8px), gap-3(12px), gap-4(16px), gap-6(24px)

### 圆角
- rounded-lg: 8px
- rounded-xl: 12px
- rounded-2xl: 16px
- rounded-full: 完全圆角

### 阴影
- shadow-sm: 轻微阴影
- shadow-md: 中等阴影
- shadow-lg: 大阴影
- shadow-primary/20: 主题色半透明阴影

### 动画
- transition-all: 所有属性过渡
- duration-200/300: 过渡时间
- hover:scale-110: 悬停缩放
- animate-pulse: 脉冲动画

---

## 图标系统

使用 Material Symbols Rounded 图标库，常用图标：
- 导航: home, mic, analytics, menu_book
- 操作: search, notifications, add, download, share
- 状态: check_circle, pending, lock, trending_up
- 交互: play_arrow, replay, send, volume_up

---

## 响应式设计

- 移动端优先
- 断点：sm(640px), md(768px), lg(1024px), xl(1280px)
- Flexbox和Grid布局
- 隐藏/显示元素根据屏幕尺寸

---

## 待迁移的交互功能

1. **路由导航**：需要使用Flutter的导航系统实现
2. **状态管理**：需要使用Provider或Riverpod管理全局状态
3. **表单验证**：字数限制、输入验证
4. **动画**：页面转场、hover效果、波纹效果
5. **图表**：雷达图需要使用Flutter图表库（fl_chart）
6. **音频**：录音、播放功能
7. **实时更新**：WebSocket推送评估完成通知
8. **深色模式**：主题切换
9. **离线支持**：草稿保存
10. **搜索和筛选**：实时搜索、多条件筛选
