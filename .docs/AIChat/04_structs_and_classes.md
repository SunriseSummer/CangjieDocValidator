# 04. 结构体与类：消息数据建模

> 数据建模是 AI 系统的基石。清晰的数据结构让 API 调用、消息管理和状态追踪变得自然而简单。本章我们用仓颉的 `struct` 与 `class` 为 AIChatPro 构建核心数据模型。

## 本章目标

*   理解 `struct`（值类型）与 `class`（引用类型）的本质区别与适用场景。
*   掌握构造函数 `init`、成员方法与计算属性 `prop` 的用法。
*   体会封装的价值：隐藏实现细节，暴露清晰接口。
*   构建 AIChatPro 的核心数据模型：`ChatMessage` 与 `ChatSession`。

## 1. 结构体：值类型

`struct` 是**值类型**。赋值或传参时，会完整复制一份数据。适合表示"数据快照"——不可变、无副作用。

<!-- check:run -->
```cangjie
struct TokenUsage {
    var promptTokens: Int64
    var completionTokens: Int64

    public init(prompt: Int64, completion: Int64) {
        this.promptTokens = prompt
        this.completionTokens = completion
    }

    public func total(): Int64 {
        promptTokens + completionTokens
    }

    public func describe(): String {
        "prompt=${promptTokens}, completion=${completionTokens}, total=${total()}"
    }
}

main() {
    let usage1 = TokenUsage(100, 50)
    var usage2 = usage1        // 值拷贝：完整复制

    usage2.promptTokens = 999  // 修改 usage2，不影响 usage1

    println("usage1: ${usage1.describe()}")
    println("usage2: ${usage2.describe()}")
    println("usage1 未被修改: ${usage1.total() == 150}")
}
```

<!-- expected_output:
usage1: prompt=100, completion=50, total=150
usage2: prompt=999, completion=50, total=1049
usage1 未被修改: true
-->

再看一个更贴近项目的例子——`ModelConfig` 作为只读配置快照：

<!-- check:run -->
```cangjie
struct ModelConfig {
    let name: String
    let provider: String
    let maxTokens: Int64
    let supportsStreaming: Bool

    public init(name: String, provider: String, maxTokens: Int64, supportsStreaming: Bool) {
        this.name = name
        this.provider = provider
        this.maxTokens = maxTokens
        this.supportsStreaming = supportsStreaming
    }

    public func summary(): String {
        let streamTag = if (supportsStreaming) { "流式" } else { "非流式" }
        "${name} (${provider}, ${maxTokens} tokens, ${streamTag})"
    }
}

main() {
    let configs = [
        ModelConfig("moonshot-v1-8k", "Moonshot AI", 8000, true),
        ModelConfig("glm-4-flash", "智谱 AI", 8192, true),
        ModelConfig("abab6.5s-chat", "Minimax", 8192, true)
    ]

    println("已配置模型:")
    for (cfg in configs) {
        println("  ${cfg.summary()}")
    }
}
```

<!-- expected_output:
已配置模型:
  moonshot-v1-8k (Moonshot AI, 8000 tokens, 流式)
  glm-4-flash (智谱 AI, 8192 tokens, 流式)
  abab6.5s-chat (Minimax, 8192 tokens, 流式)
-->

## 2. 类：引用类型

`class` 是**引用类型**。赋值或传参传递的是引用（指针），多个变量可以指向同一个对象。适合管理有生命周期的可变状态。

<!-- check:run -->
```cangjie
class ConversationContext {
    public var turnCount: Int64
    public var totalInputTokens: Int64
    public var totalOutputTokens: Int64

    public init() {
        this.turnCount = 0
        this.totalInputTokens = 0
        this.totalOutputTokens = 0
    }

    public func recordTurn(inputTokens: Int64, outputTokens: Int64) {
        turnCount = turnCount + 1
        totalInputTokens = totalInputTokens + inputTokens
        totalOutputTokens = totalOutputTokens + outputTokens
    }

    public func summary(): String {
        "轮次=${turnCount}, 输入=${totalInputTokens}, 输出=${totalOutputTokens}"
    }
}

main() {
    let ctx = ConversationContext()
    let ctxAlias = ctx    // 引用拷贝，指向同一对象

    ctx.recordTurn(120, 80)
    ctxAlias.recordTurn(200, 150)    // 通过别名修改同一对象

    println("通过 ctx: ${ctx.summary()}")
    println("通过 ctxAlias: ${ctxAlias.summary()}")
    println("是同一对象: ${ctx.turnCount == ctxAlias.turnCount}")
}
```

<!-- expected_output:
通过 ctx: 轮次=2, 输入=320, 输出=230
通过 ctxAlias: 轮次=2, 输入=320, 输出=230
是同一对象: true
-->

> **选择法则**：无状态的数据描述（API 响应、配置快照）用 `struct`；有持续状态的对象（会话、连接池、缓冲区）用 `class`。

## 3. 方法与属性

仓颉的 `prop` 关键字定义**计算属性**——像访问字段一样调用函数，封装计算逻辑，对外暴露清晰接口。

<!-- check:run -->
```cangjie
class ApiStats {
    public var requestCount: Int64
    public var totalTokens: Int64
    public var failureCount: Int64

    public init() {
        this.requestCount = 0
        this.totalTokens = 0
        this.failureCount = 0
    }

    // 计算属性：平均每次请求的 Token 数
    public prop avgTokensPerRequest: Int64 {
        get() {
            if (requestCount == 0) { 0 } else { totalTokens / requestCount }
        }
    }

    // 计算属性：成功率（百分比整数）
    public prop successRate: Int64 {
        get() {
            if (requestCount == 0) {
                0
            } else {
                (requestCount - failureCount) * 100 / requestCount
            }
        }
    }

    public func record(tokens: Int64, failed: Bool) {
        requestCount = requestCount + 1
        totalTokens = totalTokens + tokens
        if (failed) { failureCount = failureCount + 1 }
    }

    public func report(): String {
        "请求=${requestCount}, 成功率=${successRate}%, 平均Token=${avgTokensPerRequest}"
    }
}

main() {
    let stats = ApiStats()
    stats.record(150, false)
    stats.record(200, false)
    stats.record(180, true)
    stats.record(220, false)

    // 像字段一样访问计算属性
    println("平均 Token: ${stats.avgTokensPerRequest}")
    println("成功率: ${stats.successRate}%")
    println(stats.report())
}
```

<!-- expected_output:
平均 Token: 187
成功率: 75%
请求=4, 成功率=75%, 平均Token=187
-->

## 4. 封装与可读性

良好的封装意味着：**私有字段，公开行为**。外部代码只看到"能做什么"，不关心"怎么做"。

<!-- check:run -->
```cangjie
class RateLimiter {
    private var _windowStart: Int64   // 时间窗口起始（模拟时间戳）
    private var _requestsInWindow: Int64
    private let _maxPerWindow: Int64

    public init(maxPerWindow: Int64) {
        this._maxPerWindow = maxPerWindow
        this._windowStart = 0
        this._requestsInWindow = 0
    }

    // 公开行为：尝试发起请求
    public func tryRequest(currentTime: Int64): Bool {
        // 超过 60 秒则重置窗口（简化逻辑）
        if (currentTime - _windowStart >= 60) {
            _windowStart = currentTime
            _requestsInWindow = 0
        }

        if (_requestsInWindow < _maxPerWindow) {
            _requestsInWindow = _requestsInWindow + 1
            return true
        }
        return false
    }

    // 只读属性：当前窗口已用请求数
    public prop used: Int64 { get() { _requestsInWindow } }
    public prop limit: Int64 { get() { _maxPerWindow } }

    public func status(): String {
        "${_requestsInWindow}/${_maxPerWindow} 次（窗口内）"
    }
}

main() {
    let limiter = RateLimiter(3)    // 每 60 秒最多 3 次请求

    let times = [0, 10, 20, 30, 100, 110]
    for (t in times) {
        let ok = limiter.tryRequest(t)
        let tag = if (ok) { "✓ 允许" } else { "✗ 拒绝" }
        println("t=${t}s: ${tag} — ${limiter.status()}")
    }
}
```

<!-- expected_output:
t=0s: ✓ 允许 — 1/3 次（窗口内）
t=10s: ✓ 允许 — 2/3 次（窗口内）
t=20s: ✓ 允许 — 3/3 次（窗口内）
t=30s: ✗ 拒绝 — 3/3 次（窗口内）
t=100s: ✓ 允许 — 1/3 次（窗口内）
t=110s: ✓ 允许 — 2/3 次（窗口内）
-->

*   `private` 字段不能从类外部访问，实现细节被安全封装。
*   `prop` 提供只读视图，外部无法直接修改内部状态。
*   `tryRequest` 封装了窗口重置和计数更新的完整逻辑，调用方不需要了解细节。

## 5. ChatMessage 与 ChatSession

综合运用本章知识，构建 AIChatPro 的核心数据模型：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

// ChatMessage：单条消息，用 class 管理生命周期
class ChatMessage {
    public let role: String
    public let content: String
    public let tokenCount: Int64

    public init(role: String, content: String, tokenCount: Int64) {
        this.role = role
        this.content = content
        this.tokenCount = tokenCount
    }

    public func toDisplay(): String {
        "[${role}]: ${content}"
    }

    public func toJson(): String {
        "{\"role\": \"${role}\", \"content\": \"${content}\"}"
    }
}

// TokenBudget：Token 预算，用 struct 记录快照
struct TokenBudget {
    let used: Int64
    let limit: Int64

    public init(used: Int64, limit: Int64) {
        this.used = used
        this.limit = limit
    }

    public prop remaining: Int64 { get() { limit - used } }
    public prop percentUsed: Int64 { get() { used * 100 / limit } }

    public func describe(): String {
        "已用 ${used}/${limit} tokens（${percentUsed}%），剩余 ${remaining}"
    }
}

// ChatSession：对话会话，持有可变状态
class ChatSession {
    public let model: String
    private var messages: ArrayList<ChatMessage>
    private var totalTokensUsed: Int64
    private let tokenLimit: Int64

    public init(model: String, tokenLimit: Int64) {
        this.model = model
        this.messages = ArrayList<ChatMessage>()
        this.totalTokensUsed = 0
        this.tokenLimit = tokenLimit
    }

    public prop messageCount: Int64 { get() { messages.size } }

    public prop budget: TokenBudget {
        get() { TokenBudget(totalTokensUsed, tokenLimit) }
    }

    public func addMessage(role: String, content: String, tokens: Int64) {
        messages.add(ChatMessage(role, content, tokens))
        totalTokensUsed = totalTokensUsed + tokens
    }

    public func clearHistory() {
        messages.clear()
        totalTokensUsed = 0
    }

    public func showHistory() {
        println("=== 对话历史 [${model}] ===")
        for (msg in messages) {
            println(msg.toDisplay())
        }
        println(budget.describe())
    }
}

main() {
    let session = ChatSession("moonshot-v1-8k", 8000)

    session.addMessage("system", "你是专业的仓颉语言助手", 20)
    session.addMessage("user", "什么是仓颉语言？", 10)
    session.addMessage("assistant", "仓颉是华为推出的现代系统编程语言。", 25)
    session.addMessage("user", "它的主要特点是什么？", 9)

    session.showHistory()
    println("")

    // Token 预算快照（struct 值类型）
    let snapshot = session.budget
    println("预算快照: ${snapshot.describe()}")

    // 清空历史后，快照数据不受影响
    session.clearHistory()
    println("清空后消息数: ${session.messageCount}")
    println("快照仍保留: ${snapshot.used} tokens used")
}
```

<!-- expected_output:
=== 对话历史 [moonshot-v1-8k] ===
[system]: 你是专业的仓颉语言助手
[user]: 什么是仓颉语言？
[assistant]: 仓颉是华为推出的现代系统编程语言。
[user]: 它的主要特点是什么？
已用 64/8000 tokens（0%），剩余 7936
预算快照: 已用 64/8000 tokens（0%），剩余 7936
清空后消息数: 0
快照仍保留: 64 tokens used
-->

*   `ChatMessage` 的字段用 `let`（内容一旦创建不应修改），而 `ChatSession` 内部状态用 `var`（消息列表和 Token 计数需要更新）。
*   `TokenBudget` 用 `struct` + `prop` 提供计算属性，`budget` 的快照语义完美契合值类型的复制行为。
*   `private messages` 防止外部直接操作列表，所有修改必须通过 `addMessage`/`clearHistory` 方法，保持数据一致性。

## 工程化提示

*   **`struct` vs `class` 决策**：字段不超过 4 个、语义上是"数据快照"的用 `struct`；有多个可变字段、代表持续状态的用 `class`。
*   **`let` 字段优先**：`ChatMessage` 的 `role` 和 `content` 用 `let`，表达"消息一经创建不可修改"的语义。
*   **`prop` 封装计算**：`avgTokensPerRequest`、`successRate` 等派生值用 `prop` 暴露，比暴露 `var` 字段更安全。
*   **私有字段 + 公有方法**：将 `messages` 设为 `private`，迫使所有修改通过 `addMessage` 进行，便于添加校验、日志等横切逻辑。
*   **`toString` 模式**：在 `class`/`struct` 中提供 `toDisplay()` 和 `toJson()` 方法，分别服务于调试输出和 API 序列化两种场景。

## 实践挑战

1. 为 `ChatSession` 添加 `getLastMessage(): ?ChatMessage` 方法，当消息为空时返回 `None`（用 `Option` 类型，下一章会详细介绍）。
2. 为 `TokenBudget` 添加 `isNearLimit(): Bool` 方法，当使用率超过 80% 时返回 `true`。
3. 为 `ChatSession` 添加 `setModel(newModel: String)` 方法，切换模型时自动打印一行提示（"已从 X 切换到 Y"）。
4. 思考：如果要实现"撤回最后一条消息"的功能，`ChatSession` 需要添加什么方法？`totalTokensUsed` 的计算会遇到什么问题？
