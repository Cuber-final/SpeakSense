# LLM/VLM 抽象层调研与落地草案

最后更新: 2026-02-07  
适用范围: SpeakSense 后端 `backend/app/services/llm`（待创建）

---

## 1. 目标与边界

### 目标
- 统一接入 OpenAI compatible API，并支持主流云端与本地推理服务（如 Ollama、vLLM）。
- 同一套调用接口覆盖 LLM 与 VLM（文本+图像）。
- 对上层业务暴露稳定的语义层，不让业务代码感知 provider 差异。
- 提供可观测性、失败重试、降级与错误标准化（Problem JSON）。

### 非目标（MVP 阶段）
- 不做“全量参数透传”；只暴露业务必需参数，避免接口失控。
- 不做多租户计费系统；只保留 usage 与 provider 计量字段。
- 不做复杂编排平台；先实现单次请求 + 简单 fallback 链路。

---

## 2. 参考实现与文档（第一批）

> 当前环境无法在线校验链接可达性，以下为已筛选的官方/主流项目入口，后续可在联网环境补做健康检查。

- OpenAI Responses API: `https://platform.openai.com/docs/api-reference/responses`
- OpenAI Vision Guide: `https://platform.openai.com/docs/guides/vision`
- vLLM OpenAI compatible server: `https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html`
- vLLM multimodal inputs: `https://docs.vllm.ai/en/latest/serving/multimodal_inputs.html`
- Ollama OpenAI compatibility: `https://github.com/ollama/ollama/blob/main/docs/openai.md`
- LiteLLM providers: `https://docs.litellm.ai/docs/providers`
- LiteLLM routing/fallback: `https://docs.litellm.ai/docs/routing`
- Cherry Studio（产品能力参考）: `https://github.com/CherryHQ/cherry-studio`
- One API（网关参考）: `https://github.com/songquanpeng/one-api`

---

## 3. 统一能力模型（Capability Matrix）

建议以“能力”驱动路由，而不是硬编码 provider 分支。MVP 先冻结以下能力位：

| capability | 说明 |
|---|---|
| `chat` | 标准对话生成 |
| `stream` | 流式输出 |
| `tool_call` | 函数调用/工具调用 |
| `json_output` | JSON mode / schema constrained output |
| `vision_input` | 图像输入（URL/base64） |
| `embedding` | 向量接口（后续可选） |
| `reasoning_effort` | 推理强度类参数（可选） |

Provider 注册时声明 `supported_capabilities`，请求路由按能力筛选候选模型。

---

## 4. 统一请求/响应协议（服务内 DTO）

## Request（建议）
- `request_id: str`
- `provider_hint: str | None`（可选）
- `model: str`
- `messages: list[Message]`
- `temperature: float | None`
- `top_p: float | None`
- `max_output_tokens: int | None`
- `stream: bool`
- `tools: list[ToolSpec]`
- `response_format: JsonSchemaSpec | None`
- `timeout_ms: int`
- `metadata: dict[str, str]`

`Message.content` 采用多模态分段：
- `{"type":"text","text":"..."}`
- `{"type":"image_url","image_url":"https://..."}`
- `{"type":"image_base64","mime_type":"image/png","data":"..."}`

## Response（建议）
- `provider: str`
- `model: str`
- `output_text: str`
- `tool_calls: list[ToolCall]`
- `finish_reason: str`
- `usage: Usage`
- `raw_response: dict[str, Any]`（审计/排障）

---

## 5. 抽象层接口设计（Python）

```python
from __future__ import annotations
from typing import Protocol, AsyncIterator

class LLMAdapter(Protocol):
    provider_name: str
    supported_capabilities: set[str]

    async def generate(self, request: "GenerateRequest") -> "GenerateResponse":
        ...

    async def stream(self, request: "GenerateRequest") -> AsyncIterator["StreamChunk"]:
        ...

    async def health(self) -> bool:
        ...
```

配套组件：
- `ProviderRegistry`: provider 实例注册/查找。
- `ModelRouter`: 按能力、优先级、可用性选路。
- `RetryPolicy`: 指数退避 + 可重试错误白名单。
- `FallbackPolicy`: 主模型失败后切换备用模型。
- `ErrorNormalizer`: 统一映射到 Problem JSON。

---

## 6. 错误标准化（Problem JSON 对齐）

建议统一错误码：
- `LLM_AUTH_ERROR`
- `LLM_RATE_LIMITED`
- `LLM_TIMEOUT`
- `LLM_PROVIDER_UNAVAILABLE`
- `LLM_INVALID_REQUEST`
- `LLM_UNSUPPORTED_CAPABILITY`
- `LLM_EMPTY_OUTPUT`

响应格式遵循仓库约束：

```json
{
  "error": {
    "type": "provider_error",
    "code": "LLM_TIMEOUT",
    "message": "Upstream model request timed out",
    "details": {
      "provider": "openai",
      "model": "gpt-4.1-mini"
    }
  }
}
```

---

## 7. 可观测性与审计字段

每次调用应记录：
- `request_id`
- `user_id`（如有）
- `provider`
- `model`
- `latency_ms`
- `input_tokens` / `output_tokens` / `total_tokens`
- `status`（success/fail/fallback）
- `error_code`（失败时）

日志结构保持 JSON，便于后续指标聚合。

---

## 8. 与前端契约的衔接

- 当前前端已完成评估详情契约草案：`docs/evaluation-detail-contract.md`
- 后端落地时应先冻结 MVP 字段，再连接前端 API 模式，减少双端返工。
- 推荐顺序：先 `/v1/attempts/{id}/evaluation`，再扩展语音上传、实时事件。

---

## 9. 建议实施顺序（Backend MVP）

1. `B1` 创建后端骨架（FastAPI + settings + Problem JSON + request_id middleware）。
2. `B2` 实现 `services/llm` 核心抽象层（DTO + Adapter Protocol + Registry + Router）。
3. `B3` 首批 provider：`openai_compatible` 通用适配器 + `ollama` + `vllm`。
4. `B4` 接入业务路由：boards/eval/practice 使用统一 gateway。
5. `B5` 增加 VLM 输入支持与能力检测（vision_input）。
6. `B6` 增加集成测试（mock provider + 失败重试 + fallback）。

---

## 10. 待决策项

- JSON schema 输出是强制（strict）还是软约束（best effort）？
- 流式接口是否在 MVP 即暴露到业务层？
- provider 凭据管理是否按模型级覆盖（`model -> api_key/base_url`）？
- fallback 策略是静态配置还是运行时策略（按错误类型分支）？

