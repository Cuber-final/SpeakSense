# Evaluation Detail API Contract (Draft)

> 用途：对齐后端实现与前端数据解析的最小字段契约（MVP）。
> 目标：避免后续前端大改，同时保留扩展空间。

## Endpoint

```
GET /v1/attempts/{attempt_id}/evaluation
```

兼容候选（可选）
```
GET /v1/evaluations/{attempt_id}
```

## Response (Problem JSON on error)

成功响应（示例）：

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

## 字段说明（最小集）

### 顶层 data

- `id` (string) 评估/attempt 的唯一标识
- `scenario_title` (string) 场景标题
- `overall_score` (number) 总评分 (0–5)
- `level` (string) 等级描述
- `summary` (string) 总结评语
- `dimensions` (array) 雷达图维度列表
- `metrics` (array) 关键指标（Duration / Pace / Vocabulary）
- `questions` (array) 问题细分列表

### dimensions[]（雷达图维度）
- `label` (string) 维度名称（Naturalness / Richness / Grammar / Relevance）
- `score` (number) 评分 (0–5)

### metrics[]（关键指标）
- `key` (string) 便于映射的 key（duration/pace/vocabulary）
- `label` (string) 展示名
- `value` (string) 展示值

### questions[]（问题细分）
- `question` (string) 问题文本
- `answer` (string) 用户回答
- `feedback` (string) AI 反馈
- `suggested_answer` (string) 建议答案
- `audio_url` (string, optional) 语音回放地址（可为空）
- `dimensions` (array) 单题维度评分（结构同上）

## 兼容字段（前端解析已支持）

为了降低后端实现负担，前端已支持以下别名字段：

- `overall_score` / `avg_score` / `score`
- `scenario_title` / `title` / `name`
- `questions` / `items` / `breakdown`
- `suggested_answer` / `suggested` / `ideal_answer`
- `audio_url` / `audio` / `audioUrl`

## 错误响应

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
