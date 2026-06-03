# 02_10 — LiteLLM 实战指南

> 本项目实际使用的多模型统一网关。一文掌握 LiteLLM 的配置、路由、成本控制和部署。

---

## 一、LiteLLM 解决什么问题？

### 问题

```
Agent 要调用的模型:
  ├─ Claude Sonnet 4.6 (Anthropic API)    → API 格式: Anthropic Messages
  ├─ GPT-4.1 (OpenAI API)                 → API 格式: OpenAI Chat
  ├─ DeepSeek-V4-Pro (DeepSeek API)       → API 格式: Anthropic 兼容
  └─ Qwen2.5-Coder (自部署 vLLM)          → API 格式: OpenAI 兼容

每个模型的 API 格式、认证方式、计费模型都不同。
Agent 代码需要分别对接 4 套 SDK → 复杂、难维护。
```

### 解决

```
Agent
  │  统一调 OpenAI 格式 API
  ▼
LiteLLM (统一网关 :4000)
  │  内部路由、格式转换、认证注入
  ├─→ Anthropic API (转 Anthropic 格式)
  ├─→ OpenAI API (直通)
  ├─→ DeepSeek API (转 Anthropic 格式)
  └─→ 自部署 vLLM (直通)
```

Agent 只需对接一套接口（OpenAI 格式），LiteLLM 负责内部转换。

---

## 二、LiteLLM 架构

```
┌─────────────────────────────────────────┐
│              LiteLLM Proxy               │
│                                         │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │ 路由层   │  │ 格式转换  │  │ 预算   │ │
│  │ 按规则选 │  │ Anthropic │  │ 月限额 │ │
│  │ 模型     │  │ ↔ OpenAI │  │ Token  │ │
│  └─────────┘  └──────────┘  └────────┘ │
│                                         │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │ 重试/降级│  │ 日志/监控 │  │ 速率   │ │
│  │ 主模型挂 │  │ 每请求   │  │ 限制   │ │
│  │ → 备用  │  │ 记录     │  │ RPM/TPM│ │
│  └─────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────┘
```

---

## 三、快速启动

### Docker 部署（推荐）

```bash
# 1. 创建配置文件
mkdir litellm && cd litellm
cat > litellm_config.yaml << 'EOF'
general_settings:
  master_key: sk-litellm-master-key

model_list:
  # Claude Sonnet — 编码主力
  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: sk-ant-xxx
      rpm: 50

  # DeepSeek — 低成本备用
  - model_name: deepseek
    litellm_params:
      model: deepseek/deepseek-chat
      api_key: sk-deepseek-xxx
      rpm: 100

  # GPT-4.1 — 结构化输出专用
  - model_name: gpt-4
    litellm_params:
      model: openai/gpt-4.1
      api_key: sk-openai-xxx
      rpm: 30

litellm_settings:
  drop_params: true           # 自动去掉不支持的参数
  set_verbose: false
  request_timeout: 120        # 请求超时 120 秒

router_settings:
  num_retries: 3              # 失败重试 3 次
  allowed_fails: 5            # 连续失败 5 次标记不健康
  cooldown_time: 30           # 冷却 30 秒后重试
EOF

# 2. 启动
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -v $(pwd)/litellm_config.yaml:/app/config.yaml \
  ghcr.io/berriai/litellm:main \
  --config /app/config.yaml

# 3. 验证
curl http://localhost:4000/health
```

### 本项目配置

```bash
# .env 中的 LiteLLM 配置
ANTHROPIC_BASE_URL=http://localhost:4000
ANTHROPIC_MODEL=deepseek-chat            # 对应 litellm_config.yaml 中的 model_name
ANTHROPIC_AUTH_TOKEN=sk-litellm-master-key
```

---

## 四、核心功能

### 4.1 模型路由

```yaml
# 按任务复杂度路由到不同模型
router_settings:
  routing_strategy: "usage-based"   # 负载均衡 / latency-based / cost-based

model_list:
  # 定义同一个逻辑模型的多个后端
  - model_name: my-agent-model
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: sk-ant-xxx
  - model_name: my-agent-model
    litellm_params:
      model: deepseek/deepseek-chat
      api_key: sk-deepseek-xxx

# Agent 调 "my-agent-model" 时，
# LiteLLM 自动在两个后端间负载均衡
```

### 4.2 预算控制

```yaml
# 全局预算
litellm_settings:
  max_budget: 500           # 月预算 $500
  budget_duration: "1mo"

# 单模型限流
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: sk-ant-xxx
      rpm: 50               # 每分钟最多 50 次
      tpm: 100000           # 每分钟最多 10万 token
      max_budget: 200       # 该模型月预算 $200
```

### 4.3 降级策略

```yaml
model_list:
  - model_name: production-model
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: sk-ant-xxx
      rpm: 50
    model_info:
      mode: chat
```

当 Claude API 返回错误或超时时，LiteLLM 自动重试 3 次，还失败则返回错误给 Agent。Agent 侧可以实现 fallback 逻辑：主模型失败 → 切备用模型。

### 4.4 成本追踪

```bash
# LiteLLM 内置 Dashboard
# 访问 http://localhost:4000/ui

# 查看各模型使用统计
curl http://localhost:4000/global/activity \
  -H "Authorization: Bearer sk-litellm-master-key"

# 按模型查看
curl http://localhost:4000/global/activity?model=claude-sonnet \
  -H "Authorization: Bearer sk-litellm-master-key"
```

---

## 五、生产部署建议

### 5.1 连接池和缓存

```yaml
litellm_settings:
  cache: true
  cache_params:
    type: redis
    host: localhost
    port: 6379
    ttl: 3600              # 缓存 1 小时
```

相同请求命中缓存 → 直接返回，不调模型 API，省钱。

### 5.2 Prometheus 监控

```yaml
litellm_settings:
  success_callback: ["prometheus"]    # 成功请求回调
  failure_callback: ["prometheus"]    # 失败请求回调

# 指标:
#   - litellm_requests_total       (总请求数)
#   - litellm_tokens_total          (总 token 数)
#   - litellm_cost_total            (总成本)
#   - litellm_latency_seconds       (延迟)
```

### 5.3 哨兵模式（高可用）

```
┌──────────────┐    ┌──────────────┐
│  LiteLLM-1   │    │  LiteLLM-2   │
│  :4000       │    │  :4001       │
└──────┬───────┘    └──────┬───────┘
       │                   │
       └─────────┬─────────┘
                 │
          ┌──────▼──────┐
          │    nginx     │
          │  负载均衡    │
          │   :4000      │
          └─────────────┘
                 │
           Agent 统一调 :4000
```

```nginx
# nginx 配置
upstream litellm {
    server 127.0.0.1:4000;
    server 127.0.0.1:4001;
}

server {
    listen 4000;
    location / {
        proxy_pass http://litellm;
        proxy_read_timeout 120s;
    }
}
```

---

## 六、和直接 API 的对比

| | 直接调 API | LiteLLM |
|---|---|---|
| **多模型管理** | 各自对接 SDK | 统一 OpenAI 格式 |
| **成本追踪** | 自己实现 | 内置 Dashboard |
| **限流降级** | 自己实现 | 内置路由 |
| **格式转换** | 自己处理 | 自动转换 |
| **运维复杂度** | 低 | 中等（多一层服务） |
| **单点故障** | 无 | LiteLLM 挂影响全部 |
| **适用规模** | <1000 次/天 | >1000 次/天 |

---

## 七、常见问题

**Q: LiteLLM 不支持 Anthropic 原生 API 怎么办？**

LiteLLM 内部支持 Anthropic Messages API 格式的输入/输出转换。Agent 发 OpenAI 格式请求，LiteLLM 转成 Anthropic 格式发给 Claude，返回时再转回 OpenAI 格式。功能 95% 覆盖。

**Q: 延迟增加多少？**

通常 <50ms（纯转发+格式转换）。但如果请求排队（RPM 限制触发），延迟会增加。

**Q: 和 OpenRouter 的区别？**

| | LiteLLM | OpenRouter |
|---|---|---|
| 部署 | 自部署 | SaaS |
| 模型源 | 你配置的 API/服务器 | OpenRouter 聚合的 |
| 成本 | 自己 API Key 的费用 | 加价 5-10% |
| 可控性 | 完全可控 | 依赖第三方 |
