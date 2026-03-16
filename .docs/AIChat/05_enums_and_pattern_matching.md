# 05. 枚举与模式匹配：角色与命令系统

> 枚举让状态有名有义，模式匹配让分支逻辑清晰无歧义。AI 对话的每一个角色、每一条命令，都需要精确的类型表达——而不是用魔法字符串堆砌。

## 本章目标

*   掌握枚举（`enum`）的定义与基本匹配。
*   使用带载荷的枚举表达"有内容的状态"。
*   探索模式匹配的进阶用法：元组模式、OR 模式、枚举解构。
*   深入理解 `Option<T>` 类型，安全处理可能缺失的值。
*   构建 AIChatPro 的 `Role` 枚举与完整命令解析系统。

## 1. 枚举基础

枚举用 `enum` 关键字定义，每个构造器前加 `|`。枚举值是类型安全的——不会与整数、字符串混淆。

<!-- check:run -->
```cangjie
enum ConnectionState {
    | Disconnected
    | Connecting
    | Connected
    | Failed

    public func isActive(): Bool {
        match (this) {
            case Connected => true
            case _ => false
        }
    }

    public func label(): String {
        match (this) {
            case Disconnected => "未连接"
            case Connecting => "连接中"
            case Connected => "已连接"
            case Failed => "连接失败"
        }
    }
}

main() {
    let states = [
        ConnectionState.Disconnected,
        ConnectionState.Connecting,
        ConnectionState.Connected,
        ConnectionState.Failed
    ]

    for (s in states) {
        println("${s.label()} — 活跃: ${s.isActive()}")
    }
}
```

<!-- expected_output:
未连接 — 活跃: false
连接中 — 活跃: false
已连接 — 活跃: true
连接失败 — 活跃: false
-->

OR 模式（`|`）在 `match` 中合并多个同类情况：

<!-- check:run -->
```cangjie
enum Day {
    | Mon | Tue | Wed | Thu | Fri | Sat | Sun
}

func dayType(d: Day): String {
    match (d) {
        case Sat | Sun => "周末"
        case Mon | Fri => "周一/周五（特殊工作日）"
        case _ => "普通工作日"
    }
}

main() {
    println(dayType(Day.Mon))
    println(dayType(Day.Wed))
    println(dayType(Day.Sat))
    println(dayType(Day.Sun))
}
```

<!-- expected_output:
周一/周五（特殊工作日）
普通工作日
周末
周末
-->

## 2. 带载荷的枚举

枚举构造器可以携带数据——这让每种状态都能附带上下文信息，是仓颉表达"有内容的结果"的核心工具。

<!-- check:run -->
```cangjie
enum ApiError {
    | NetworkError(String)      // 错误描述
    | RateLimited(Int64)        // 可重试的等待秒数
    | AuthFailed
    | ParseError(String)        // 出错的字段名
    | ServerError(Int64, String) // HTTP 状态码 + 描述
}

func describeError(err: ApiError): String {
    match (err) {
        case NetworkError(msg) => "网络错误: ${msg}"
        case RateLimited(secs) => "频率限制，请等待 ${secs} 秒后重试"
        case AuthFailed => "认证失败，请检查 API Key"
        case ParseError(field) => "JSON 解析失败，字段: ${field}"
        case ServerError(code, desc) => "服务器错误 ${code}: ${desc}"
    }
}

main() {
    let errors: Array<ApiError> = [
        ApiError.NetworkError("连接超时 (10s)"),
        ApiError.RateLimited(30),
        ApiError.AuthFailed,
        ApiError.ParseError("choices[0].delta.content"),
        ApiError.ServerError(503, "Service Unavailable")
    ]

    for (err in errors) {
        println(describeError(err))
    }
}
```

<!-- expected_output:
网络错误: 连接超时 (10s)
频率限制，请等待 30 秒后重试
认证失败，请检查 API Key
JSON 解析失败，字段: choices[0].delta.content
服务器错误 503: Service Unavailable
-->

带载荷的枚举也可以有方法，封装重试策略：

<!-- check:run -->
```cangjie
enum ApiError {
    | RateLimited(Int64)   // 等待秒数
    | NetworkError(String)
    | AuthFailed

    public func isRetryable(): Bool {
        match (this) {
            case RateLimited(_) | NetworkError(_) => true
            case AuthFailed => false
        }
    }

    public func retryAfter(): Int64 {
        match (this) {
            case RateLimited(secs) => secs
            case NetworkError(_) => 5    // 网络错误固定等 5 秒
            case AuthFailed => 0
        }
    }
}

main() {
    let err1 = ApiError.RateLimited(60)
    let err2 = ApiError.NetworkError("DNS 解析失败")
    let err3 = ApiError.AuthFailed

    for (err in [err1, err2, err3]) {
        if (err.isRetryable()) {
            println("可重试，等待 ${err.retryAfter()} 秒")
        } else {
            println("不可重试，需要人工处理")
        }
    }
}
```

<!-- expected_output:
可重试，等待 60 秒
可重试，等待 5 秒
不可重试，需要人工处理
-->

## 3. 模式匹配进阶

### 元组模式

`match` 可以同时匹配元组，将多个条件组合为一个分支：

<!-- check:run -->
```cangjie
main() {
    let scenarios: Array<(String, Bool)> = [
        ("kimi", true),
        ("kimi", false),
        ("glm", true),
        ("unknown", false)
    ]

    for ((model, available) in scenarios) {
        let status = match ((model, available)) {
            case ("kimi", true) => "Kimi 就绪"
            case ("glm", true) => "GLM 就绪"
            case (_, true) => "${model} 就绪"
            case (m, false) => "${m} 不可用"
        }
        println(status)
    }
}
```

<!-- expected_output:
Kimi 就绪
kimi 不可用
GLM 就绪
unknown 不可用
-->

### 嵌套枚举解构

枚举的载荷本身也可以是枚举，模式匹配支持深层嵌套：

<!-- check:run -->
```cangjie
enum ModelTier {
    | Free
    | Pro(Int64)    // 每月 Token 配额
}

enum ModelInfo {
    | Available(String, ModelTier)   // 模型名 + 等级
    | Unavailable(String)
}

main() {
    let models: Array<ModelInfo> = [
        ModelInfo.Available("glm-4-flash", ModelTier.Free),
        ModelInfo.Available("glm-4", ModelTier.Pro(1000000)),
        ModelInfo.Unavailable("gpt-4")
    ]

    for (info in models) {
        let desc = match (info) {
            case Available(name, Free) => "${name}: 免费版"
            case Available(name, Pro(quota)) => "${name}: Pro 版（月配额 ${quota} tokens）"
            case Unavailable(name) => "${name}: 暂不支持"
        }
        println(desc)
    }
}
```

<!-- expected_output:
glm-4-flash: 免费版
glm-4: Pro 版（月配额 1000000 tokens）
gpt-4: 暂不支持
-->

## 4. Option 类型

`Option<T>`（简写 `?T`）是仓颉处理"可能缺失的值"的核心工具。它强制你在编译期处理"找不到"的情况，杜绝空指针异常。

<!-- check:run -->
```cangjie
func findModel(alias: String): ?String {
    match (alias) {
        case "kimi" | "moonshot" => Some("moonshot-v1-8k")
        case "glm" | "chatglm" => Some("glm-4-flash")
        case "minimax" | "abab" => Some("abab6.5s-chat")
        case _ => None
    }
}

main() {
    // ?? 运算符：找不到时提供默认值
    let m1 = findModel("kimi") ?? "unknown"
    let m2 = findModel("gpt") ?? "unknown"
    println("kimi → ${m1}")
    println("gpt  → ${m2}")
}
```

<!-- expected_output:
kimi → moonshot-v1-8k
gpt  → unknown
-->

`if-let` 解构 `Option`，只在有值时执行：

<!-- check:run -->
```cangjie
func findModel(alias: String): ?String {
    match (alias) {
        case "kimi" => Some("moonshot-v1-8k")
        case "glm" => Some("glm-4-flash")
        case "minimax" => Some("abab6.5s-chat")
        case _ => None
    }
}

main() {
    let aliases = ["kimi", "glm", "gpt", "minimax"]

    for (alias in aliases) {
        if (let Some(modelId) <- findModel(alias)) {
            println("${alias} → ${modelId}")
        } else {
            println("${alias} → 未找到对应模型")
        }
    }
}
```

<!-- expected_output:
kimi → moonshot-v1-8k
glm → glm-4-flash
gpt → 未找到对应模型
minimax → abab6.5s-chat
-->

`?.` 安全调用与 `??` 链式默认值：

<!-- check:run -->
```cangjie
func findConfig(model: String): ?String {
    match (model) {
        case "moonshot-v1-8k" => Some("apiKey=sk-xxx,endpoint=https://api.moonshot.cn/v1")
        case _ => None
    }
}

main() {
    // findConfig 返回 Option<String>
    // ?? 在 None 时返回默认配置字符串
    let config1 = findConfig("moonshot-v1-8k") ?? "apiKey=,endpoint=https://api.default.com"
    let config2 = findConfig("gpt-4") ?? "apiKey=,endpoint=https://api.default.com"

    println("moonshot 配置: ${config1}")
    println("gpt-4 配置: ${config2}")

    // 结合 if-let 进行非空处理
    if (let Some(cfg) <- findConfig("moonshot-v1-8k")) {
        println("找到配置，长度: ${cfg.size} 字节")
    }
}
```

<!-- expected_output:
moonshot 配置: apiKey=sk-xxx,endpoint=https://api.moonshot.cn/v1
gpt-4 配置: apiKey=,endpoint=https://api.default.com
找到配置，长度: 51 字节
-->

## 5. Role 枚举与命令系统

综合运用本章所有知识，构建 AIChatPro 的角色枚举与完整命令解析系统：

<!-- check:run project=cmd_system -->
```cangjie
// ---- 角色枚举 ----
enum Role {
    | User
    | Assistant
    | System

    public func toApiString(): String {
        match (this) {
            case User => "user"
            case Assistant => "assistant"
            case System => "system"
        }
    }

    public func displayName(): String {
        match (this) {
            case User => "用户"
            case Assistant => "AI 助手"
            case System => "系统"
        }
    }

    public func icon(): String {
        match (this) {
            case User => "👤"
            case Assistant => "🤖"
            case System => "⚙️"
        }
    }
}

// ---- 命令解析结果枚举 ----
enum CommandResult {
    | Help                        // 显示帮助
    | SwitchModel(String)         // 切换模型，携带目标模型名
    | ClearHistory                // 清空历史
    | ShowStats                   // 显示统计
    | Quit                        // 退出
    | UserMessage(String)         // 普通用户消息
    | UnknownCommand(String)      // 未识别的命令

    public func isCommand(): Bool {
        match (this) {
            case UserMessage(_) => false
            case _ => true
        }
    }
}
```

<!-- check:run project=cmd_system -->
```cangjie
// ---- 命令解析函数 ----
func parseModelAlias(alias: String): ?String {
    match (alias) {
        case "kimi" | "moonshot" => Some("moonshot-v1-8k")
        case "glm" | "chatglm" => Some("glm-4-flash")
        case "minimax" | "abab" => Some("abab6.5s-chat")
        case _ => None
    }
}

func parseCommand(input: String): CommandResult {
    let trimmed = input.trimAscii()

    if (!trimmed.startsWith("/")) {
        return CommandResult.UserMessage(trimmed)
    }

    if (trimmed == "/help") {
        CommandResult.Help
    } else if (trimmed == "/clear") {
        CommandResult.ClearHistory
    } else if (trimmed == "/stats") {
        CommandResult.ShowStats
    } else if (trimmed == "/exit" || trimmed == "/quit") {
        CommandResult.Quit
    } else if (trimmed.startsWith("/switch ")) {
        let alias = trimmed[8..]
        let resolved = parseModelAlias(alias) ?? alias
        CommandResult.SwitchModel(resolved)
    } else {
        CommandResult.UnknownCommand(trimmed)
    }
}

func executeCommand(result: CommandResult, currentModel: String): String {
    match (result) {
        case Help =>
            "可用命令:\n  /help          显示此帮助\n  /switch <模型> 切换模型\n  /clear         清空历史\n  /stats         查看统计\n  /exit          退出程序"
        case SwitchModel(m) =>
            "已从 ${currentModel} 切换到 ${m}"
        case ClearHistory =>
            "对话历史已清空"
        case ShowStats =>
            "当前模型: ${currentModel}，运行正常"
        case Quit =>
            "感谢使用 AIChatPro，再见！"
        case UserMessage(msg) =>
            "正在发送给 ${currentModel}: \"${msg}\""
        case UnknownCommand(cmd) =>
            "未知命令: ${cmd}，输入 /help 查看帮助"
    }
}
```

<!-- check:run project=cmd_system -->
```cangjie
main() {
    // 演示 Role 枚举
    println("=== 角色系统 ===")
    let roles = [Role.System, Role.User, Role.Assistant]
    for (role in roles) {
        println("${role.icon()} ${role.displayName()} → API: \"${role.toApiString()}\"")
    }
    println("")

    // 演示命令解析
    println("=== 命令解析 ===")
    let model = "moonshot-v1-8k"
    let inputs = [
        "/help",
        "/switch kimi",
        "/switch glm",
        "/switch unknown-model",
        "/clear",
        "/stats",
        "/exit",
        "/badcmd",
        "你好，仓颉！",
        "  请帮我解释变量作用域  "
    ]

    for (input in inputs) {
        let result = parseCommand(input)
        let tag = if (result.isCommand()) { "[命令]" } else { "[消息]" }
        println("${tag} ${executeCommand(result, model)}")
    }
}
```

<!-- expected_output:
=== 角色系统 ===
⚙️ 系统 → API: "system"
👤 用户 → API: "user"
🤖 AI 助手 → API: "assistant"

=== 命令解析 ===
[命令] 可用命令:
  /help          显示此帮助
  /switch <模型> 切换模型
  /clear         清空历史
  /stats         查看统计
  /exit          退出程序
[命令] 已从 moonshot-v1-8k 切换到 moonshot-v1-8k
[命令] 已从 moonshot-v1-8k 切换到 glm-4-flash
[命令] 已从 moonshot-v1-8k 切换到 unknown-model
[命令] 对话历史已清空
[命令] 当前模型: moonshot-v1-8k，运行正常
[命令] 感谢使用 AIChatPro，再见！
[命令] 未知命令: /badcmd，输入 /help 查看帮助
[消息] 正在发送给 moonshot-v1-8k: "你好，仓颉！"
[消息] 正在发送给 moonshot-v1-8k: "请帮我解释变量作用域"
-->

*   `Role` 枚举将字符串常量 `"user"`, `"assistant"` 升级为类型安全的枚举值，编译期杜绝拼写错误。
*   `CommandResult` 用带载荷的枚举携带参数（如 `SwitchModel("glm-4-flash")`），比返回 `(String, String)` 更具表达力。
*   `parseModelAlias` 返回 `?String`，用 `??` 在别名未找到时回退到原始输入，让 `parseCommand` 保持简洁。
*   `executeCommand` 是 `match` 的完美用例：穷举所有分支，编译器会提示遗漏的情况。

## 工程化提示

*   **枚举替代魔法字符串**：`Role.User` 优于 `"user"`，`CommandResult.Quit` 优于 `"quit"`。枚举让编译器成为你的守门人。
*   **穷举 `match`**：不加 `case _` 通配符时，编译器强制覆盖所有枚举分支，新增枚举值时编译错误会提示所有需要更新的地方。
*   **`Option` 而非 `null`**：仓颉没有隐式 null，用 `?T` 表达"可能为空"，调用方必须显式处理 `None`，从根源消除空指针。
*   **`??` 提供合理默认值**：`findModel(alias) ?? alias` 让未知别名降级为直接使用原字符串，避免硬性失败。
*   **带载荷枚举 vs 结构体**：当"状态变体"数量确定且每种变体形状不同时，用枚举；当所有变体共享相同字段时，用结构体 + 枚举字段。

## 实践挑战

1. 为 `Role` 枚举添加 `fromApiString(s: String): ?Role` 静态方法，将 `"user"` 转回 `Role.User`（提示：`match` 返回 `Option`）。
2. 扩展 `CommandResult`，新增 `SetSystemPrompt(String)` 变体，对应 `/system <内容>` 命令，并在 `parseCommand` 和 `executeCommand` 中处理它。
3. 用 `if-let` 链改写 `executeCommand` 中 `SwitchModel` 的处理：先用 `parseModelAlias` 查找别名，找到则显示友好名，找不到则显示原始 ID。
4. 思考：为什么 `CommandResult.UserMessage(String)` 比让 `parseCommand` 返回 `?CommandResult`（找不到命令时返回 `None`）更好？列举两个理由。
