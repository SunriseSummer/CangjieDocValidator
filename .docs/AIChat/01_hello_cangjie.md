# 01. 你好，仓颉！初识语言与项目启动

> 千里之行，始于 `println("你好，仓颉！")`。每一个伟大的工具都从第一行代码开始。今天，我们踏出构建 AIChatPro 命令行 AI 对话工具的第一步。

---

## 写在最前面：你将构建什么？

在传统的语言教程中，你会学到变量、函数、类型——然后把它们丢在脑后，因为你不知道该用它们做什么。**本系列课程不同。** 我们采用「项目驱动学习」的方式，从第一行代码开始，每一章都在构建一个真实可用的工具——**AIChatPro**。

### AIChatPro 是什么？

AIChatPro 是一个**多模型 AI 命令行对话工具**，完全使用仓颉语言从零构建。它不是一个玩具项目，而是一个具备工程完整性的实用工具：

- **多模型支持**：接入 Kimi（月之暗面）、GLM（智谱 AI）、Minimax 等多个国产大模型，一键切换
- **流式输出**：逐 token 实时显示 AI 回复，体验如丝般顺滑的打字机效果
- **对话历史管理**：自动维护上下文，支持多轮连续对话
- **斜杠命令系统**：`/model`、`/clear`、`/history`、`/help`……用命令掌控一切
- **模型热切换**：对话中随时切换模型，无需重启

当你完成全部课程，打开终端运行 AIChatPro，你将看到这样的画面：

```
==============================
     AIChatPro  v1.0.0
  多模型 AI 对话命令行工具
==============================
当前模型: moonshot-v1-8k
输入 /help 查看可用命令

You> 用一句话介绍仓颉编程语言
AI>  仓颉是华为自研的面向全场景的新一代编程语言，
     兼具静态类型安全与现代语言的简洁表达力。
You> /model glm-4-flash
✓ 已切换到模型: glm-4-flash
You> 同样的问题，你怎么看？
AI>  仓颉编程语言是华为推出的新一代通用编程语言，
     旨在为开发者提供高效、安全且易用的编程体验。
You> /exit
再见！对话已保存。
```

### 项目架构

完整的 AIChatPro 采用仓颉的包管理系统组织代码，分为五个职责清晰的子包：

```
AIChatPro 架构
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   ReplRunner │────▶│ BaseChatModel│────▶│  StreamEngine │
│  (交互循环)  │     │  (模型接口)   │     │  (流式显示)   │
└──────┬──────┘     └──────┬───────┘     └──────┬───────┘
       │                   │                    │
       ▼                   ▼                    ▼
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│ConfigManager│     │  KimiModel   │     │   CharQueue   │
│ (配置管理)   │     │  (Kimi实现)   │     │  (字符队列)   │
└─────────────┘     └──────────────┘     └──────────────┘
```

### 学习路线图

每一章围绕一个**语言核心概念**，同时推进项目的一个**功能模块**。学完即用，概念不再悬空：

| 章节 | 语言主题 | 项目模块 | 你将获得 |
|------|---------|---------|---------|
| 01 · 本章 | 变量、函数、字符串插值 | 启动横幅 | 第一个可运行的仓颉程序 |
| 02 | 集合与控制流 | 对话历史管理 | ArrayList、for-in、模式匹配 |
| 03 | 函数与 Lambda | 消息格式化器 | 高阶函数、闭包、管道运算符 |
| 04 | 结构体与值语义 | HTTP 请求构建 | struct、方法、值类型设计 |
| 05 | 类与继承 | 多模型抽象层 | class、多态、工厂模式 |
| 06 | 接口与泛型 | 统一模型协议 | interface、泛型约束、类型安全 |
| 07 | 异常与资源管理 | 流式显示引擎 | try-catch、资源释放、错误恢复 |
| 08 | 枚举与模式匹配 | REPL 命令系统 | enum、match、命令解析 |
| 09 | 包管理与集成 | 最终集成 | cjpm、模块化、完整项目 |

> 💡 **学习建议**：每一章都可以独立运行其中的代码示例。但当你按顺序完成全部九章后，这些零散的知识碎片将拼合成一个完整的、可交付的工程项目。这就是项目驱动学习的力量。

---

## 本章目标

*   运行第一个仓颉程序，感受语言的简洁与直接。
*   理解 `let`（不可变）与 `var`（可变）的本质区别。
*   掌握字符串插值语法，让输出更具表达力。
*   构建 AIChatPro 的启动横幅，完成项目的"第一印象"。

## 1. 第一个仓颉程序

万事皆有起点。在仓颉的世界里，这个起点就是 `main()` 函数——它不需要类、不需要命名空间、不需要任何仪式感。直接定义，直接运行。这种"零样板代码"的设计哲学，让你把注意力放在真正重要的事情上：解决问题。

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
*   仓颉天然支持 UTF-8，中文字符与英文字符同等对待——这对于我们后续处理 AI 的中文回复至关重要。

两行代码，零配置，输出直达终端。如果你用过 Java，可能还在回忆 `public static void main(String[] args)` 的拼写；仓颉已经跑完了。

接下来，让我们试试 `print` 与 `println` 的配合——这正是 AIChatPro 中"流式输出"效果的雏形：

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

注意前两个 `print` 的输出是如何拼接在同一行的——`print` 不换行，`println` 才换行。在 AIChatPro 的流式显示模块中，我们会大量使用 `print` 来逐字符输出 AI 的回复，营造"正在思考、逐步生成"的交互体验。

## 2. 变量：let 与 var

在构建 AIChatPro 时，有些值一旦确定就不应改变（比如工具名称），有些则需要随运行时状态更新（比如版本号、当前模型）。仓颉用两个关键字精确地表达了这种区分：`let` 声明**不可变**绑定，`var` 声明**可变**变量。这一设计鼓励你优先使用不可变量，让程序状态更容易推理、更不容易出错。

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

请注意第三行输出：`version` 被重新赋值为 `"1.0.1"`，而 `toolName` 作为 `let` 绑定，一旦赋值便不可更改——如果你尝试 `toolName = "Other"`，编译器会直接拒绝。这种"编译期保护"机制，在大型项目中价值巨大。

在实际开发中，AI 模型的参数配置往往需要精确的类型控制。仓颉支持显式类型标注，这在类型不能被推断、或者你希望代码更具自文档性时尤为有用：

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

这些参数——`maxTokens`、`temperature`、`streaming`、`modelName`——在后续章节中会反复出现。它们将成为 AIChatPro 配置系统的核心字段。现在先记住它们的类型，未来你会在 `struct ConfigManager` 中再次遇见它们。

## 3. 字符串插值

一个优秀的命令行工具，离不开清晰、美观的信息输出。想象 AIChatPro 需要显示"当前模型: Kimi，剩余 Token: 7168"这样的动态信息——如果只能用字符串拼接，代码会变得冗长且脆弱。仓颉使用 `${}` 语法将任意表达式嵌入字符串，让输出代码既简洁又直观：

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

注意第三行：`${maxTokens - usedTokens}` 直接在字符串中完成了算术运算。插值表达式不限于简单变量——任何合法的仓颉表达式都可以放入 `${}` 中。这种表达力在构建 AI 对话界面时极为实用：你可以在一行代码中组装出包含模型名、Token 用量、响应时间等多个动态字段的状态行。

当然，字符串也可以通过 `+` 运算符拼接。两种方式各有适用场景——短表达式用插值更清爽，多段独立内容用拼接更清晰：

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

这段代码模拟了 AIChatPro 的用户问候场景。注意 `greeting` 使用了 `+` 拼接，而 `info` 使用了 `${}` 插值——在实际项目中，我们会统一采用插值风格，因为它在参数变多时依然保持可读性。

## 4. 构建启动横幅

理论学够了，是时候动手构建 AIChatPro 的第一个真实组件。

每一个专业的命令行工具都有一个醒目的启动横幅（Banner）——它是用户打开工具时看到的第一样东西，决定了工具的"第一印象"。AIChatPro 的横幅需要展示工具名称、版本号和基本用法。我们用今天学到的函数、字符串插值和变量，来实现它。

先看一个基础版本——将横幅逻辑封装为 `printBanner()` 函数，让 `main()` 保持简洁：

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

基础版本虽然能工作，但版本号 `"v1.0.0"` 是硬编码的——每次升级都要修改函数内部。这违反了"开闭原则"。让我们用参数化的方式重构它，同时将职责进一步拆分为"横幅"和"欢迎信息"两个独立函数：

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

> 💡 这段代码已经具备了 AIChatPro 启动模块的雏形。在第 9 章的最终集成中，`printBanner` 会从配置文件读取版本号，`printWelcome` 会显示真实的模型名称——但它们的函数签名不需要改变。**好的 API 设计，从第一天就开始。**

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
