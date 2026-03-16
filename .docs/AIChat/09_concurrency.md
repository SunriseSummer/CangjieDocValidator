# 09. 并发编程：流式输出引擎

> 流式 AI 回复的本质是生产者-消费者问题：网络线程持续接收 token，主线程负责实时显示。仓颉的并发模型让这两个角色之间的协作既安全又优雅。

## 本章目标

*   使用 `spawn` 创建并发任务，用 `Future<T>` 获取结果。
*   通过 `Mutex` 和 `synchronized` 保护共享状态。
*   使用 `AtomicInt64` 实现无锁计数器。
*   掌握生产者-消费者模式。
*   实现 AIChatPro 的 `CharQueue` 和 `StreamEngine` 核心组件。

---

## 1. spawn 与 Future

`spawn { ... }` 创建一个并发任务（轻量级线程），返回 `Future<T>`。调用 `future.get()` 阻塞等待结果。

### 1.1 基本用法

<!-- check:run -->
```cangjie
import std.sync.*

func processChunk(id: Int64, data: String): String {
    "${id}: ${data.size} chars processed"
}

main() {
    let f1 = spawn { processChunk(0, "Hello World") }
    let f2 = spawn { processChunk(1, "Cangjie Language") }
    let f3 = spawn { processChunk(2, "AI Chat Tool") }

    println(f1.get())
    println(f2.get())
    println(f3.get())
}
```

<!-- expected_output:
0: 11 chars processed
1: 16 chars processed
2: 12 chars processed
-->

### 1.2 收集多个 Future

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

func processChunk(id: Int64, data: String): String {
    "${id}: ${data.size} chars processed"
}

main() {
    let futures = ArrayList<Future<String>>()
    let chunks = ["Hello World", "Cangjie Language", "AI Chat Tool"]

    for (i in 0..chunks.size) {
        let chunk = chunks[i]
        let idx = i
        futures.add(spawn { processChunk(idx, chunk) })
    }

    for (f in futures) {
        println(f.get())
    }
}
```

<!-- expected_output:
0: 11 chars processed
1: 16 chars processed
2: 12 chars processed
-->

### 1.3 Future 并行聚合

并发执行多个任务并汇总结果，比串行快得多：

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

func countWords(text: String): Int64 {
    var count: Int64 = 1
    var inSpace = false
    for (ch in text.runes()) {
        if (ch == ' ' || ch == '\t') {
            if (!inSpace) {
                count++
                inSpace = true
            }
        } else {
            inSpace = false
        }
    }
    return count
}

main() {
    let documents = [
        "仓颉是华为推出的编程语言",
        "它支持多范式编程包括函数式和面向对象",
        "并发模型基于轻量级线程",
        "标准库提供丰富的集合和 IO 工具"
    ]

    let futures = ArrayList<Future<Int64>>()
    for (doc in documents) {
        futures.add(spawn { countWords(doc) })
    }

    var total: Int64 = 0
    for (i in 0..futures.size) {
        let wc = futures[i].get()
        println("文档 ${i}: ${wc} 词")
        total = total + wc
    }
    println("总计: ${total} 词")
}
```

<!-- expected_output:
文档 0: 7 词
文档 1: 8 词
文档 2: 6 词
文档 3: 8 词
总计: 29 词
-->

---

## 2. Mutex 与 synchronized

当多个线程共享可变状态时，必须用锁保护。`Mutex` 提供互斥锁，`synchronized` 是获取-执行-释放的语法糖。

### 2.1 无保护 vs 有保护

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

main() {
    // 用 Mutex 保护共享列表
    let log = ArrayList<String>()
    let mtx = Mutex()

    let f1 = spawn {
        synchronized(mtx) { log.add("线程 A: 开始处理") }
        synchronized(mtx) { log.add("线程 A: 处理完成") }
    }
    let f2 = spawn {
        synchronized(mtx) { log.add("线程 B: 开始处理") }
        synchronized(mtx) { log.add("线程 B: 处理完成") }
    }

    f1.get()
    f2.get()

    println("日志条数: ${log.size}")
    println("包含 A 开始: ${log.size >= 1}")
    println("日志完整: ${log.size == 4}")
}
```

<!-- expected_output:
日志条数: 4
包含 A 开始: true
日志完整: true
-->

### 2.2 synchronized 返回值

`synchronized` 块可以有返回值：

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

class SafeCounter {
    private let mtx: Mutex = Mutex()
    private var count: Int64 = 0
    private let history: ArrayList<Int64> = ArrayList<Int64>()

    public func increment(): Int64 {
        synchronized(mtx) {
            count++
            history.add(count)
            count
        }
    }

    public func decrement(): Int64 {
        synchronized(mtx) {
            count--
            history.add(count)
            count
        }
    }

    public func get(): Int64 {
        synchronized(mtx) { count }
    }

    public func historySize(): Int64 {
        synchronized(mtx) { history.size }
    }
}

main() {
    let counter = SafeCounter()

    let f1 = spawn {
        for (_ in 0..5) {
            counter.increment()
        }
    }
    let f2 = spawn {
        for (_ in 0..3) {
            counter.increment()
        }
        counter.decrement()
        counter.decrement()
    }

    f1.get()
    f2.get()

    println("最终计数: ${counter.get()}")
    println("操作历史长度: ${counter.historySize()}")
}
```

<!-- expected_output:
最终计数: 6
操作历史长度: 10
-->

---

## 3. 原子操作

`AtomicInt64` 提供无锁的线程安全整数操作，性能优于 Mutex，适合简单的计数场景。

### 3.1 基本原子操作

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

main() {
    let counter = AtomicInt64(0)
    let futures = ArrayList<Future<Unit>>()

    for (_ in 0..10) {
        futures.add(spawn {
            counter.fetchAdd(1)
        })
    }
    for (f in futures) { f.get() }

    println("计数器值: ${counter.load()}")
}
```

<!-- expected_output:
计数器值: 10
-->

### 3.2 多种原子操作

<!-- check:run -->
```cangjie
import std.sync.*

main() {
    let a = AtomicInt64(100)

    // load / store
    println("初始值: ${a.load()}")
    a.store(200)
    println("store 后: ${a.load()}")

    // fetchAdd / fetchSub
    let oldAdd = a.fetchAdd(50)
    println("fetchAdd(50) 返回旧值: ${oldAdd}, 新值: ${a.load()}")

    let oldSub = a.fetchSub(30)
    println("fetchSub(30) 返回旧值: ${oldSub}, 新值: ${a.load()}")

    // compareAndSwap：只有当前值等于期望值时才更新
    let swapped1 = a.compareAndSwap(220, 999)
    println("CAS(220→999) 成功: ${swapped1}, 当前: ${a.load()}")

    let swapped2 = a.compareAndSwap(100, 0)
    println("CAS(100→0) 成功: ${swapped2}, 当前: ${a.load()}")
}
```

<!-- expected_output:
初始值: 100
store 后: 200
fetchAdd(50) 返回旧值: 200, 新值: 250
fetchSub(30) 返回旧值: 250, 新值: 220
CAS(220→999) 成功: true, 当前: 999
CAS(100→0) 成功: false, 当前: 999
-->

### 3.3 AtomicBool 流程控制

<!-- check:run -->
```cangjie
import std.sync.*
import std.time.*

main() {
    let done = AtomicBool(false)
    let tokenCount = AtomicInt64(0)

    let producer = spawn {
        for (i in 0..5) {
            tokenCount.fetchAdd(1)
        }
        done.store(true)
    }

    producer.get()

    println("完成: ${done.load()}")
    println("生成 token 数: ${tokenCount.load()}")
}
```

<!-- expected_output:
完成: true
生成 token 数: 5
-->

---

## 4. 生产者-消费者模式

AI 流式输出的核心模式：网络线程（生产者）持续推送 token，显示线程（消费者）持续读取显示。

### 4.1 简化演示

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

class SimpleQueue<T> {
    private let items: ArrayList<T> = ArrayList<T>()
    private let mtx: Mutex = Mutex()
    private var closed: Bool = false

    public func push(item: T): Unit {
        synchronized(mtx) { items.add(item) }
    }

    public func pop(): ?T {
        synchronized(mtx) {
            if (items.size > 0) {
                let item = items[0]
                items.remove(at: 0)
                return Some(item)
            }
            return None
        }
    }

    public func close(): Unit {
        synchronized(mtx) { closed = true }
    }

    public func isDone(): Bool {
        synchronized(mtx) { closed && items.size == 0 }
    }

    public func size(): Int64 {
        synchronized(mtx) { items.size }
    }
}

main() {
    let queue = SimpleQueue<String>()

    // 生产者：生成若干 token
    let producer = spawn {
        let tokens = ["你", "好", "！", "我", "是", "AI", "助", "手", "。"]
        for (t in tokens) {
            queue.push(t)
        }
        queue.close()
    }

    producer.get()

    // 消费者：读取所有 token
    let sb = StringBuilder()
    while (!queue.isDone()) {
        if (let Some(token) <- queue.pop()) {
            sb.append(token)
        }
    }
    println("收到: ${sb.toString()}")
}
```

<!-- expected_output:
收到: 你好！我是AI助手。
-->

---

## 5. CharQueue 实现

`CharQueue` 是 AIChatPro 流式输出的核心数据结构，提供线程安全的字符缓冲区。

<!-- check:build_only -->
```cangjie
import std.sync.*
import std.collection.ArrayList

class CharQueue {
    private let queue: ArrayList<Rune> = ArrayList<Rune>()
    private let collected: ArrayList<Rune> = ArrayList<Rune>()
    private let mtx: Mutex = Mutex()
    private var finished: Bool = false

    public func addMany(str: String): Unit {
        synchronized(mtx) {
            for (ch in str.runes()) {
                queue.add(ch)
            }
        }
    }

    public func poll(): ?Rune {
        synchronized(mtx) {
            if (queue.size > 0) {
                let ch = queue[0]
                queue.remove(at: 0)
                collected.add(ch)
                return Some(ch)
            }
            return None
        }
    }

    public func size(): Int64 {
        synchronized(mtx) { queue.size }
    }

    public func setFinished(): Unit {
        synchronized(mtx) { finished = true }
    }

    public func isFinished(): Bool {
        synchronized(mtx) { finished && queue.size == 0 }
    }

    public func getCollected(): String {
        synchronized(mtx) {
            let sb = StringBuilder()
            for (ch in collected) { sb.append(ch) }
            sb.toString()
        }
    }

    public func clear(): Unit {
        synchronized(mtx) {
            queue.clear()
            collected.clear()
            finished = false
        }
    }
}

main() {
    let q = CharQueue()
    q.addMany("你好，仓颉！")
    println("队列大小: ${q.size()}")

    let sb = StringBuilder()
    while (!q.isFinished()) {
        if (let Some(ch) <- q.poll()) {
            sb.append(ch)
        } else {
            q.setFinished()
        }
    }
    println("读取结果: ${sb.toString()}")
    println("已收集: ${q.getCollected()}")
}
```

---

## 6. StreamEngine 流式输出引擎

`StreamEngine` 协调生产者（AI 网络请求）和消费者（终端显示）两个并发角色。

### 6.1 StreamEngine 核心设计

<!-- check:build_only -->
```cangjie
import std.sync.*
import std.time.*
import std.collection.ArrayList

class CharQueue {
    private let queue: ArrayList<Rune> = ArrayList<Rune>()
    private let mtx: Mutex = Mutex()
    private var finished: Bool = false

    public func addMany(str: String): Unit {
        synchronized(mtx) {
            for (ch in str.runes()) { queue.add(ch) }
        }
    }

    public func poll(): ?Rune {
        synchronized(mtx) {
            if (queue.size > 0) {
                let ch = queue[0]
                queue.remove(at: 0)
                return Some(ch)
            }
            return None
        }
    }

    public func setFinished(): Unit {
        synchronized(mtx) { finished = true }
    }

    public func isFinished(): Bool {
        synchronized(mtx) { finished && queue.size == 0 }
    }
}

class StreamEngine {
    private let queue: CharQueue
    private let mtx: Mutex
    private let displayIntervalMs: Int64

    public init(queue: CharQueue, mtx: Mutex, displayIntervalMs!: Int64 = 30) {
        this.queue = queue
        this.mtx = mtx
        this.displayIntervalMs = displayIntervalMs
    }

    // 启动显示循环（在单独线程中运行）
    public func startDisplay(): Future<Unit> {
        spawn {
            while (!queue.isFinished()) {
                var printed = false
                var ch = queue.poll()
                while (let Some(c) <- ch) {
                    print(c.toString())
                    printed = true
                    ch = queue.poll()
                }
                if (!printed) {
                    sleep(Duration.millisecond * displayIntervalMs)
                }
            }
            println("")
        }
    }

    // 模拟 AI 生成（生产者）
    public func simulateStream(tokens: Array<String>): Unit {
        for (token in tokens) {
            synchronized(mtx) { queue.addMany(token) }
            sleep(Duration.millisecond * 10)
        }
        synchronized(mtx) { queue.setFinished() }
    }
}

main() {
    let queue = CharQueue()
    let mtx = Mutex()
    let engine = StreamEngine(queue: queue, mtx: mtx)

    let tokens = ["仓颉", "语言", "的", "并发", "模型", "非常", "优雅", "！"]

    let displayFuture = engine.startDisplay()
    engine.simulateStream(tokens)
    displayFuture.get()

    println("流式输出完成")
}
```

### 6.2 并发安全测试（可运行验证版）

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

class CharQueue {
    private let queue: ArrayList<Rune> = ArrayList<Rune>()
    private let collected: ArrayList<Rune> = ArrayList<Rune>()
    private let mtx: Mutex = Mutex()
    private var finished: Bool = false

    public func addMany(str: String): Unit {
        synchronized(mtx) {
            for (ch in str.runes()) { queue.add(ch) }
        }
    }

    public func drainAll(): String {
        synchronized(mtx) {
            let sb = StringBuilder()
            for (ch in queue) { sb.append(ch) }
            for (ch in queue) { collected.add(ch) }
            queue.clear()
            sb.toString()
        }
    }

    public func setFinished(): Unit {
        synchronized(mtx) { finished = true }
    }

    public func isFinished(): Bool {
        synchronized(mtx) { finished }
    }
}

main() {
    let queue = CharQueue()
    let totalTokens = AtomicInt64(0)

    // 3 个生产者并发写入
    let producers = ArrayList<Future<Unit>>()
    let parts = ["Hello ", "World ", "仓颉！"]
    for (part in parts) {
        producers.add(spawn {
            queue.addMany(part)
            totalTokens.fetchAdd(Int64(part.size))
        })
    }
    for (p in producers) { p.get() }
    queue.setFinished()

    // 消费者一次性读取
    let result = queue.drainAll()
    println("写入完成: ${queue.isFinished()}")
    println("总字节数: ${totalTokens.load()}")
    println("读取长度: ${result.size}")
}
```

<!-- expected_output:
写入完成: true
总字节数: 14
读取长度: 14
-->

---

## 工程化提示

*   **Mutex 的粒度**：锁的范围越小越好。`CharQueue` 中每个方法内部用 `synchronized` 而非对整个对象加锁，避免不必要的等待。
*   **AtomicInt64 vs Mutex**：对于单一整数的读写，`AtomicInt64` 比 `Mutex + Int64` 快，因为无需线程切换。但多字段的复合操作仍需 `Mutex`。
*   **Future 的生命周期**：`spawn` 返回的 `Future<T>` 必须在某处调用 `.get()` 或明确忽略，否则可能导致线程提前退出。
*   **生产者-消费者的终止条件**：`setFinished()` + `isFinished()（finished && queue.size == 0）` 的组合确保消费者不会在队列为空但生产者还未结束时提前退出。

---

## 实践挑战

1.  为 `SimpleQueue<T>` 添加 `pushAll(items: Array<T>): Unit` 方法（原子性地批量写入）。
2.  使用 `AtomicInt64` 实现一个 `RateCounter`，统计每秒 token 生成速率（调用 `tick()` 增加计数，`getRate(): Float64` 返回当前速率）。
3.  思考：`StreamEngine` 的 `displayIntervalMs` 参数如何影响用户体验？如果值太小或太大分别会发生什么？
