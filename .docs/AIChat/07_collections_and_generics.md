# 07. 集合与泛型：对话历史管理

> 数据结构决定了你的程序能做什么。正确选择集合——列表、映射、队列——往往比优化算法更重要。AIChatPro 的对话历史，就建立在仓颉标准集合之上。

## 本章目标

*   掌握 `ArrayList<T>` 的增删改查与遍历。
*   使用 `HashMap<K, V>` 存储键值配置。
*   编写泛型函数，让代码适用于任意类型。
*   熟悉基于闭包的集合迭代模式（map / filter 风格）。
*   构建 AIChatPro 的 `ConversationHistory` 对话历史管理类。

---

## 1. ArrayList

`ArrayList<T>` 是仓颉标准库中的动态数组，支持 O(1) 随机访问和均摊 O(1) 尾部追加。

### 1.1 基本操作

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

### 1.2 从数组构建 ArrayList

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

---

## 2. HashMap

`HashMap<K, V>` 提供 O(1) 平均查找时间，适合按名称存储配置项。

### 2.1 基本操作

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

### 2.2 HashMap 存储模型配置

<!-- check:run -->
```cangjie
import std.collection.HashMap

struct ModelConfig {
    let displayName: String
    let apiUrl: String
    let defaultModelId: String
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

---

## 3. 泛型函数

泛型（generics）让函数适用于任意类型，同时保持类型安全。

### 3.1 基础泛型函数

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

### 3.2 泛型转换函数

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
  8
  11
  10
  17
-->

---

## 4. 集合迭代模式

### 4.1 累积计算

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
总字符数: 101
用户消息数: 2
助手消息数: 2
-->

### 4.2 分组与统计

<!-- check:run -->
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
            if (ch == ':') {
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

<!-- expected_output:
user (2 条):
  - user: 你好
  - user: 今天天气
assistant (2 条):
  - assistant: 你好！
  - assistant: 我无法查询天气
system (1 条):
  - system: 系统维护中
-->

---

## 5. 对话历史管理

将以上知识整合成 AIChatPro 的核心组件：`ConversationHistory`。

### 5.1 ConversationHistory 实现

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
            // 移除最旧的一对消息（user + assistant）
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

    println("---")
    println("最近 2 条:")
    let latest = history.getLatest(2)
    for (i in 0..latest.size) {
        println("  ${latest[i]}")
    }

    println("---")
    history.clear()
    println("清空后大小: ${history.size}")
}
```

<!-- expected_output:
历史大小: 5
JSON 数组:
[{"role":"system","content":"你是一名专业的 AI 助手"},{"role":"user","content":"你好！"},{"role":"assistant","content":"你好！有什么可以帮到你？"},{"role":"user","content":"仓颉是什么语言？"},{"role":"assistant","content":"仓颉是华为推出的编程语言，适用于多种场景。"}]
---
最近 2 条:
  {"role":"user","content":"仓颉是什么语言？"}
  {"role":"assistant","content":"仓颉是华为推出的编程语言，适用于多种场景。"}
---
清空后大小: 0
-->

### 5.2 maxSize 滚动窗口测试

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
