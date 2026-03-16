# 03. 函数与 Lambda：消息格式化器

> 函数是逻辑的契约，Lambda 是策略的表达。好的函数设计让 AI 对话系统的每一个转换步骤都清晰可替换——今天我们为 AIChatPro 构建消息格式化工具链。

## 本章目标

*   掌握仓颉函数的定义、调用与隐式返回。
*   使用命名参数和默认值提升 API 可读性。
*   用 Lambda 表达式封装可传递的逻辑片段。
*   理解闭包如何捕获外部变量，构建高阶函数。
*   用管道运算符 `|>` 组合多步转换。
*   构建 AIChatPro 的消息格式化器。

## 1. 函数定义与调用

仓颉函数用 `func` 关键字定义，函数体的**最后一个表达式**即为返回值，无需显式 `return`。

<!-- check:run -->
```cangjie
func greet(name: String): String {
    "你好，${name}！"   // 隐式返回
}

func add(a: Int64, b: Int64): Int64 {
    return a + b       // 也可以显式 return
}

func describe(model: String, tokens: Int64): String {
    let label = if (tokens >= 32000) { "长上下文" } else { "标准" }
    "${model}（${label}，${tokens} tokens）"
}

main() {
    println(greet("仓颉"))
    println("1 + 2 = ${add(1, 2)}")
    println(describe("moonshot-v1-8k", 8000))
    println(describe("moonshot-v1-128k", 128000))
}
```

<!-- expected_output:
你好，仓颉！
1 + 2 = 3
moonshot-v1-8k（标准，8000 tokens）
moonshot-v1-128k（长上下文，128000 tokens）
-->

返回 `Unit` 的函数（即无返回值的过程）可以省略返回类型声明：

<!-- check:run -->
```cangjie
func printSeparator() {
    println("----------------------------")
}

func printModelInfo(model: String, provider: String) {
    printSeparator()
    println("模型: ${model}")
    println("提供商: ${provider}")
    printSeparator()
}

main() {
    printModelInfo("glm-4-flash", "智谱 AI")
}
```

<!-- expected_output:
----------------------------
模型: glm-4-flash
提供商: 智谱 AI
----------------------------
-->

## 2. 命名参数与默认值

仓颉支持**命名参数**（在参数名后加 `!`），调用时必须写出参数名，大幅提升可读性，避免参数顺序错误。

<!-- check:run -->
```cangjie
// role! 和 content! 是命名参数，调用时必须写名字
func buildMessage(role!: String, content!: String): String {
    "[${role}] ${content}"
}

main() {
    // 调用时必须写参数名，顺序可以调换
    println(buildMessage(role: "user", content: "你好"))
    println(buildMessage(content: "你是 AI 助手", role: "system"))
}
```

<!-- expected_output:
[user] 你好
[system] 你是 AI 助手
-->

**默认参数值**让常用场景更简洁：

<!-- check:run -->
```cangjie
func createRequest(
    model!: String = "moonshot-v1-8k",
    maxTokens!: Int64 = 2048,
    temperature!: Int64 = 1
): String {
    "模型=${model}, maxTokens=${maxTokens}, temperature=${temperature}"
}

main() {
    // 全部使用默认值
    println(createRequest())

    // 只覆盖 model
    println(createRequest(model: "glm-4-flash"))

    // 只覆盖 maxTokens
    println(createRequest(maxTokens: 4096))

    // 覆盖全部
    println(createRequest(model: "abab6.5s-chat", maxTokens: 1024, temperature: 0))
}
```

<!-- expected_output:
模型=moonshot-v1-8k, maxTokens=2048, temperature=1
模型=glm-4-flash, maxTokens=2048, temperature=1
模型=moonshot-v1-8k, maxTokens=4096, temperature=1
模型=abab6.5s-chat, maxTokens=1024, temperature=0
-->

*   命名参数的定义用 `param!: Type`，调用时用 `func(param: value)`。
*   默认值紧跟参数类型后：`param!: Type = defaultValue`。
*   调用时未提供的命名参数自动使用默认值。

## 3. Lambda 表达式

Lambda 是匿名函数，可以赋值给变量、作为参数传递。语法为 `{ 参数 => 函数体 }`。

<!-- check:run -->
```cangjie
main() {
    // 带类型注解的 Lambda
    let double = { x: Int64 => x * 2 }
    let greet = { name: String => "你好，${name}" }

    println(double(21))
    println(greet("仓颉"))

    // 类型可推断时省略注解
    let isCommand = { s: String => s.startsWith("/") }
    println(isCommand("/help"))
    println(isCommand("你好"))
}
```

<!-- expected_output:
42
你好，仓颉
true
false
-->

Lambda 可以直接用于数组操作等场景：

<!-- check:run -->
```cangjie
func applyToAll(items: Array<String>, transform: (String) -> String): Array<String> {
    var result = Array<String>(items.size, item: "")
    for (i in 0..items.size) {
        result[i] = transform(items[i])
    }
    return result
}

main() {
    let models = ["kimi", "glm", "minimax"]

    // 传入 Lambda 作为 transform
    let upper = applyToAll(models) { s => s.toAsciiUpper() }
    for (m in upper) {
        println(m)
    }
}
```

<!-- expected_output:
KIMI
GLM
MINIMAX
-->

## 4. 闭包与高阶函数

**闭包**是能捕获外部变量的 Lambda。**高阶函数**是接受或返回函数的函数，两者配合可以构建灵活的策略模式。

<!-- check:run -->
```cangjie
// makeGreeter 返回一个闭包，闭包捕获了 prefix
func makeGreeter(prefix: String): (String) -> String {
    { name => "${prefix}，${name}！" }
}

main() {
    let chineseGreeter = makeGreeter("你好")
    let formalGreeter = makeGreeter("尊敬的用户")

    println(chineseGreeter("仓颉"))
    println(chineseGreeter("工程师"))
    println(formalGreeter("管理员"))
}
```

<!-- expected_output:
你好，仓颉！
你好，工程师！
尊敬的用户，管理员！
-->

高阶函数在消息过滤中的应用：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

func filterList(items: ArrayList<String>, keep: (String) -> Bool): ArrayList<String> {
    let result = ArrayList<String>()
    for (item in items) {
        if (keep(item)) {
            result.add(item)
        }
    }
    return result
}

main() {
    let history = ArrayList<String>()
    history.add("你好")
    history.add("")
    history.add("请帮我写代码")
    history.add("")
    history.add("谢谢")

    // 传入 Lambda 作为过滤条件
    let nonEmpty = filterList(history) { msg => !msg.isEmpty() }
    println("有效消息数: ${nonEmpty.size}")
    for (msg in nonEmpty) {
        println("  [${msg}]")
    }
}
```

<!-- expected_output:
有效消息数: 3
  [你好]
  [请帮我写代码]
  [谢谢]
-->

## 5. 管道运算符

管道运算符 `|>` 将左侧值作为第一个参数传入右侧函数，让多步数据转换像流水线一样直观。

<!-- check:run -->
```cangjie
func trimMsg(s: String): String { s.trimAscii() }
func addUserTag(s: String): String { "[user]: ${s}" }
func appendNewline(s: String): String { "${s}\n" }

main() {
    // 不用管道：嵌套调用，从右到左读
    let v1 = addUserTag(trimMsg("  你好，仓颉！  "))
    println(v1)

    // 用管道：从左到右，一目了然
    let v2 = "  你好，仓颉！  " |> trimMsg |> addUserTag
    println(v2)
}
```

<!-- expected_output:
[user]: 你好，仓颉！
[user]: 你好，仓颉！
-->

更复杂的管道链：

<!-- check:run -->
```cangjie
func normalize(s: String): String { s.trimAscii() }
func wrapJson(s: String): String { "{\"content\": \"${s}\"}" }
func addRole(s: String): String { "user: ${s}" }

main() {
    let rawInput = "  请解释仓颉语言的特点  "

    let result = rawInput
        |> normalize
        |> addRole
        |> wrapJson

    println(result)
}
```

<!-- expected_output:
{"content": "user: 请解释仓颉语言的特点"}
-->

## 6. 消息格式化器

将本章知识综合运用，为 AIChatPro 构建完整的消息格式化工具链：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

// 单条消息的 JSON 格式化
func formatMessage(role!: String, content!: String): String {
    "{\"role\": \"${role}\", \"content\": \"${content}\"}"
}

// 快捷构造器：命名参数 + 默认值
func userMessage(content!: String): String {
    formatMessage(role: "user", content: content)
}

func systemMessage(content!: String): String {
    formatMessage(role: "system", content: content)
}

func assistantMessage(content!: String): String {
    formatMessage(role: "assistant", content: content)
}

// 内容预处理管道
func trimContent(s: String): String { s.trimAscii() }
func sanitize(s: String): String {
    // 简化处理：将双引号替换为单引号，避免 JSON 注入
    var result = StringBuilder()
    for (ch in s.runes()) {
        if (ch == r'"') {
            result.append("'")
        } else {
            result.append(ch)
        }
    }
    result.toString()
}

// 构建请求体（简化版，仅展示消息列表格式）
func buildRequestBody(model: String, messages: ArrayList<String>): String {
    var body = StringBuilder()
    body.append("{\"model\": \"${model}\", \"messages\": [")
    for (i in 0..messages.size) {
        if (i > 0) { body.append(", ") }
        body.append(messages[i])
    }
    body.append("]}")
    body.toString()
}

main() {
    // 演示各格式化函数
    println(userMessage(content: "你好"))
    println(systemMessage(content: "你是仓颉语言助手"))
    println(assistantMessage(content: "你好，我是 AI 助手"))
    println("")

    // 演示内容预处理管道
    let rawInput = "  请帮我写一个 \"Hello World\"  "
    let clean = rawInput |> trimContent |> sanitize
    println("清洗后: ${clean}")
    println("")

    // 组装完整请求体
    let messages = ArrayList<String>()
    messages.add(systemMessage(content: "你是专业的仓颉语言助手"))
    messages.add(userMessage(content: "什么是仓颉语言？"))

    let body = buildRequestBody("moonshot-v1-8k", messages)
    println("请求体长度: ${body.size} 字节")
    println("消息数: ${messages.size}")
}
```

<!-- expected_output:
{"role": "user", "content": "你好"}
{"role": "system", "content": "你是仓颉语言助手"}
{"role": "assistant", "content": "你好，我是 AI 助手"}

清洗后: 请帮我写一个 'Hello World'
请求体长度: 111 字节
消息数: 2
-->

*   `StringBuilder` 用于高效字符串拼接，避免大量 `+` 操作产生中间对象。
*   `for (ch in s.runes())` 以 Unicode 码点（`Rune`）遍历字符串，正确处理中文字符。
*   `r'"'` 是双引号的 `Rune` 字面量。
*   管道运算符让内容预处理步骤清晰可读，每步职责单一。

## 工程化提示

*   **命名参数消除歧义**：`formatMessage(role: "user", content: "...")` 比 `formatMessage("user", "...")` 安全得多，参数顺序错误无法编译通过。
*   **默认值降低调用成本**：`createRequest()` 比 `createRequest("moonshot-v1-8k", 2048, 1)` 更易维护，修改默认值只需改一处。
*   **管道 vs 嵌套**：超过两层嵌套调用时，改用管道；管道链超过五步时，考虑拆分为具名中间变量。
*   **Lambda 策略化**：将"如何过滤"、"如何转换"等策略抽为 Lambda 参数，让函数逻辑与策略逻辑解耦。
*   **StringBuilder 优于 `+` 循环**：在循环中拼接字符串时，始终使用 `StringBuilder`，避免 O(n²) 的性能陷阱。

## 实践挑战

1. 为 `filterList` 添加一个 `transform` 参数，先过滤再转换，一步完成两个操作。
2. 用 `makeGreeter` 的模式，实现 `makeRoleFormatter(role: String): (String) -> String`，返回一个将内容格式化为指定角色消息的函数。
3. 扩展 `sanitize` 函数，同时处理换行符（将 `\n` 替换为空格）。
4. 思考：如果消息内容本身包含 `"` 或 `\n`，应该如何进行 JSON 安全转义？列举至少三种需要转义的字符。
