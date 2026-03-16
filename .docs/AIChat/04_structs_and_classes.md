# 04. 结构体与类：消息数据建模

> 每一个 AI 应用的内核，都是一组精心设计的数据结构。消息如何表示？会话如何管理？Token 预算如何追踪？这些看似简单的问题，决定了系统的可维护性与可扩展性。本章，我们将用仓颉的 `struct` 与 `class` 两大基石，为 AIChatPro 构建核心数据模型——从不可变的配置快照，到有生命周期的会话对象。

## 本章目标

*   理解 `struct`（值类型）与 `class`（引用类型）的本质区别与适用场景。
*   掌握构造函数 `init`、成员方法与计算属性 `prop` 的用法。
*   体会封装的价值：隐藏实现细节，暴露清晰接口。
*   构建 AIChatPro 的核心数据模型：`ChatMessage` 与 `ChatSession`。

## 1. 结构体：值类型

在 AI 应用中，有大量"一旦产生就不再改变"的数据——API 返回的 Token 用量、模型的配置参数、某一时刻的状态快照。这些数据天然适合用值类型来表达。

仓颉的 `struct` 正是**值类型**：赋值或传参时，会完整复制一份数据。这意味着每个副本彼此独立，修改其中一个，绝不会影响另一个。这种"数据快照"般的语义，消除了共享状态带来的隐患。

下面用 `TokenUsage` 来直观感受值拷贝的行为：

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

注意最后一行输出：即便 `usage2` 是从 `usage1` 赋值而来，修改 `usage2` 后，`usage1` 的数据纹丝不动。这就是值类型的核心承诺——**拷贝即隔离**。在多处传递 Token 用量数据时，你永远不用担心某处的修改会"幽灵般"地影响其他地方。

再看一个更贴近项目的例子——`ModelConfig` 作为只读配置快照。AIChatPro 支持多家模型供应商，每个模型的配置参数在创建后就不应被修改，`struct` + `let` 字段的组合完美契合这一需求：

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

所有字段都用 `let` 声明，意味着一旦构造完成就彻底冻结。即使把 `ModelConfig` 传递给任意函数，接收方也无法修改它——编译器会替你把关。这种"编译期不可变性"比运行时检查更可靠，也更高效。

## 2. 类：引用类型

并非所有数据都适合"快照化"。一个 AI 对话会话需要持续追踪轮次、累积 Token 用量、动态增删消息——它有自己的**生命周期**和**可变状态**。对于这类场景，仓颉提供了 `class`。

`class` 是**引用类型**：赋值或传参传递的是引用（指针），多个变量可以指向同一个对象。这意味着通过任何一个引用修改对象，所有引用都能看到变化——这正是管理共享状态所需要的。

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

`ctx` 和 `ctxAlias` 输出完全一致——因为它们指向同一个对象。无论通过哪个变量调用 `recordTurn`，都是在修改同一块内存。在实际项目中，这意味着你可以把会话对象传递给不同的模块（日志模块、计费模块、UI 模块），它们都操作同一个对象，无需手动同步数据。

> **选择法则**：无状态的数据描述（API 响应、配置快照）用 `struct`；有持续状态的对象（会话、连接池、缓冲区）用 `class`。

## 3. 方法与属性

在前面的示例中，我们已经使用了成员方法（如 `total()`、`summary()`）来封装行为。但有些逻辑更像是"数据的自然延伸"而非"动作"——比如成功率、平均值、百分比。对于这类派生数据，仓颉提供了一种更优雅的表达方式。

仓颉的 `prop` 关键字定义**计算属性**——外部像访问字段一样使用它，内部却是一个函数在动态计算。这样做的好处是：调用方的代码更简洁（`stats.successRate` 比 `stats.getSuccessRate()` 更自然），同时实现细节仍然被封装在类的内部。

下面通过一个 API 调用统计器来演示方法与计算属性的配合：

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

注意 `avgTokensPerRequest` 和 `successRate` 的使用方式：调用方写 `stats.successRate`，看起来像访问一个字段，实际上每次访问都会重新计算。这意味着它们永远返回最新值——无需担心缓存过期。`record()` 方法负责"写入"，`prop` 负责"派生读取"，职责分明。

## 4. 封装与可读性

良好的封装意味着：**私有字段，公开行为**。外部代码只看到"能做什么"，不关心"怎么做"。这不仅是代码美学的追求，更是工程上的实际需要——当内部实现需要调整时（比如更换限流算法），只要公开接口不变，所有调用方无需改动。

下面的 `RateLimiter` 展示了这一原则。它的内部维护着时间窗口和计数器，但外部调用方只需调用 `tryRequest()` 即可——完全不需要理解窗口重置的逻辑：

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

仔细观察这个设计中三层封装的配合：

*   **`private` 字段**隐藏了实现细节（`_windowStart`、`_requestsInWindow`），外部无法直接修改计数器。
*   **`prop` 只读属性**（`used`、`limit`）提供了安全的观察窗口——可以读取状态，但无法篡改。
*   **`tryRequest` 方法**将窗口重置、计数更新、限流判断封装为一个原子操作，调用方只需传入当前时间即可。

未来如果需要将固定窗口算法升级为滑动窗口或令牌桶算法，只需修改 `tryRequest` 的内部逻辑，所有调用方的代码一行都不用改。

## 5. ChatMessage 与 ChatSession

前面四节分别介绍了值类型、引用类型、计算属性和封装。现在，让我们将这些知识融会贯通，构建 AIChatPro 的核心数据模型。我们将逐步搭建三个组件：表示单条消息的 `ChatMessage`、追踪 Token 预算的 `TokenBudget`、以及管理整个对话的 `ChatSession`。

### 5.1 ChatMessage：不可变的消息记录

在 AI 对话中，每条消息一旦发送就不应被修改——用户说了什么、助手回复了什么，都是历史事实。因此 `ChatMessage` 的所有字段都用 `let` 声明，构造后即冻结。

我们选择 `class` 而非 `struct`，是因为消息对象会被放入动态列表中管理。引用语义让列表持有的是指向消息的指针，避免了大量字符串数据的反复拷贝。

<!-- check:run -->
```cangjie
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

main() {
    let msg = ChatMessage("user", "什么是仓颉语言？", 10)
    println(msg.toDisplay())
    println(msg.toJson())
    println("Token 数: ${msg.tokenCount}")
}
```

<!-- expected_output:
[user]: 什么是仓颉语言？
{"role": "user", "content": "什么是仓颉语言？"}
Token 数: 10
-->

`toDisplay()` 服务于终端调试输出，`toJson()` 服务于 API 请求序列化——同一份数据，两种视图。这种"多格式输出"的模式在 AI 应用中非常常见，值得从一开始就建立良好的习惯。

### 5.2 TokenBudget：值类型的快照语义

大语言模型的每次调用都有 Token 上限。我们需要一个轻量的结构来记录"已用多少、还剩多少"。`TokenBudget` 用 `struct` 实现，因为它本质上是一个**数据快照**——某一时刻的预算状态。

值类型在这里带来了一个精妙的好处：你可以在任意时刻"拍摄"一份预算快照，之后即使原始数据发生变化（比如新增了消息），快照中的数值依然不变。这对于日志记录和状态审计非常有用。

<!-- check:run -->
```cangjie
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

main() {
    let budget = TokenBudget(640, 8000)
    println(budget.describe())

    // struct 是值类型——赋值产生独立副本
    var snapshot = budget
    println("快照与原始独立: ${snapshot.remaining == budget.remaining}")
}
```

<!-- expected_output:
已用 640/8000 tokens（8%），剩余 7360
快照与原始独立: true
-->

`remaining` 和 `percentUsed` 用计算属性实现，而非存储字段。这样做的好处是不存在数据不一致的风险——它们永远由 `used` 和 `limit` 实时推导，无需手动同步。

### 5.3 ChatSession：组装完整的对话引擎

有了消息和预算两个组件，我们终于可以构建最核心的 `ChatSession` 类。它综合运用了本章的所有知识：`class` 管理可变状态、`private` 封装内部细节、`prop` 暴露派生数据、值类型的 `TokenBudget` 提供安全的快照语义。

<!-- check:run -->
```cangjie
import std.collection.ArrayList

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

这段代码的最后几行揭示了一个关键的设计决策：`session.budget` 返回的是一个 `TokenBudget` 结构体——值类型。当我们用 `let snapshot = session.budget` 保存预算快照后，即使调用 `session.clearHistory()` 清空了所有消息并重置了 Token 计数，`snapshot` 中的数据仍然完好无损。这正是 `struct` 与 `class` 协作的典范：`class` 管理动态变化的状态，`struct` 在需要时"冻结"一个安全的瞬间副本。

回顾整个模型的设计，每一处选择都有明确的理由：

*   `ChatMessage` 用 `class` + `let` 字段：引用语义便于列表管理，不可变字段保证消息内容不被篡改。
*   `TokenBudget` 用 `struct` + `prop`：值语义天然支持快照，计算属性保证派生数据始终一致。
*   `ChatSession` 用 `private` 字段 + 公有方法：所有修改必须通过 `addMessage`/`clearHistory` 进行，便于将来添加校验、日志等横切逻辑。

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
