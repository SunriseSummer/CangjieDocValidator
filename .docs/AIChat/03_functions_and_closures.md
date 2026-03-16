# 03. 函数与 Lambda：消息格式化器

> 函数是逻辑的契约，Lambda 是策略的表达。好的函数设计让 AI 对话系统的每一个转换步骤都清晰可替换——今天我们为 AIChatPro 构建消息格式化工具链。

## 本章目标

*   掌握仓颉函数的定义、调用与隐式返回。
*   使用命名参数和默认值提升 API 可读性。
*   用 Lambda 表达式封装可传递的逻辑片段。
*   理解闭包如何捕获外部变量，构建高阶函数。
*   用管道运算符 `|>` 组合多步转换。
*   构建 AIChatPro 的消息格式化器。

---

## 1. 函数定义与调用

在仓颉中，函数是程序的基本构建单元。使用 `func` 关键字定义函数时，一个值得注意的语法特性是**隐式返回**——函数体中最后一个表达式的值会自动成为返回值，无需显式书写 `return`。这一设计借鉴了函数式编程的传统，让代码更加简洁。当然，如果你偏好明确的控制流，显式 `return` 同样有效。

下面的例子展示了三种常见的函数定义模式：简单的字符串拼接、算术运算，以及包含条件逻辑的描述生成。

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

请注意 `describe` 函数中 `if` 表达式的用法——在仓颉中，`if` 是**表达式**而非语句，它本身会产生一个值，因此可以直接赋给变量。这使得条件逻辑的表达既紧凑又直观。

并非所有函数都需要返回有意义的值。返回 `Unit` 的函数（即"过程"）通常用于执行副作用操作，如打印输出或修改外部状态。声明此类函数时，可以省略返回类型：

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

---

## 2. 命名参数与默认值

当函数参数较多或类型相同时，按位置传参很容易出错。试想 `buildMessage("user", "你好")` 和 `buildMessage("你好", "user")`——两者都能编译通过，但后者的含义完全错误。仓颉的**命名参数**机制从根本上消除了这类隐患：在参数名后加 `!` 标记，调用者必须显式写出参数名。

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

命名参数的定义语法是 `param!: Type`，调用时写作 `func(param: value)`。由于参数由名字标识，调用时的书写顺序不影响语义——上面的两次调用虽然参数顺序不同，但都能正确工作。

在实际开发中，许多 API 的参数具有合理的"常用值"。**默认参数值**允许我们为这些参数预设值，调用者只需覆盖与默认不同的部分：

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

总结命名参数与默认值的要点：

*   命名参数的定义用 `param!: Type`，调用时用 `func(param: value)`。
*   默认值紧跟参数类型后：`param!: Type = defaultValue`。
*   调用时未提供的命名参数自动使用默认值。

在 AIChatPro 中，这一机制让我们可以提供简洁的 `createRequest()` 快捷调用，同时保留对每个参数的精细控制——API 设计的灵活性与易用性兼得。

---

## 3. Lambda 表达式

如果说函数是"写好名字贴在墙上的菜谱"，那么 Lambda 就是"随手写在便条上的菜谱"——它没有名字，但同样完整，可以随时传给别人使用。在仓颉中，Lambda 的语法是 `{ 参数 => 函数体 }`，简洁而富有表达力。

Lambda 可以赋值给变量，像普通值一样在程序中传递：

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

Lambda 的真正威力在于它可以作为参数传递给其他函数，从而实现"策略注入"。下面的 `applyToAll` 函数接收一个 `transform` 参数——它不关心"怎么变换"，只负责"对每个元素应用变换"。具体的变换逻辑由调用者通过 Lambda 灵活指定：

<!-- check:run -->
```cangjie
func applyToAll(items: Array<String>, transform: (String) -> String): Array<String> {
    var result = Array<String>(items.size, repeat: "")
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

注意**尾随 Lambda** 语法——当函数的最后一个参数是函数类型时，Lambda 可以写在圆括号外面，如 `applyToAll(models) { s => ... }`。这一语法糖让代码读起来更自然。

---

## 4. 闭包与高阶函数

**闭包**（Closure）是函数式编程中的核心概念之一。它指的是一个函数"记住"了定义时所在作用域的变量，即使离开了那个作用域，依然能够访问这些变量。你可以把闭包想象成一个随身携带了"上下文行囊"的函数。

与之密切相关的是**高阶函数**——它接受函数作为参数，或者返回一个函数作为结果。当高阶函数返回闭包时，就形成了一种强大的"函数工厂"模式。

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

在上面的例子中，`makeGreeter("你好")` 返回的闭包"记住了" `prefix` 的值 `"你好"`。此后无论在哪里调用这个闭包，它都能正确引用 `prefix`，即使 `makeGreeter` 本身早已返回。

高阶函数在数据处理中同样大有用武之地。下面的 `filterList` 将"保留哪些元素"的判断逻辑抽象为一个 Lambda 参数 `keep`——函数只负责遍历与筛选的骨架，具体的过滤策略完全由调用方决定：

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

这种"骨架与策略分离"的设计模式在 AIChatPro 中随处可见：消息过滤、内容转换、请求构建——每一步都可以通过注入不同的 Lambda 来调整行为，而无需修改核心框架代码。

---

## 5. 管道运算符

在数据处理流程中，我们经常需要对一个值依次施加多步变换。传统的嵌套调用写法（如 `c(b(a(x)))`）迫使读者从最内层向外阅读，与人类的思维习惯相悖。

仓颉的管道运算符 `|>` 优雅地解决了这个问题——它将左侧的值作为第一个参数传入右侧的函数，让代码像水流一样从左向右自然流淌：

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

两种写法的结果完全相同，但管道版本清晰展现了数据的流转路径：原始字符串 → 去除空白 → 添加用户标签。每一个函数都像流水线上的一个工位，职责单一、组合自如。

当管道链更长时，可以将每一步写成独立一行，进一步提升可读性：

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

管道运算符是函数式编程理念在工程实践中的自然延伸。在 AIChatPro 的消息处理场景中，一条用户输入往往需要经历"清洗 → 校验 → 格式化 → 封装"等多个阶段，管道让这条处理链变得一目了然。

---

## 6. 消息格式化器

至此，我们已经掌握了函数定义、命名参数、Lambda、闭包和管道运算符。现在，是时候将这些知识综合运用，为 AIChatPro 构建一套完整的消息格式化工具链了。

### 6.1 消息格式化函数

首先构建消息格式化的核心层。`formatMessage` 利用命名参数确保角色与内容不会混淆，三个快捷函数则为常见角色提供了语义化的入口：

<!-- check:run -->
```cangjie
func formatMessage(role!: String, content!: String): String {
    "{\"role\": \"${role}\", \"content\": \"${content}\"}"
}

func userMessage(content!: String): String {
    formatMessage(role: "user", content: content)
}

func systemMessage(content!: String): String {
    formatMessage(role: "system", content: content)
}

func assistantMessage(content!: String): String {
    formatMessage(role: "assistant", content: content)
}

main() {
    println(userMessage(content: "你好"))
    println(systemMessage(content: "你是仓颉语言助手"))
    println(assistantMessage(content: "你好，我是 AI 助手"))
}
```

<!-- expected_output:
{"role": "user", "content": "你好"}
{"role": "system", "content": "你是仓颉语言助手"}
{"role": "assistant", "content": "你好，我是 AI 助手"}
-->

这种设计体现了**分层抽象**的原则：底层的 `formatMessage` 处理通用逻辑，上层的 `userMessage` 等函数封装业务语义。调用者无需关心 JSON 格式的细节，只需选择合适的快捷函数即可。

### 6.2 内容预处理管道

用户输入的原始内容往往包含多余的空白甚至潜在的注入风险。我们用两个小函数组成预处理管道——`trimContent` 去除首尾空白，`sanitize` 将双引号替换为单引号以防止 JSON 结构被破坏：

<!-- check:run -->
```cangjie
func trimContent(s: String): String { s.trimAscii() }

func sanitize(s: String): String {
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

main() {
    let rawInput = "  请帮我写一个 \"Hello World\"  "
    let clean = rawInput |> trimContent |> sanitize
    println("清洗后: ${clean}")
}
```

<!-- expected_output:
清洗后: 请帮我写一个 'Hello World'
-->

这里有几个值得关注的技术细节：`StringBuilder` 用于高效拼接字符串，避免循环中大量 `+` 操作产生的中间对象；`for (ch in s.runes())` 以 Unicode 码点（`Rune`）为单位遍历字符串，确保中文等多字节字符得到正确处理；`r'"'` 是双引号的 `Rune` 字面量。

### 6.3 完整集成：构建请求体

最后，我们将格式化函数与预处理管道整合到 `buildRequestBody` 中，生成可直接发送给 AI 服务的完整请求体：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

func formatMessage(role!: String, content!: String): String {
    "{\"role\": \"${role}\", \"content\": \"${content}\"}"
}

func userMessage(content!: String): String {
    formatMessage(role: "user", content: content)
}

func systemMessage(content!: String): String {
    formatMessage(role: "system", content: content)
}

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
    let messages = ArrayList<String>()
    messages.add(systemMessage(content: "你是专业的仓颉语言助手"))
    messages.add(userMessage(content: "什么是仓颉语言？"))

    let body = buildRequestBody("moonshot-v1-8k", messages)
    println("请求体长度: ${body.size} 字节")
    println("消息数: ${messages.size}")
}
```

<!-- expected_output:
请求体长度: 166 字节
消息数: 2
-->

至此，一条用户消息从原始输入到最终请求体的完整旅程已经清晰可见：内容清洗（管道）→ 消息格式化（命名参数）→ 请求体组装（`StringBuilder`）。每一层都职责分明、可独立测试、可灵活替换。

---

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
