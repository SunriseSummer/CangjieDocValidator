# 01. 你好，仓颉！初识语言与项目启动

> 千里之行，始于 `println("你好，仓颉！")`。每一个伟大的工具都从第一行代码开始。今天，我们踏出构建 AIChatPro 命令行 AI 对话工具的第一步。

## 本章目标

*   运行第一个仓颉程序，感受语言的简洁与直接。
*   理解 `let`（不可变）与 `var`（可变）的本质区别。
*   掌握字符串插值语法，让输出更具表达力。
*   构建 AIChatPro 的启动横幅，完成项目的"第一印象"。

## 1. 第一个仓颉程序

仓颉程序的入口是 `main()` 函数。它不需要类、不需要命名空间，直接定义、直接运行。

<!-- check:run -->
```cangjie
main() {
    println("你好，仓颉！")
    println("Hello, Cangjie!")
}
```

<!-- expected_output:
你好，仓颉！
Hello, Cangjie!
-->

*   `main()` 是整个程序的唯一入口，保持它"清晰、简洁、可读"。
*   `println` 输出一行文字并自动换行；`print` 则不换行。
*   仓颉天然支持 UTF-8，中文字符与英文字符同等对待。

再试一个多行输出：

<!-- check:run -->
```cangjie
main() {
    print("AIChatPro ")
    print("v1.0.0 ")
    println("启动中...")
    println("初始化完成。")
}
```

<!-- expected_output:
AIChatPro v1.0.0 启动中...
初始化完成。
-->

## 2. 变量：let 与 var

仓颉用 `let` 声明**不可变**绑定，用 `var` 声明**可变**变量。这一设计鼓励你优先使用不可变量，让程序更容易推理。

<!-- check:run -->
```cangjie
main() {
    let toolName = "AIChatPro"   // 不可变，类型推断为 String
    var version = "1.0.0"        // 可变，类型推断为 String

    println("工具: ${toolName}")
    println("版本: ${version}")

    version = "1.0.1"            // 更新版本号
    println("升级后版本: ${version}")
}
```

<!-- expected_output:
工具: AIChatPro
版本: 1.0.0
升级后版本: 1.0.1
-->

也可以显式声明类型，这在类型不能被推断时是必须的：

<!-- check:run -->
```cangjie
main() {
    let maxTokens: Int64 = 4096
    let temperature: Float64 = 0.7
    let streaming: Bool = true
    let modelName: String = "moonshot-v1-8k"

    println("最大 Token: ${maxTokens}")
    println("流式输出: ${streaming}")
    println("模型: ${modelName}")
}
```

<!-- expected_output:
最大 Token: 4096
流式输出: true
模型: moonshot-v1-8k
-->

> **类型推断规则**：整数字面量默认推断为 `Int64`，浮点数默认推断为 `Float64`，布尔值为 `Bool`，字符串为 `String`。大多数情况下无需手动标注类型。

## 3. 字符串插值

仓颉使用 `${}` 语法将任意表达式嵌入字符串，告别繁琐的字符串拼接。

<!-- check:run -->
```cangjie
main() {
    let model = "Kimi"
    let provider = "Moonshot AI"
    let maxTokens = 8192

    // 直接插入变量
    println("当前模型: ${model}")

    // 插入表达式
    println("提供商: ${provider}，上下文窗口: ${maxTokens} tokens")

    // 插入计算结果
    let usedTokens = 1024
    println("已使用: ${usedTokens}，剩余: ${maxTokens - usedTokens}")
}
```

<!-- expected_output:
当前模型: Kimi
提供商: Moonshot AI，上下文窗口: 8192 tokens
已使用: 1024，剩余: 7168
-->

字符串也可以多行拼接，用 `+` 或多次 `println`：

<!-- check:run -->
```cangjie
main() {
    let user = "仓颉学习者"
    let model = "GLM"
    let greeting = "你好，" + user + "！"
    let info = "正在使用 ${model} 模型进行对话。"

    println(greeting)
    println(info)
    println("输入你的问题，按 Enter 发送。")
}
```

<!-- expected_output:
你好，仓颉学习者！
正在使用 GLM 模型进行对话。
输入你的问题，按 Enter 发送。
-->

## 4. 构建启动横幅

AIChatPro 启动时需要展示一个醒目的横幅，告诉用户工具的名称、版本和基本用法。我们把这段逻辑封装为 `printBanner()` 函数。

先看一个基础版本：

<!-- check:run -->
```cangjie
func printBanner() {
    println("==============================")
    println("     AIChatPro  v1.0.0")
    println("  多模型 AI 对话命令行工具")
    println("==============================")
    println("支持模型: Kimi / GLM / Minimax")
    println("输入 /help 查看帮助，输入 /exit 退出")
}

main() {
    printBanner()
}
```

<!-- expected_output:
==============================
     AIChatPro  v1.0.0
  多模型 AI 对话命令行工具
==============================
支持模型: Kimi / GLM / Minimax
输入 /help 查看帮助，输入 /exit 退出
-->

进阶版本：让横幅接受版本号参数，方便未来升级：

<!-- check:run -->
```cangjie
func printBanner(version: String) {
    let line = "=============================="
    println(line)
    println("     AIChatPro  v${version}")
    println("  多模型 AI 对话命令行工具")
    println(line)
}

func printWelcome(model: String) {
    println("当前模型: ${model}")
    println("输入 /help 查看可用命令")
    println("")
}

main() {
    printBanner("1.0.0")
    printWelcome("moonshot-v1-8k")
    println("AIChatPro 已就绪，请开始对话。")
}
```

<!-- expected_output:
==============================
     AIChatPro  v1.0.0
  多模型 AI 对话命令行工具
==============================
当前模型: moonshot-v1-8k
输入 /help 查看可用命令

AIChatPro 已就绪，请开始对话。
-->

*   函数用 `func` 关键字定义，参数格式为 `名称: 类型`。
*   函数体的最后一个表达式即为返回值（无需 `return`）。
*   将横幅与欢迎信息分为两个函数，职责更清晰，便于复用。

## 工程化提示

*   **函数命名清晰**：`printBanner`、`printWelcome` 直接表达意图，比 `output1`、`display` 更专业。
*   **不可变优先**：能用 `let` 的地方就不用 `var`，减少意外修改的风险。
*   **字符串插值 vs 拼接**：`"v${version}"` 比 `"v" + version` 更易读，优先使用插值。
*   **`main()` 保持简洁**：`main` 是调度中心，不应堆放业务细节，用函数拆分职责。
*   **常量集中管理**：将版本号、工具名等常量定义为 `let` 变量，便于统一更新。

## 实践挑战

1. 为 `printBanner` 添加 `author` 参数，在横幅中显示作者信息。
2. 将 `"=============================="`（30 个等号）提取为一个 `let` 常量 `separator`，在多处复用。
3. 新增 `printStartupInfo()` 函数，打印"系统时间"占位符（用字符串常量模拟）、已加载的模型数量（用整数变量）。
4. 思考：如果未来需要在横幅中显示彩色文字，应该修改哪个函数？如何设计才能让调用方不受影响？
