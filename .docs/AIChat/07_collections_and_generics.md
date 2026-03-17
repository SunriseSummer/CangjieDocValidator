# 07. 集合与泛型：对话历史管理

> 数据结构决定了你的程序能做什么。正确选择集合——列表、映射、队列——往往比优化算法更重要。AIChatPro 的对话历史，就建立在仓颉标准集合之上。

在前面的章节中，我们已经学会了定义类、接口和枚举，也掌握了函数与闭包的基本用法。然而，当程序需要管理数量不确定的数据时——例如一段对话可能包含 3 条消息，也可能包含 300 条——我们就需要更灵活的数据容器。这正是**集合**登场的时刻。

本章将围绕 AIChatPro 的对话历史管理这一核心场景，逐步引入仓颉标准库中两大最常用的集合类型：动态列表 `ArrayList` 和哈希映射 `HashMap`。在此基础上，我们还将学习**泛型编程**，让工具函数摆脱对特定类型的依赖，真正做到"一次编写，处处复用"。

## 本章目标

*   掌握 `ArrayList<T>` 的增删改查与遍历。
*   使用 `HashMap<K, V>` 存储键值配置。
*   编写泛型函数，让代码适用于任意类型。
*   熟悉基于闭包的集合迭代模式（map / filter 风格）。
*   构建 AIChatPro 的 `ConversationHistory` 对话历史管理类。

---

## 1. ArrayList

在日常开发中，最常遇到的需求莫过于"维护一组可变长度的数据"。固定大小的数组 `Array<T>` 虽然性能极佳，但一旦创建便无法改变长度——对于对话历史这样时刻增长的数据流而言，显然力不从心。

`ArrayList<T>` 是仓颉标准库中的**动态数组**，它在底层维护一段连续内存，支持 O(1) 随机访问和均摊 O(1) 的尾部追加操作。当容量不足时，`ArrayList` 会自动扩容，开发者无需手动管理内存分配。可以把它想象成一个"会自动变长的数组"。

### 1.1 基本操作

我们先从最基础的增、删、查、遍历开始。下面的示例模拟了一个简单的聊天消息列表，展示了 `ArrayList` 最常用的几个方法：

- **`add`** 向尾部追加元素；
- **下标 `[i]`** 按索引随机访问；
- **`remove(at:)`** 按索引删除；
- **`clear`** 一次性清空全部元素。

<!-- check:run -->
```cangjie
import std.collection.ArrayList

main() {
    let list = ArrayList<String>()

    // 添加元素
    list.add("用户消息")
    list.add("助手回复")
    list.add("用户追问")
    println("大小: ${list.size}")

    // 随机访问
    println("第一条: ${list[0]}")
    println("最后一条: ${list[list.size - 1]}")

    // 遍历
    for (i in 0..list.size) {
        println("  [${i}] ${list[i]}")
    }

    // 删除（按索引）
    list.remove(at: 1)
    println("删除后大小: ${list.size}")

    // 清空
    list.clear()
    println("清空后大小: ${list.size}")
}
```

<!-- expected_output:
大小: 3
第一条: 用户消息
最后一条: 用户追问
  [0] 用户消息
  [1] 助手回复
  [2] 用户追问
删除后大小: 2
清空后大小: 0
-->

值得留意的是 `remove(at: 1)` 的行为：它删除的是**索引 1** 处的元素（即第二条消息"助手回复"），删除后，后续元素会自动前移填补空缺。这一操作的时间复杂度为 O(n)，对于频繁在中间删除的场景需要谨慎考虑性能影响。

### 1.2 从数组构建 ArrayList

在实际项目中，初始数据往往来自配置文件或硬编码的默认值，此时我们会先拥有一个固定数组，再将其内容填充到 `ArrayList` 中以便后续动态操作。构造函数 `ArrayList<T>(capacity)` 接收一个初始容量参数，它**不会**创建任何元素，但会预先分配足够的底层存储空间，从而减少后续追加时的扩容次数。

<!-- check:run -->
```cangjie
import std.collection.ArrayList

main() {
    // 用初始容量构造
    let history = ArrayList<String>(10)
    let initial = ["system: 你是 AI 助手", "user: 你好", "assistant: 你好！有什么可以帮你？"]
    for (msg in initial) {
        history.add(msg)
    }

    println("历史记录 (${history.size} 条):")
    for (i in 0..history.size) {
        println("  ${history[i]}")
    }
}
```

<!-- expected_output:
历史记录 (3 条):
  system: 你是 AI 助手
  user: 你好
  assistant: 你好！有什么可以帮你？
-->

这里传入容量 `10` 意味着底层数组预分配了 10 个位置，但 `size` 仍为 0——只有调用 `add` 后 `size` 才会增长。这一技巧在预知数据量级时能有效减少内存分配次数，是提升性能的小而实用的优化手段。

---

## 2. HashMap

如果说 `ArrayList` 解决的是"按顺序存放一组数据"的问题，那么 `HashMap<K, V>` 解决的则是"通过名字快速找到对应值"的问题。在 AIChatPro 中，我们需要管理多个 AI 模型的 API 配置——每个模型有唯一的名称标识符（如 `"kimi"`、`"glm"`），以及对应的 URL、模型 ID 等信息。这正是键值映射的典型应用场景。

`HashMap<K, V>` 基于哈希表实现，提供 O(1) 平均查找时间，适合按名称存储配置项。

### 2.1 基本操作

下面的示例展示了 `HashMap` 的核心操作。请特别注意 `get` 方法的返回类型——它返回 `Option<V>`（即 `?V`），因为查询的键可能并不存在。我们使用 `??` 运算符为缺失值提供默认兜底，这是仓颉中处理可选值的惯用模式。

<!-- check:run -->
```cangjie
import std.collection.HashMap

main() {
    let config = HashMap<String, String>()

    // 写入
    config.add("kimi_url", "https://api.moonshot.cn/v1")
    config.add("glm_url", "https://open.bigmodel.cn/api/paas/v4")
    config.add("default_model", "kimi")

    // 读取（返回 ?String，即 Option<String>）
    let url = config.get("kimi_url") ?? "未配置"
    println("Kimi URL: ${url}")

    let missing = config.get("unknown_key") ?? "不存在"
    println("未知键: ${missing}")

    // 存在性检查
    println("包含 glm_url: ${config.contains("glm_url")}")
    println("包含 openai_url: ${config.contains("openai_url")}")

    // 遍历
    println("---所有配置---")
    for ((k, v) in config) {
        println("  ${k} = ${v}")
    }
}
```

<!-- expected_output:
Kimi URL: https://api.moonshot.cn/v1
未知键: 不存在
包含 glm_url: true
包含 openai_url: false
---所有配置---
  kimi_url = https://api.moonshot.cn/v1
  glm_url = https://open.bigmodel.cn/api/paas/v4
  default_model = kimi
-->

遍历 `HashMap` 时使用了**元组解构** `(k, v)`，这使得在 `for-in` 循环中同时获取键和值变得简洁自然。需要注意的是，`HashMap` 不保证遍历顺序与插入顺序一致——如果需要有序遍历，应当额外维护一个键的有序列表。

### 2.2 HashMap 存储模型配置

当值不仅仅是简单的字符串，而是包含多个字段的结构化数据时，我们可以将自定义的 `struct` 作为 `HashMap` 的值类型。下面的示例定义了一个 `ModelConfig` 结构体，将每个 AI 模型的显示名称、API 地址和默认模型 ID 打包在一起，然后用模型名称作为键存入注册表。

查找时使用 `if-let` 模式匹配来安全地解包 `Option` 值——如果找到了对应配置则打印详情，否则提示"未注册"。这种防御性编程风格能从编译期就杜绝空指针类的运行时错误。

<!-- check:run -->
```cangjie
import std.collection.HashMap

struct ModelConfig {
    let displayName: String
    let apiUrl: String
    let defaultModelId: String
    public init(displayName!: String, apiUrl!: String, defaultModelId!: String) {
        this.displayName = displayName
        this.apiUrl = apiUrl
        this.defaultModelId = defaultModelId
    }
}

main() {
    let registry = HashMap<String, ModelConfig>()
    registry.add("kimi", ModelConfig(
        displayName: "Kimi (月之暗面)",
        apiUrl: "https://api.moonshot.cn/v1",
        defaultModelId: "moonshot-v1-8k"
    ))
    registry.add("glm", ModelConfig(
        displayName: "GLM-4 (智谱 AI)",
        apiUrl: "https://open.bigmodel.cn/api/paas/v4",
        defaultModelId: "glm-4"
    ))

    let names = ["kimi", "glm", "gpt"]
    for (name in names) {
        if (let Some(cfg) <- registry.get(name)) {
            println("✓ ${name}: ${cfg.displayName} → ${cfg.defaultModelId}")
        } else {
            println("✗ ${name}: 未注册")
        }
    }
}
```

<!-- expected_output:
✓ kimi: Kimi (月之暗面) → moonshot-v1-8k
✓ glm: GLM-4 (智谱 AI) → glm-4
✗ gpt: 未注册
-->

运行结果清晰地展示了注册表的查找逻辑：已注册的 `"kimi"` 和 `"glm"` 成功匹配并输出配置详情，而未注册的 `"gpt"` 则优雅地走入 `else` 分支。这种"注册表"模式在插件架构和多模型切换中极为常见。

---

## 3. 泛型函数

回顾前面的代码，你或许已经注意到一个问题：我们为 `ArrayList<String>` 编写的工具逻辑（如查找第一个元素、过滤满足条件的元素）与元素类型其实无关——同样的逻辑完全可以应用于 `ArrayList<Int64>` 或任何其他类型。如果为每种类型都写一遍几乎相同的函数，那将是令人窒息的重复劳动。

**泛型**（generics）正是为解决这一问题而生的语言特性。通过在函数签名中引入**类型参数**（如 `<T>`），我们可以编写"对类型未知、但逻辑通用"的函数，由编译器在调用时自动推断具体类型，同时保持完整的类型安全——既不牺牲灵活性，也不放弃编译期检查。

### 3.1 基础泛型函数

下面我们编写三个通用的集合工具函数：`firstOrDefault` 获取首元素（列表为空时返回默认值）、`lastOrDefault` 获取尾元素、`contains` 判断是否存在满足条件的元素。它们的类型参数 `<T>` 使得同一份代码可以同时服务于字符串列表和整数列表。

<!-- check:run -->
```cangjie
import std.collection.ArrayList

func firstOrDefault<T>(list: ArrayList<T>, default!: T): T {
    if (list.size > 0) { list[0] } else { default }
}

func lastOrDefault<T>(list: ArrayList<T>, default!: T): T {
    if (list.size > 0) { list[list.size - 1] } else { default }
}

func contains<T>(list: ArrayList<T>, predicate: (T) -> Bool): Bool {
    for (i in 0..list.size) {
        if (predicate(list[i])) { return true }
    }
    return false
}

main() {
    let strings = ArrayList<String>()
    strings.add("hello")
    strings.add("world")

    println(firstOrDefault(strings, default: "(空)"))
    println(lastOrDefault(strings, default: "(空)"))

    let empty = ArrayList<Int64>()
    println(firstOrDefault(empty, default: -1))

    let numbers = ArrayList<Int64>()
    numbers.add(1)
    numbers.add(5)
    numbers.add(3)
    println("包含大于 4 的数: ${contains(numbers) { n => n > 4 }}")
    println("包含大于 10 的数: ${contains(numbers) { n => n > 10 }}")
}
```

<!-- expected_output:
hello
world
-1
包含大于 4 的数: true
包含大于 10 的数: false
-->

注意 `contains` 函数的第二个参数是一个**闭包** `(T) -> Bool`——我们在第 6 章学过的闭包语法在这里大放异彩。调用时使用尾随 Lambda 的写法 `contains(numbers) { n => n > 4 }`，代码读起来几乎像自然语言一样流畅。泛型与闭包的结合，正是函数式风格集合操作的基石。

### 3.2 泛型转换函数

有了基础泛型函数的经验，我们进一步构建两个更强大的集合操作原语：**映射**（map）和**过滤**（filter）。这两个操作在函数式编程中无处不在，几乎所有现代语言的标准库都内置了它们的某种形式。

`mapList<A, B>` 接受两个类型参数——输入类型 `A` 和输出类型 `B`，对列表中的每个元素应用 `transform` 变换函数，生成一个全新的列表。`filterList<T>` 则保留类型不变，只筛选出满足 `predicate` 条件的元素。两者都不修改原列表，而是返回新的列表——这种**不可变数据**的风格使代码更易推理和调试。

<!-- check:run -->
```cangjie
import std.collection.ArrayList

func mapList<A, B>(list: ArrayList<A>, transform: (A) -> B): ArrayList<B> {
    let result = ArrayList<B>()
    for (i in 0..list.size) {
        result.add(transform(list[i]))
    }
    return result
}

func filterList<T>(list: ArrayList<T>, predicate: (T) -> Bool): ArrayList<T> {
    let result = ArrayList<T>()
    for (i in 0..list.size) {
        if (predicate(list[i])) {
            result.add(list[i])
        }
    }
    return result
}

main() {
    let messages = ArrayList<String>()
    messages.add("user: 你好")
    messages.add("assistant: 你好！")
    messages.add("user: 讲个故事")
    messages.add("assistant: 从前有座山…")

    // 只保留用户消息
    let userMsgs = filterList(messages) { msg => msg.startsWith("user:") }
    println("用户消息:")
    for (i in 0..userMsgs.size) {
        println("  ${userMsgs[i]}")
    }

    // 提取长度
    let lengths = mapList(messages) { msg => msg.size }
    println("消息长度:")
    for (i in 0..lengths.size) {
        println("  ${lengths[i]}")
    }
}
```

<!-- expected_output:
用户消息:
  user: 你好
  user: 讲个故事
消息长度:
  12
  20
  18
  29
-->

这段代码展示了泛型的真正威力：`filterList` 作用于 `ArrayList<String>` 返回 `ArrayList<String>`，而 `mapList` 则将 `ArrayList<String>` 转换为 `ArrayList<Int64>`——输入与输出可以是完全不同的类型。编译器通过闭包的返回值自动推断出类型参数 `B` 为 `Int64`，开发者无需显式标注。

---

## 4. 集合迭代模式

掌握了 `ArrayList` 的基本操作和泛型函数之后，我们来看看在实际业务逻辑中如何高效地遍历和处理集合数据。集合迭代的两大经典模式是**累积计算**（将整个集合归约为单一结果）和**分组统计**（将元素按某种规则归类）。这两种模式在对话历史分析中随处可见。

### 4.1 累积计算

累积计算的核心思想是：维护一个"累加器"变量，逐一扫描集合中的每个元素，将信息汇聚到累加器中。下面我们实现两个实用函数——`sumLengths` 计算所有消息的总字符数（这在估算 API token 用量时非常有用），`countRole` 统计特定角色的消息数量。

<!-- check:run -->
```cangjie
import std.collection.ArrayList

func sumLengths(messages: ArrayList<String>): Int64 {
    var total: Int64 = 0
    for (i in 0..messages.size) {
        total = total + messages[i].size
    }
    return total
}

func countRole(messages: ArrayList<String>, role: String): Int64 {
    var count: Int64 = 0
    for (i in 0..messages.size) {
        if (messages[i].startsWith(role + ":")) {
            count++
        }
    }
    return count
}

main() {
    let history = ArrayList<String>()
    history.add("user: 你好，帮我解释一下量子计算")
    history.add("assistant: 量子计算利用量子力学原理进行计算，使用量子比特。")
    history.add("user: 和传统计算机有什么区别？")
    history.add("assistant: 传统计算机用 0 和 1，量子计算机可以同时处于叠加态。")

    println("总字符数: ${sumLengths(history)}")
    println("用户消息数: ${countRole(history, "user")}")
    println("助手消息数: ${countRole(history, "assistant")}")
}
```

<!-- expected_output:
总字符数: 255
用户消息数: 2
助手消息数: 2
-->

`sumLengths` 函数的实际应用价值不容小觑：大多数 AI API 按 token 计费，而字符数是 token 数的粗略近似。在发送请求前预估总字符数，可以帮助我们决定是否需要截断历史以避免超出上下文窗口限制。

### 4.2 分组与统计

当需要将消息按角色分类统计时，单纯的累加器就不够用了——我们需要 `HashMap` 与 `ArrayList` 的联合运用。下面的 `groupByRole` 函数解析每条消息中冒号前的角色名称，以此为键将消息归入对应的列表。这是一个典型的"分组归类"模式，在日志分析、数据统计等场景中广泛使用。

由于 `HashMap` 的遍历顺序不固定，这里使用 `check:build_only` 仅验证编译通过。

<!-- check:build_only -->
```cangjie
import std.collection.{ArrayList, HashMap}

func groupByRole(messages: ArrayList<String>): HashMap<String, ArrayList<String>> {
    let groups = HashMap<String, ArrayList<String>>()
    for (i in 0..messages.size) {
        let msg = messages[i]
        // 找冒号位置
        var colonIdx: Int64 = -1
        var charIdx: Int64 = 0
        for (ch in msg.runes()) {
            if (ch == r':') {
                colonIdx = charIdx
                break
            }
            charIdx++
        }
        if (colonIdx < 0) { continue }
        // 提取 role（冒号前）
        var role = ""
        charIdx = 0
        for (ch in msg.runes()) {
            if (charIdx >= colonIdx) { break }
            role = role + ch.toString()
            charIdx++
        }
        if (!groups.contains(role)) {
            groups.add(role, ArrayList<String>())
        }
        if (let Some(list) <- groups.get(role)) {
            list.add(msg)
        }
    }
    return groups
}

main() {
    let history = ArrayList<String>()
    history.add("user: 你好")
    history.add("assistant: 你好！")
    history.add("user: 今天天气")
    history.add("system: 系统维护中")
    history.add("assistant: 我无法查询天气")

    let grouped = groupByRole(history)
    for ((role, msgs) in grouped) {
        println("${role} (${msgs.size} 条):")
        for (i in 0..msgs.size) {
            println("  - ${msgs[i]}")
        }
    }
}
```

这段代码中有一处值得细品的设计：在向分组中添加消息前，先检查该角色的键是否已存在——如果不存在，则为该角色创建一个新的空列表。这种"按需初始化"的模式是使用 `HashMap<K, ArrayList<V>>` 这类嵌套集合时的标准写法。

---

## 5. 对话历史管理

经过前面四节的循序渐进，我们已经分别掌握了 `ArrayList` 的动态存储、`HashMap` 的键值查找、泛型函数的类型抽象，以及集合迭代的常用模式。现在，是时候将这些知识**融会贯通**，构建 AIChatPro 的核心组件——`ConversationHistory` 对话历史管理类了。

### 5.1 ConversationHistory 类定义

`ConversationHistory` 的设计遵循一个关键原则：**有限窗口**。大语言模型的 API 通常有上下文长度限制（如 8K 或 32K tokens），不可能无限制地发送全部历史。因此，我们的对话历史类需要一个 `maxSize` 参数，当消息数量超出上限时，自动移除最早的消息对（一条用户消息 + 一条助手回复），为新消息腾出空间。

类的核心方法包括：
- **`add`**：添加一条带角色标签的 JSON 格式消息，必要时触发滚动淘汰；
- **`toJsonArray`**：将全部消息序列化为 JSON 数组字符串，供 API 请求体使用；
- **`getLatest`**：获取最近 N 条消息，用于上下文预览或摘要生成；
- **`clear`** 和 **`size`**：基础的清空与计数操作。

下面先展示类定义和基本的添加、序列化功能：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

class ConversationHistory {
    private let messages: ArrayList<String> = ArrayList<String>()
    private let maxSize: Int64

    public init(maxSize!: Int64 = 20) {
        this.maxSize = maxSize
    }

    public func add(role: String, content: String): Unit {
        if (messages.size >= maxSize) {
            messages.remove(at: 0)
            if (messages.size > 0) {
                messages.remove(at: 0)
            }
        }
        messages.add("{\"role\":\"${role}\",\"content\":\"${content}\"}")
    }

    public func toJsonArray(): String {
        if (messages.size == 0) { return "[]" }
        var result = "["
        for (i in 0..messages.size) {
            if (i > 0) { result = result + "," }
            result = result + messages[i]
        }
        return result + "]"
    }

    public func clear(): Unit { messages.clear() }

    public prop size: Int64 {
        get() { messages.size }
    }

    public func getLatest(n: Int64): ArrayList<String> {
        let result = ArrayList<String>()
        let start = if (messages.size > n) { messages.size - n } else { 0 }
        for (i in start..messages.size) {
            result.add(messages[i])
        }
        return result
    }
}

main() {
    let history = ConversationHistory(maxSize: 6)

    history.add("system", "你是一名专业的 AI 助手")
    history.add("user", "你好！")
    history.add("assistant", "你好！有什么可以帮到你？")
    history.add("user", "仓颉是什么语言？")
    history.add("assistant", "仓颉是华为推出的编程语言，适用于多种场景。")

    println("历史大小: ${history.size}")
    println("JSON 数组:")
    println(history.toJsonArray())
}
```

<!-- expected_output:
历史大小: 5
JSON 数组:
[{"role":"system","content":"你是一名专业的 AI 助手"},{"role":"user","content":"你好！"},{"role":"assistant","content":"你好！有什么可以帮到你？"},{"role":"user","content":"仓颉是什么语言？"},{"role":"assistant","content":"仓颉是华为推出的编程语言，适用于多种场景。"}]
-->

运行结果中，`toJsonArray()` 输出了一个标准的 JSON 数组——这正是大多数 AI API 所期望的 `messages` 字段格式。每条消息都包含 `role` 和 `content` 两个字段，完整还原了对话的上下文结构。

### 5.2 上下文检索与生命周期管理

仅仅能添加和序列化消息还不够。在实际对话流程中，我们常常需要**检索最近几条消息**作为摘要提示，或者在用户发起新会话时**清空历史**重新开始。`getLatest(n)` 方法通过计算起始索引 `start`，只提取尾部 N 条消息到新列表中返回，原始历史不受影响。

下面验证这两个功能的协作效果：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

class ConversationHistory {
    private let messages: ArrayList<String> = ArrayList<String>()
    private let maxSize: Int64

    public init(maxSize!: Int64 = 20) {
        this.maxSize = maxSize
    }

    public func add(role: String, content: String): Unit {
        if (messages.size >= maxSize) {
            messages.remove(at: 0)
            if (messages.size > 0) {
                messages.remove(at: 0)
            }
        }
        messages.add("{\"role\":\"${role}\",\"content\":\"${content}\"}")
    }

    public func clear(): Unit { messages.clear() }

    public prop size: Int64 {
        get() { messages.size }
    }

    public func getLatest(n: Int64): ArrayList<String> {
        let result = ArrayList<String>()
        let start = if (messages.size > n) { messages.size - n } else { 0 }
        for (i in start..messages.size) {
            result.add(messages[i])
        }
        return result
    }
}

main() {
    let history = ConversationHistory(maxSize: 6)

    history.add("system", "你是一名专业的 AI 助手")
    history.add("user", "你好！")
    history.add("assistant", "你好！有什么可以帮到你？")
    history.add("user", "仓颉是什么语言？")
    history.add("assistant", "仓颉是华为推出的编程语言，适用于多种场景。")

    println("最近 2 条:")
    let latest = history.getLatest(2)
    for (i in 0..latest.size) {
        println("  ${latest[i]}")
    }
    history.clear()
    println("清空后大小: ${history.size}")
}
```

<!-- expected_output:
最近 2 条:
  {"role":"user","content":"仓颉是什么语言？"}
  {"role":"assistant","content":"仓颉是华为推出的编程语言，适用于多种场景。"}
清空后大小: 0
-->

`getLatest(2)` 精确返回了最后两条消息——恰好是最近一轮对话的用户提问和助手回答。在实际应用中，这一功能可用于生成对话摘要、构建上下文提示词，或在界面上展示"最近对话预览"。调用 `clear()` 后，历史大小归零，对象可以安全地开始承载新的会话。

### 5.3 maxSize 滚动窗口测试

`ConversationHistory` 最精妙的机制在于**滚动窗口**：当消息数达到 `maxSize` 上限时，`add` 方法会自动移除最早的两条消息（模拟移除一轮对话），然后再追加新消息。这确保了内存占用始终可控，同时保留了最近的对话上下文。

下面用一个容量仅为 4 的微型历史来直观验证这一行为——前两轮填满窗口，第三轮触发滚动淘汰：

<!-- check:run -->
```cangjie
import std.collection.ArrayList

class ConversationHistory {
    private let messages: ArrayList<String> = ArrayList<String>()
    private let maxSize: Int64

    public init(maxSize!: Int64 = 20) {
        this.maxSize = maxSize
    }

    public func add(role: String, content: String): Unit {
        if (messages.size >= maxSize) {
            messages.remove(at: 0)
            if (messages.size > 0) {
                messages.remove(at: 0)
            }
        }
        messages.add("{\"role\":\"${role}\",\"content\":\"${content}\"}")
    }

    public func clear(): Unit { messages.clear() }
    public prop size: Int64 { get() { messages.size } }
    public func get(i: Int64): String { messages[i] }
}

main() {
    // 最多保留 4 条（2 轮对话）
    let history = ConversationHistory(maxSize: 4)

    history.add("user", "第一轮问题")
    history.add("assistant", "第一轮回答")
    println("第 1 轮后: ${history.size} 条")

    history.add("user", "第二轮问题")
    history.add("assistant", "第二轮回答")
    println("第 2 轮后: ${history.size} 条")

    // 第 3 轮触发滚动
    history.add("user", "第三轮问题")
    history.add("assistant", "第三轮回答")
    println("第 3 轮后: ${history.size} 条")
    println("最早的消息: ${history.get(0)}")
}
```

<!-- expected_output:
第 1 轮后: 2 条
第 2 轮后: 4 条
第 3 轮后: 4 条
最早的消息: {"role":"user","content":"第二轮问题"}
-->

第三轮添加后，历史条数仍然维持在 4 条而非增长到 6 条——第一轮的两条消息已被自动淘汰。此时窗口中最早的消息变成了第二轮的用户问题，完美实现了"滑动窗口"效果。这一机制保证了无论对话持续多久，发送给 API 的上下文数据量始终在可控范围内。

---

## 工程化提示

*   **`ArrayList` 还是数组？** 对话历史长度动态变化，应使用 `ArrayList`。若长度固定（如固定缓冲区），优先使用 `Array<T>`，避免动态分配开销。
*   **`HashMap` 的键类型**：模型配置用 `String` 键（如 `"kimi"`）既直观又便于序列化。避免用可变对象作为键，否则哈希值可能失效。
*   **maxSize 策略**：API 通常有 token 上下文限制（如 8K/32K tokens）。`ConversationHistory` 的 `maxSize` 是消息条数限制；实际项目中还需按 token 数截断，但消息数是简单实用的近似。
*   **泛型函数的位置**：`firstOrDefault`、`filterList` 这类工具函数适合放在独立的 `utils` 包里，方便复用。

---

## 实践挑战

1.  为 `ConversationHistory` 添加 `getRoleCount(role: String): Int64` 方法，统计某角色的消息数。
2.  编写一个泛型 `Stack<T>` 类，基于 `ArrayList<T>` 实现 `push`、`pop`（返回 `?T`）和 `peek` 方法。
3.  扩展 `ConversationHistory`，添加 `exportToString(): String` 方法，将全部历史格式化为人类可读的文本（如 `"[user] 你好\n[assistant] 你好！\n"`）。
