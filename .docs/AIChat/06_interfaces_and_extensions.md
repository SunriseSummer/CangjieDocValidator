# 06. 接口与扩展：模型抽象层

> 接口是约定，扩展是增强。好的抽象让你可以在不改动上层代码的情况下，随时替换底层实现——这正是 AIChatPro 支持多个 AI 模型的秘诀。

## 本章目标

*   掌握 `interface` 的定义与 `<:` 实现语法。
*   理解多接口实现与接口继承。
*   使用接口默认实现减少重复代码。
*   通过 `extend` 为已有类型增添新方法。
*   定义 AIChatPro 的 `BaseChatModel` 抽象接口。

---

## 1. 接口基础

在 AIChatPro 中，我们需要多个 AI 模型（Kimi、GLM、Minimax）都能响应同一个 `chat()` 调用。接口正是实现这一目标的利器——定义一次契约，为每个模型各自实现，上层调用代码无需任何改动。

接口（`interface`）定义了一组方法签名，任何实现该接口的类型都必须提供这些方法。接口本身不持有数据。

<!-- check:run -->
```cangjie
interface Greeter {
    func greet(name: String): String
}

class FormalGreeter <: Greeter {
    public func greet(name: String): String {
        "您好，${name} 先生/女士。"
    }
}

class CasualGreeter <: Greeter {
    public func greet(name: String): String {
        "嘿，${name}！"
    }
}

func printGreeting(g: Greeter, name: String): Unit {
    println(g.greet(name))
}

main() {
    let formal: Greeter = FormalGreeter()
    let casual: Greeter = CasualGreeter()

    printGreeting(formal, "张伟")
    printGreeting(casual, "小明")
}
```

<!-- expected_output:
您好，张伟 先生/女士。
嘿，小明！
-->

接口变量的关键特性：你可以把 `FormalGreeter` 或 `CasualGreeter` 的实例赋给 `Greeter` 类型的变量，实现多态。注意 `printGreeting` 函数完全不关心它接收的是哪种 `Greeter`——它只知道对方一定能 `greet()`。在 AIChatPro 中，`ReplRunner` 同样不知道自己在和 Kimi 还是 GLM 对话，它只调用 `model.chat()`，具体行为由底层实现决定。这种"面向契约编程"的方式，是整个多模型架构的基石。

---

## 2. 多接口实现

一个类往往需要扮演多种角色。例如，模型配置信息既需要对用户友好地展示（`Describable`），又需要以结构化格式写入日志（`Serializable`）。多接口实现让一个类自然地承担这些不同职责。

仓颉支持一个类同时实现多个接口，用 `&` 分隔：

<!-- check:run -->
```cangjie
interface Describable {
    func describe(): String
}

interface Serializable {
    func serialize(): String
}

class ModelInfo <: Describable & Serializable {
    let name: String
    let version: String

    public init(name: String, version: String) {
        this.name = name
        this.version = version
    }

    public func describe(): String {
        "模型: ${name} (版本 ${version})"
    }

    public func serialize(): String {
        "{\"name\":\"${name}\",\"version\":\"${version}\"}"
    }
}

func printDescription(d: Describable): Unit {
    println(d.describe())
}

func saveToLog(s: Serializable): Unit {
    println("写入日志: ${s.serialize()}")
}

main() {
    let info = ModelInfo("Kimi", "v1.0")
    printDescription(info)
    saveToLog(info)
}
```

<!-- expected_output:
模型: Kimi (版本 v1.0)
写入日志: {"name":"Kimi","version":"v1.0"}
-->

同一个对象 `info` 既可以作为 `Describable` 传入 `printDescription`，也可以作为 `Serializable` 传入 `saveToLog`。这里的 `&` 不是继承，而是**能力组合**——类承诺独立地履行每一份契约。与单继承不同，能力组合没有层级关系，`ModelInfo` 不是 `Describable` 的"子类"，它只是恰好同时具备描述和序列化两种能力。

---

## 3. 接口默认实现

并非每个接口方法都需要从头实现。默认实现允许你在接口中提供合理的通用行为，实现者可以按需覆盖——既减少了样板代码，又不牺牲灵活性。

仓颉的接口可以提供默认实现，实现类型可以选择覆盖或直接继承：

<!-- check:run -->
```cangjie
interface Logger {
    func log(msg: String): Unit

    // 默认实现：带时间戳前缀
    func logInfo(msg: String): Unit {
        log("[INFO] ${msg}")
    }

    func logError(msg: String): Unit {
        log("[ERROR] ${msg}")
    }
}

class ConsoleLogger <: Logger {
    public func log(msg: String): Unit {
        println(msg)
    }
    // logInfo 和 logError 直接继承默认实现
}

class PrefixLogger <: Logger {
    let prefix: String
    public init(prefix: String) { this.prefix = prefix }

    public func log(msg: String): Unit {
        println("[${prefix}] ${msg}")
    }

    // 覆盖 logInfo，自定义格式
    public func logInfo(msg: String): Unit {
        log("INFO: ${msg}")
    }
}

main() {
    let console: Logger = ConsoleLogger()
    console.logInfo("服务启动")
    console.logError("连接超时")

    println("---")

    let prefixed: Logger = PrefixLogger("AIChatPro")
    prefixed.logInfo("模型已加载")
    prefixed.logError("API Key 无效")
}
```

<!-- expected_output:
[INFO] 服务启动
[ERROR] 连接超时
---
[AIChatPro] INFO: 模型已加载
[AIChatPro] [ERROR] API Key 无效
-->

`ConsoleLogger` 不需要重新定义 `logInfo`/`logError`，`PrefixLogger` 则选择性覆盖了 `logInfo`。这里体现了经典的"模板方法"模式：`log()` 是唯一的定制点，而 `logInfo`/`logError` 在其基础上构建更高层的行为。实现者只需关注最底层的输出逻辑，上层格式由接口统一管理。AIChatPro 的模型实现中也采用了类似模式——基础方法由各模型自行定义，组合逻辑则由接口默认实现提供。

---

## 4. extend 扩展

`extend` 关键字允许你在不修改原始类型的情况下，为其添加新方法——甚至可以让它实现新接口。

### 4.1 为内置类型添加方法

`extend` 是仓颉对"表达式问题"的回答——你可以为已有类型添加新行为，而无需修改其源代码。这对内置类型尤其有用：`String` 是语言核心类型，你无法编辑它的定义，但 `extend` 让你像操作自己的类型一样为它增添方法。

<!-- check:run -->
```cangjie
extend String {
    func truncate(maxLen: Int64, suffix!: String = "..."): String {
        if (this.size <= maxLen) {
            return this
        }
        // 取前 maxLen 个字节后拼接省略号
        var result = ""
        var count: Int64 = 0
        for (ch in this.runes()) {
            if (count >= maxLen) { break }
            result = result + ch.toString()
            count++
        }
        return result + suffix
    }

    func isBlank(): Bool {
        this.trimAscii().isEmpty()
    }
}

main() {
    let longMsg = "这是一条非常非常长的 AI 回复消息，需要截断显示"
    println(longMsg.truncate(10))
    println(longMsg.truncate(15, suffix: "【更多】"))

    println("".isBlank())
    println("   ".isBlank())
    println("hello".isBlank())
}
```

<!-- expected_output:
这是一条非常非常长的...
这是一条非常非常长的 AI 回【更多】
true
true
false
-->

这里的 `truncate` 和 `isBlank` 都是为 AI 聊天场景量身定制的增强。`truncate` 用于截断过长的模型回复以便预览显示；`isBlank` 则帮助判断用户是否提交了空白输入。它们读起来就像 `String` 的原生方法，调用方无需知道这是扩展还是内置行为。

### 4.2 用 extend 实现接口

`extend` 也可以让已有类型实现新接口，这在你无法修改原始类型时非常有用：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

interface Printable {
    func prettyPrint(): Unit
}

extend ArrayList<String> <: Printable {
    public func prettyPrint(): Unit {
        println("列表 (共 ${size} 项):")
        for (i in 0..size) {
            println("  ${i + 1}. ${this[i]}")
        }
    }
}

main() {
    let models = ArrayList<String>()
    models.add("Kimi (月之暗面)")
    models.add("GLM-4 (智谱 AI)")
    models.add("MiniMax")

    models.prettyPrint()
}
```

<!-- expected_output:
列表 (共 3 项):
  1. Kimi (月之暗面)
  2. GLM-4 (智谱 AI)
  3. MiniMax
-->

这展示了 `extend` 的另一个强大用法：为标准库类型追加接口实现。`ArrayList<String>` 现在拥有了 `prettyPrint()` 方法，而我们完全没有修改标准库的任何代码。在 AIChatPro 中，类似的扩展让集合类型直接具备格式化输出能力，避免了到处编写独立的打印函数。

### 4.3 扩展 ArrayList 添加工具方法

为 `ArrayList<String>` 添加消息历史构建辅助方法：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

extend ArrayList<String> {
    func joinWith(sep: String): String {
        if (size == 0) { return "" }
        var result = this[0]
        for (i in 1..size) {
            result = result + sep + this[i]
        }
        return result
    }

    func lastOrEmpty(): String {
        if (size == 0) { return "" }
        this[size - 1]
    }
}

main() {
    let tags = ArrayList<String>()
    tags.add("AI")
    tags.add("聊天")
    tags.add("仓颉")

    println(tags.joinWith(", "))
    println(tags.joinWith(" | "))
    println("最后一项: ${tags.lastOrEmpty()}")

    let empty = ArrayList<String>()
    println("空列表: '${empty.joinWith(",")}'")
    println("空列表末尾: '${empty.lastOrEmpty()}'")
}
```

<!-- expected_output:
AI, 聊天, 仓颉
AI | 聊天 | 仓颉
最后一项: 仓颉
空列表: ''
空列表末尾: ''
-->

这些扩展方法都是便捷的工具函数，让集合操作更加流畅。接下来，让我们定义贯穿 AIChatPro 整个模型层的核心抽象——`BaseChatModel` 接口。

---

## 5. BaseChatModel 接口

现在将这些概念应用到 AIChatPro 的核心抽象：所有 AI 模型必须实现的 `BaseChatModel` 接口。

```
接口定义 BaseChatModel
├── chat(userMessage, onToken) → 发起对话，逐 token 回调
├── getName()                  → 返回显示名称（如 "kimi"）
└── getModelId()               → 返回 API 模型 ID（如 "moonshot-v1-8k"）
```

### 5.1 定义接口

<!-- check:ast -->
```cangjie
interface BaseChatModel {
    func chat(userMessage: String, onToken: (String) -> Unit): Unit
    func getName(): String
    func getModelId(): String
}
```

`onToken` 是一个回调函数，每当 AI 返回一个新 token（字符片段），就会被调用一次——这正是流式输出的核心机制。之所以采用回调而非一次性返回完整字符串，是因为大语言模型的响应是异步逐 token 生成的；回调设计让每个 token 一到达就能立即推入显示管线，用户无需等待完整回复即可看到输出。

### 5.2 实现 MockModel（测试用）

<!-- check:run -->
```cangjie
interface BaseChatModel {
    func chat(userMessage: String, onToken: (String) -> Unit): Unit
    func getName(): String
    func getModelId(): String
}

class MockModel <: BaseChatModel {
    let name: String

    public init(name: String) {
        this.name = name
    }

    public func getName(): String { name }

    public func getModelId(): String { "mock-v1" }

    public func chat(userMessage: String, onToken: (String) -> Unit): Unit {
        let response = "这是来自 ${name} 的回复: ${userMessage}"
        for (ch in response.runes()) {
            onToken(ch.toString())
        }
    }
}

main() {
    let model: BaseChatModel = MockModel("测试模型")
    println("模型名称: ${model.getName()}")
    println("模型 ID:  ${model.getModelId()}")
    println("---")
    print("流式回复: ")
    model.chat("你好！") { token =>
        print(token)
    }
    println("")
}
```

<!-- expected_output:
模型名称: 测试模型
模型 ID:  mock-v1
---
流式回复: 这是来自 测试模型 的回复: 你好！
-->

`MockModel` 在测试中扮演着关键角色：它让你无需任何真实 API 调用，就能完整测试 `ReplRunner`、命令解析和显示逻辑。这正是基于接口设计的核心收益——依赖抽象而非具体实现，测试时用轻量替身即可覆盖全部上层逻辑。

### 5.3 多模型切换

接口让多模型切换变得自然：

<!-- check:run -->
```cangjie
interface BaseChatModel {
    func chat(userMessage: String, onToken: (String) -> Unit): Unit
    func getName(): String
    func getModelId(): String
}

class KimiMock <: BaseChatModel {
    public func getName(): String { "kimi" }
    public func getModelId(): String { "moonshot-v1-8k" }
    public func chat(userMessage: String, onToken: (String) -> Unit): Unit {
        let resp = "[Kimi] 收到消息: ${userMessage}"
        for (ch in resp.runes()) { onToken(ch.toString()) }
    }
}

class GlmMock <: BaseChatModel {
    public func getName(): String { "glm" }
    public func getModelId(): String { "glm-4" }
    public func chat(userMessage: String, onToken: (String) -> Unit): Unit {
        let resp = "[GLM] 收到消息: ${userMessage}"
        for (ch in resp.runes()) { onToken(ch.toString()) }
    }
}

func runChat(model: BaseChatModel, msg: String): Unit {
    print("[${model.getName()}] ")
    model.chat(msg) { token => print(token) }
    println("")
}

main() {
    let models: Array<BaseChatModel> = [KimiMock(), GlmMock()]
    for (m in models) {
        runChat(m, "你是谁？")
    }
}
```

<!-- expected_output:
[kimi] [Kimi] 收到消息: 你是谁？
[glm] [GLM] 收到消息: 你是谁？
-->

有了 `BaseChatModel` 接口，新增一个 AI 供应商只需实现三个方法。AIChatPro 的其余部分——REPL 交互、命令系统、流式输出引擎——全部保持不变。这就是接口抽象的终极价值：**变化被隔离在实现层，稳定性留给架构层。**

---

## 工程化提示

*   **接口 vs 抽象类**：仓颉中没有抽象类，接口承担了全部抽象责任。接口可以有默认实现，但不持有状态（字段）。
*   **extend 的作用域**：`extend` 中新增的方法只在当前包可见（除非接口是 `public` 的）。为第三方类型写扩展时，注意不要与已有方法冲突。
*   **依赖接口而非具体类型**：`BaseChatModel` 让 `ReplRunner` 不需要知道自己在使用 Kimi 还是 GLM，只需调用 `chat()` 即可。这正是 AIChatPro 可以在运行时 `/switch` 切换模型的基础。
*   **onToken 回调**：在真实实现中，`onToken` 会把字符推送到 `CharQueue`（第 9 章），再由 `StreamEngine` 异步消费显示。

---

## 实践挑战

1.  定义一个 `Stateful` 接口，包含 `getState(): String` 和 `reset(): Unit` 方法，为 `MockModel` 实现它，使 `reset()` 能清空已生成的回复。
2.  为 `String` 类型写一个 `extend`，添加 `wordCount(): Int64` 方法（按空格分词统计）。
3.  思考：如果 `BaseChatModel` 的 `chat` 方法需要传入完整的对话历史（`ArrayList<ChatMessage>`），接口签名应如何修改？（提示：见第 7 章的 `ConversationHistory`）
