# 02. 类型系统与控制流：解析用户命令

> AI 对话工具的灵魂在于"理解用户意图"。控制流让程序学会判断，类型系统确保数据始终正确。本章我们用仓颉的类型与控制流，构建 AIChatPro 的命令解析器。

## 本章目标

*   掌握仓颉的基础类型：`Int64`、`Float64`、`Bool`、`String`。
*   理解 `if/else` 作为**表达式**的强大之处。
*   用 `match` 实现清晰的分支逻辑。
*   通过 `for` 和 `while` 循环处理批量输入。
*   构建 AIChatPro 的命令解析函数。

## 1. 基础类型

仓颉内置四种最常用的基础类型，覆盖 AI 对话工具的大部分数据表达需求。

<!-- check:run -->
```cangjie
main() {
    // 整数：Int64（默认）
    let messageCount: Int64 = 42
    let maxContextLength = 8192        // 类型推断为 Int64

    // 浮点数：Float64（默认）
    let temperature = 0.8              // 类型推断为 Float64

    // 布尔：Bool
    let streamingEnabled = true
    let debugMode: Bool = false

    // 字符串：String
    let currentModel = "moonshot-v1-8k"
    let apiEndpoint: String = "https://api.moonshot.cn/v1"

    println("消息数: ${messageCount}")
    println("上下文长度: ${maxContextLength}")
    println("流式输出: ${streamingEnabled}")
    println("调试模式: ${debugMode}")
    println("模型: ${currentModel}")
}
```

<!-- expected_output:
消息数: 42
上下文长度: 8192
流式输出: true
调试模式: false
模型: moonshot-v1-8k
-->

整数与浮点数之间需要显式转换，避免精度陷阱：

<!-- check:run -->
```cangjie
main() {
    let usedTokens: Int64 = 1500
    let maxTokens: Int64 = 4096

    // Int64 转 Float64 进行浮点运算
    let ratio = Float64(usedTokens) / Float64(maxTokens)
    let percent: Int64 = usedTokens * 100 / maxTokens

    println("使用率: ${percent}%")
}
```

<!-- expected_output:
使用率: 36%
-->

## 2. if/else 表达式

仓颉的 `if/else` 不只是语句——它是**表达式**，可以直接赋值给变量。这让代码更紧凑，也避免了可变变量的泛滥。

<!-- check:run -->
```cangjie
main() {
    let usedTokens = 500
    let maxTokens = 4096

    // if/else 作为表达式，直接赋值
    let status = if (usedTokens > maxTokens) {
        "超出限制"
    } else if (usedTokens > maxTokens * 3 / 4) {
        "接近上限"
    } else if (usedTokens > 100) {
        "正常使用"
    } else {
        "几乎为空"
    }

    println("Token 状态: ${status}")
}
```

<!-- expected_output:
Token 状态: 正常使用
-->

再看一个实际场景：根据模型名称判断是否支持长上下文：

<!-- check:run -->
```cangjie
main() {
    let model = "moonshot-v1-8k"

    let contextWindow = if (model == "moonshot-v1-128k") {
        128000
    } else if (model == "moonshot-v1-32k") {
        32000
    } else if (model == "moonshot-v1-8k") {
        8000
    } else {
        4096
    }

    let label = if (contextWindow >= 32000) { "长上下文" } else { "标准上下文" }
    println("模型 ${model}: ${contextWindow} tokens（${label}）")
}
```

<!-- expected_output:
模型 moonshot-v1-8k: 8000 tokens（标准上下文）
-->

## 3. match 表达式

`match` 是仓颉最强大的控制流工具。它比 `if/else if` 链更清晰，强制覆盖所有分支，杜绝遗漏。

<!-- check:run -->
```cangjie
func modelProvider(model: String): String {
    match (model) {
        case "moonshot-v1-8k" | "moonshot-v1-32k" | "moonshot-v1-128k" => "Moonshot AI"
        case "glm-4-flash" | "glm-4" => "智谱 AI"
        case "abab6.5s-chat" | "abab5.5-chat" => "Minimax"
        case _ => "未知提供商"
    }
}

main() {
    let models = ["moonshot-v1-8k", "glm-4-flash", "abab6.5s-chat", "gpt-4"]
    for (m in models) {
        println("${m} → ${modelProvider(m)}")
    }
}
```

<!-- expected_output:
moonshot-v1-8k → Moonshot AI
glm-4-flash → 智谱 AI
abab6.5s-chat → Minimax
gpt-4 → 未知提供商
-->

`match` 同样是表达式，可以嵌入到字符串插值或赋值中：

<!-- check:run -->
```cangjie
main() {
    let errorCode = 429

    let message = match (errorCode) {
        case 200 => "请求成功"
        case 400 => "请求格式错误"
        case 401 => "API Key 无效，请检查配置"
        case 429 => "请求频率超限，请稍后重试"
        case 500 => "服务器内部错误"
        case _ => "未知错误 (${errorCode})"
    }

    println("HTTP ${errorCode}: ${message}")
}
```

<!-- expected_output:
HTTP 429: 请求频率超限，请稍后重试
-->

## 4. 循环

### for-in 循环

仓颉的 `for-in` 可以遍历数组、区间（Range）等任何可迭代对象。

<!-- check:run -->
```cangjie
main() {
    // 遍历数组
    let supportedModels = ["Kimi", "GLM", "Minimax"]
    println("支持的模型:")
    for (model in supportedModels) {
        println("  - ${model}")
    }
}
```

<!-- expected_output:
支持的模型:
  - Kimi
  - GLM
  - Minimax
-->

用 `0..n` 区间遍历索引（不含末尾），`0..=n` 含末尾：

<!-- check:run -->
```cangjie
main() {
    let models = ["Kimi", "GLM", "Minimax"]

    // 0..3 生成 0, 1, 2（不含 3）
    for (i in 0..models.size) {
        println("模型 ${i + 1}: ${models[i]}")
    }
}
```

<!-- expected_output:
模型 1: Kimi
模型 2: GLM
模型 3: Minimax
-->

### while 循环

`while` 用于条件不确定的循环，例如重试逻辑：

<!-- check:run -->
```cangjie
main() {
    var retryCount = 0
    let maxRetries = 3
    var success = false

    while (retryCount < maxRetries && !success) {
        retryCount = retryCount + 1
        println("第 ${retryCount} 次尝试连接...")

        // 模拟第 2 次成功
        if (retryCount == 2) {
            success = true
        }
    }

    if (success) {
        println("连接成功！")
    } else {
        println("连接失败，已达最大重试次数。")
    }
}
```

<!-- expected_output:
第 1 次尝试连接...
第 2 次尝试连接...
连接成功！
-->

## 5. 命令解析器

AIChatPro 支持 `/help`、`/switch`、`/clear`、`/exit` 等斜杠命令。用 `match` 构建命令解析函数，逻辑清晰、易于扩展。

<!-- check:run -->
```cangjie
func handleCommand(cmd: String): String {
    match (cmd) {
        case "/help" => "可用命令: /help  /switch <模型>  /clear  /exit"
        case "/clear" => "对话历史已清空"
        case "/exit" => "再见！感谢使用 AIChatPro"
        case _ => if (cmd.startsWith("/")) {
            "未知命令: ${cmd}，输入 /help 查看帮助"
        } else {
            "请以 / 开头输入命令"
        }
    }
}

main() {
    let testInputs = ["/help", "/switch", "/clear", "/exit", "/unknown", "你好"]
    for (input in testInputs) {
        println("> ${input}")
        println("  ${handleCommand(input)}")
    }
}
```

<!-- expected_output:
> /help
  可用命令: /help  /switch <模型>  /clear  /exit
> /switch
  未知命令: /switch，输入 /help 查看帮助
> /clear
  对话历史已清空
> /exit
  再见！感谢使用 AIChatPro
> /unknown
  未知命令: /unknown，输入 /help 查看帮助
> 你好
  请以 / 开头输入命令
-->

结合类型和控制流，构建一个完整的命令分发演示：

<!-- check:run -->
```cangjie
func parseModelAlias(alias: String): String {
    match (alias) {
        case "kimi" | "moonshot" => "moonshot-v1-8k"
        case "glm" | "chatglm" => "glm-4-flash"
        case "minimax" | "abab" => "abab6.5s-chat"
        case _ => alias   // 直接当作模型 ID 使用
    }
}

func dispatch(input: String, currentModel: String): String {
    if (input == "/help") {
        "命令: /help /switch <模型> /clear /exit"
    } else if (input == "/clear") {
        "已清空 ${currentModel} 的对话历史"
    } else if (input == "/exit") {
        "退出 AIChatPro"
    } else if (input.startsWith("/switch ")) {
        let alias = input[8..]
        let resolved = parseModelAlias(alias)
        "已切换到模型: ${resolved}"
    } else if (input.startsWith("/")) {
        "未知命令: ${input}"
    } else {
        "发送给 ${currentModel}: ${input}"
    }
}

main() {
    let model = "moonshot-v1-8k"
    let inputs = ["/help", "/switch kimi", "/switch glm", "/clear", "你好世界"]
    for (input in inputs) {
        println(dispatch(input, model))
    }
}
```

<!-- expected_output:
命令: /help /switch <模型> /clear /exit
已切换到模型: moonshot-v1-8k
已切换到模型: glm-4-flash
已清空 moonshot-v1-8k 的对话历史
发送给 moonshot-v1-8k: 你好世界
-->

*   `input[8..]` 从字节索引 8 处截取字符串（`/switch ` 正好是 8 个 ASCII 字节）。
*   `startsWith("/switch ")` 包含末尾空格，确保 `/switch` 后必须有模型名。
*   多个 `case` 用 `|` 合并，避免重复逻辑。

## 工程化提示

*   **`match` 优于长 `if/else` 链**：分支超过 3 个时，`match` 的可读性远胜 `if/else if`，且不会遗漏分支。
*   **表达式赋值减少 `var`**：用 `let x = if (...) { ... } else { ... }` 代替 `var x; if ... x = ...`。
*   **命令解析单一职责**：`handleCommand` 只负责解析，不负责执行，实际执行交给调用方。
*   **统一命令前缀**：所有命令用 `/` 开头，便于与普通消息区分，`startsWith("/")` 一行即可判断。
*   **类型安全的分支**：`match` 搭配 `_` 通配符处理默认情况，确保所有输入都有响应。

## 实践挑战

1. 为 `handleCommand` 新增 `/models` 命令，返回支持的模型列表（硬编码字符串即可）。
2. 修改 `parseModelAlias`，为 `"minimax"` 添加别名 `"mm"`。
3. 用 `for-in` 遍历一个整数数组 `[1, 2, 3, 4, 5]`，只打印偶数（提示：用 `if` + 取余运算 `%`）。
4. 思考：如果命令列表会动态增减，`match` 硬编码的方式有什么缺点？可以用什么数据结构改进？
