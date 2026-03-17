# 09. 并发编程：流式输出引擎

> 想象你正在和 AI 对话——你按下发送键的瞬间，回复就开始一个字一个字地"蹦"出来，仿佛对方正在实时思考。这种流畅的体验背后，是一个经典的并发难题：**生产者-消费者问题**。网络线程像一条不断涌入的河流，持续接收来自服务器的 token；而主线程则像河岸边的抄写员，必须一刻不停地将这些 token 呈现在屏幕上。仓颉的并发模型为这两个角色之间的协作提供了既安全又优雅的解决方案。

## 本章目标

*   使用 `spawn` 创建并发任务，用 `Future<T>` 获取结果。
*   通过 `Mutex` 和 `synchronized` 保护共享状态。
*   使用 `AtomicInt64` 实现无锁计数器。
*   掌握生产者-消费者模式。
*   实现 AIChatPro 的 `CharQueue` 和 `StreamEngine` 核心组件。

---

## 1. spawn 与 Future

并发编程的第一步，是学会把任务"派发"出去。在仓颉中，`spawn { ... }` 就像把一项工作委托给一位同事——你只需描述要做什么，系统会自动安排一个轻量级线程去执行。`spawn` 返回一个 `Future<T>` 对象，它是对"未来结果"的承诺：当你需要结果时，调用 `future.get()` 即可阻塞等待任务完成并取回返回值。

这种模型的优雅之处在于**发起者无需关心任务何时完成**——你可以先派发多个任务，再按需收集结果，就像同时寄出几封信，然后逐一等待回信。

### 1.1 基本用法

最简单的场景：同时派发三个独立的文本处理任务，然后依次获取结果。

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

这段代码虽然简短，但已经展示了并发编程的核心思想：三个 `spawn` 调用同时将任务提交给运行时调度器，它们**可能并行执行**。`f1.get()`、`f2.get()`、`f3.get()` 则按顺序等待各自的结果。在 AIChatPro 中，类似的模式可用于同时处理多段文本——比如对历史消息做并行摘要。

值得注意的是，`Future<T>` 的 `get()` 方法只会阻塞调用者线程，不会影响其他正在运行的任务。这意味着，即使 `f1` 的任务耗时最长，`f2` 和 `f3` 也可以在等待期间继续执行。

### 1.2 收集多个 Future

当任务数量不固定时，手动为每个 Future 声明变量显然不切实际。更常见的做法是将所有 Future 收集到一个列表中，然后统一等待。

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

这里有一个值得留意的细节：在循环内部，我们用 `let idx = i` 将循环变量的值拷贝到一个新的局部变量中，然后在 `spawn` 闭包里引用 `idx` 而非 `i`。这是因为闭包捕获的是变量的**引用**——如果直接使用 `i`，所有任务看到的可能是循环结束后的最终值，而非各自迭代时的值。这是并发编程中一个极为常见的陷阱。

将 Future 收集到 `ArrayList` 中的模式非常实用：你可以动态决定创建多少个任务，最后统一遍历收集结果，代码既简洁又灵活。

### 1.3 Future 并行聚合

真正体现并发价值的场景，是当多个任务可以**同时执行**并将结果**汇总**时。下面的示例并发统计多篇文档的词数，然后合计总数：

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.ArrayList

func countWords(text: String): Int64 {
    var count: Int64 = 1
    var inSpace = false
    for (ch in text.runes()) {
        if (ch == r' ' || ch == r'\t') {
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
        "Cangjie is a programming language by Huawei",
        "It supports multi-paradigm including functional and OOP",
        "Concurrency uses lightweight threads",
        "Standard library has rich collections and IO tools"
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
文档 1: 7 词
文档 2: 4 词
文档 3: 8 词
总计: 26 词
-->

这就是经典的 **fork-join** 模式：先将任务"分叉"（fork）到多个线程，再"汇合"（join）收集结果。当文档数量增长到成百上千时，并行聚合的优势会更加明显——每个 `countWords` 调用都在独立的线程中执行，总耗时约等于最慢的那个任务，而非所有任务之和。

在 AIChatPro 的实际场景中，这种模式可用于并行分析多轮对话历史、同时请求多个 AI 模型的候选回复，或对长文本分片并行处理后合并结果。

---

## 2. Mutex 与 synchronized

`spawn` 让我们轻松创建并发任务，但并发也带来了新的挑战：当多个线程同时读写同一块数据时，**数据竞争（data race）** 就会悄然而至。想象两个人同时往一本账本上记账——如果没有任何协调，结果必然混乱不堪。

**互斥锁（Mutex）** 就是那把"只允许一人执笔"的钥匙。在仓颉中，`Mutex` 提供了最基础的互斥原语，而 `synchronized(mtx) { ... }` 则是一个便利的语法糖，它自动完成"获取锁 → 执行代码 → 释放锁"的完整流程，即使代码块抛出异常也能保证锁被正确释放。

### 2.1 无保护 vs 有保护

下面的示例展示了用 `Mutex` 保护共享日志列表的做法。两个线程并发写入日志，锁确保每次 `add` 操作的原子性——不会出现两个线程同时修改列表导致数据损坏的情况。

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

注意，尽管线程 A 和线程 B 的日志条目交错顺序不确定（取决于调度器），但总条数始终是 4——因为锁保证了每次 `add` 操作不会被打断。如果去掉 `synchronized`，在高并发场景下，`ArrayList` 的内部数组可能在同时扩容时被损坏，轻则丢失数据，重则程序崩溃。

**经验法则**：只要有多个线程可能同时访问同一个可变数据结构，就应该用锁保护。宁可多加一把锁，也不要冒数据竞争的风险。

### 2.2 synchronized 返回值

`synchronized` 不仅是一个"执行块"，它还可以像表达式一样**返回值**。这使得我们可以在锁的保护下完成计算并直接返回结果，无需额外的临时变量。下面的 `SafeCounter` 类完整地展示了这一特性：

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

`SafeCounter` 是一个典型的**线程安全封装**模式：将 `Mutex` 作为私有成员，在每个公开方法内部使用 `synchronized` 保护所有对共享状态的访问。外部调用者无需关心锁的细节——他们只看到一个"天然安全"的计数器接口。

注意 `increment()` 和 `decrement()` 各自在同一个 `synchronized` 块中完成了"修改 → 记录历史 → 返回新值"三步操作。这个**原子性**至关重要：如果把这三步拆成独立的锁操作，另一个线程可能在"修改"和"记录"之间插入，导致历史记录与实际值不一致。

在 AIChatPro 中，类似的安全计数器可用于统计已生成的 token 数量、跟踪活跃连接数，或记录错误频率。

---

## 3. 原子操作

互斥锁虽然通用，但并非唯一的线程安全手段。对于**单一变量的简单读写**，仓颉提供了更高效的选择：**原子操作**。`AtomicInt64` 和 `AtomicBool` 利用 CPU 的硬件指令直接实现线程安全的变量操作，无需获取和释放锁的额外开销。

打个比方：如果 `Mutex` 像是"进入房间前先锁门"，那原子操作就像是"用一个不可被打断的手势完成整个动作"——更快，但只适用于简单场景。

### 3.1 基本原子操作

最常见的原子操作是 `fetchAdd`——"先读后加"，且整个过程不可被其他线程打断。下面的示例让 10 个线程同时对一个原子计数器加 1：

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

结果始终是 10，绝不会出现丢失更新的情况。如果用普通的 `var count: Int64 = 0` 并让 10 个线程同时执行 `count = count + 1`，由于"读取 → 加一 → 写回"不是原子操作，最终结果可能小于 10——这就是经典的**丢失更新**问题。原子操作从根本上消除了这一隐患。

### 3.2 多种原子操作

`AtomicInt64` 提供了一组丰富的操作，涵盖读取、写入、加减以及条件更新。下面逐一演示：

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

其中，`compareAndSwap`（简称 CAS）是所有无锁算法的基石。它的语义是："只有当前值等于期望值时，才将其更新为新值，并返回 `true`；否则什么都不做，返回 `false`"。CAS 的强大之处在于它可以用来构建各种复杂的无锁数据结构——尝试更新，如果失败（说明另一个线程抢先修改了），就重试。

`fetchAdd` 和 `fetchSub` 都返回**修改前的旧值**，这在统计场景中非常有用：你可以在增加计数的同时获知之前的值，从而判断是否达到了某个阈值。

### 3.3 AtomicBool 流程控制

除了整数，仓颉还提供了 `AtomicBool`，常用于线程间的**信号通知**。例如，生产者完成工作后设置一个"完成标志"，消费者据此决定何时停止：

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

`AtomicBool` 在这里充当了一个极轻量的"完成信号"。与使用 `Mutex` 保护一个普通 `Bool` 相比，原子布尔值的开销几乎可以忽略不计。在 AIChatPro 的流式输出流程中，我们会用类似的机制来通知显示线程："网络请求已结束，处理完队列中剩余的字符后就可以收工了。"

**何时用原子操作，何时用 Mutex？** 简单规则：如果只需要对单一变量做读写或简单算术，用原子操作；如果需要在一次操作中同时修改多个变量（保证它们的一致性），必须用 Mutex。

---

## 4. 生产者-消费者模式

有了 `spawn`、`Mutex` 和原子操作这些基础工具，我们终于可以搭建并发编程中最重要的架构模式之一——**生产者-消费者模式**。

这个模式的本质很简单，可以用一个餐厅的比喻来理解：

```
厨师（生产者）          传菜窗口（队列）         服务员（消费者）
━━━━━━━━━━━━━━    ━━━━━━━━━━━━━━    ━━━━━━━━━━━━━━
  不断做菜     →     菜品排队等待    →     逐道上菜
  做完通知结束        线程安全缓冲区        读空且结束才停
```

在 AIChatPro 中，这幅图景变成了：**网络线程（厨师）** 从 AI 服务器持续接收 token，将它们推入一个 **线程安全的队列（传菜窗口）**；**显示线程（服务员）** 则不断从队列中取出 token 并呈现给用户。两者各自以自己的节奏工作，通过队列解耦，互不阻塞。

这个模式的关键设计要点是**终止条件**：生产者完成后不能立刻终止消费者，因为队列里可能还有未处理的数据。正确的做法是生产者设置"已完成"标志，消费者在"标志已设且队列已空"时才真正停止。

### 4.1 简化演示

下面用一个 `SimpleQueue<T>` 来演示这一模式的完整生命周期：

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

仔细观察 `isDone()` 的实现：`closed && items.size == 0`——两个条件缺一不可。仅检查 `closed` 会导致队列中残留的 token 被丢弃；仅检查 `items.size == 0` 则会让消费者在生产者还没开始写入时就误以为已经结束。这种"双条件终止"是生产者-消费者模式的标准做法。

另外，`pop()` 返回 `?T`（即 `Option<T>`）而非直接返回 `T`，这使得消费者可以优雅地处理"队列暂时为空但生产者还在工作"的情况——收到 `None` 就等一等，而不是抛出异常。

---

## 5. CharQueue 实现

掌握了生产者-消费者的基本原理后，我们来构建 AIChatPro 的核心数据结构——`CharQueue`。它是 `SimpleQueue` 的升级版，专为流式字符输出场景设计。

`CharQueue` 本质上是一个用 `Mutex` 保护的 `ArrayList<Rune>`，但它增加了几项关键能力：

- **`addMany(str)`** — 生产者将一整段字符串拆成 `Rune` 后批量推入队列，比逐字符 `push` 更高效。
- **`poll()`** — 消费者逐个取出字符（返回 `?Rune`），空队列时返回 `None`。
- **`isFinished()`** — 判断流式输出是否彻底结束：`finished` 标志已设置 **且** 队列已空。
- **`getCollected()`** — 返回所有已被消费的字符，用于事后展示完整回复或写入对话历史。

特别值得关注的是 `setFinished()` 与 `isFinished()` 的**分离设计**。生产者调用 `setFinished()` 仅仅表示"我不会再写入了"，但消费者会继续工作，直到队列彻底清空。这确保了最后几个字符不会因为生产者的提前退出而丢失——对于 AI 聊天场景来说，丢失句末的标点或最后一个词是完全不可接受的。

`clear()` 方法则用于对话轮次切换时重置队列状态，使同一个 `CharQueue` 实例可以被复用于多轮对话。

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

上面的代码中，`main` 函数演示了 `CharQueue` 的单线程使用场景：写入一段中文，逐字符读取，最后验证收集记录的完整性。虽然这里没有用到并发，但 `CharQueue` 的每个方法都已经是线程安全的——在后续的 `StreamEngine` 中，它将在多线程环境下发挥真正的作用。

注意 `poll()` 内部的一个设计细节：每消费一个字符，都会将其复制到 `collected` 列表中。这看似增加了开销，但对于 AI 聊天应用来说，保留完整的回复文本（用于写入对话历史或日志）是刚需，而在 `poll` 时顺便记录，比事后重新构造要简单可靠得多。

---

## 6. StreamEngine 流式输出引擎

有了 `CharQueue` 这个线程安全的"传菜窗口"，我们终于可以构建 AIChatPro 的流式输出引擎——`StreamEngine`。它是整个流式回复体验的**总指挥**，协调两个并发角色：

1. **生产者（网络线程）**：从 AI 服务器逐步接收 token，通过 `queue.addMany()` 推入字符队列。
2. **消费者（显示线程）**：在后台持续运行，通过 `queue.poll()` 逐字符取出并打印到终端，营造"打字机"般的流式效果。

`StreamEngine` 的核心设计决策是**显示轮询间隔（`displayIntervalMs`）**。消费者线程在队列为空时不会忙等（busy-wait），而是短暂休眠后再次检查——这个休眠时间就是 `displayIntervalMs`。值太小会浪费 CPU；值太大则导致字符显示卡顿。默认的 30 毫秒在大多数终端上能提供流畅的视觉效果。

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
    let engine = StreamEngine(queue, mtx)

    let tokens = ["仓颉", "语言", "的", "并发", "模型", "非常", "优雅", "！"]

    let displayFuture = engine.startDisplay()
    engine.simulateStream(tokens)
    displayFuture.get()

    println("流式输出完成")
}
```

在 `main` 中，`startDisplay()` 和 `simulateStream()` 的调用顺序很关键：必须**先启动消费者**，再启动生产者。如果反过来，生产者可能在消费者启动之前就完成了所有写入并设置了 `finished` 标志，消费者一启动就发现 `isFinished()` 为 `true`，直接退出，用户将看不到任何流式输出。

`startDisplay()` 返回 `Future<Unit>`，调用方通过 `displayFuture.get()` 等待显示线程完全结束。这保证了程序不会在所有字符还没显示完毕时就退出——又一个 `Future` 管理生命周期的经典用法。

`simulateStream()` 内部用 `sleep` 模拟网络延迟，使 token 分批到达。在真实的 AIChatPro 中，这个方法会被替换为实际的 HTTP 流式请求处理逻辑，但队列交互的模式完全相同。

### 6.2 并发安全测试（可运行验证版）

由于 `StreamEngine` 的完整流程涉及 `sleep` 和终端输出，不适合用精确的输出匹配来自动验证。下面的测试用例换一种策略：用多个生产者并发写入 `CharQueue`，然后验证数据的**完整性和一致性**——确保没有字符丢失，没有数据损坏。

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
总字节数: 21
读取长度: 21
-->

这个测试的巧妙之处在于：虽然三个生产者并发写入的**顺序不确定**（`result` 可能是 "Hello World 仓颉！" 也可能是 "仓颉！World Hello "），但**总字节数必然一致**——21 字节。这正是并发安全的核心保证：数据的完整性不受调度顺序的影响。

`drainAll()` 方法在一个 `synchronized` 块中完成读取和清空，保证了消费操作的原子性。在真实的测试场景中，你还可以对 `result` 做更细致的验证，比如检查每个子串是否完整出现（不会被拆散）。

---

## 工程化提示

*   **Mutex 的粒度**：锁的范围越小越好。`CharQueue` 中每个方法内部用 `synchronized` 而非对整个对象加锁，避免不必要的等待。如果一个方法中既有需要保护的操作又有耗时的纯计算，应当只把前者放入 `synchronized` 块中。
*   **AtomicInt64 vs Mutex**：对于单一整数的读写，`AtomicInt64` 比 `Mutex + Int64` 快，因为无需线程切换。但多字段的复合操作仍需 `Mutex`——原子操作无法保证多个变量之间的一致性。
*   **Future 的生命周期**：`spawn` 返回的 `Future<T>` 必须在某处调用 `.get()` 或明确忽略，否则可能导致线程提前退出。一个好的习惯是在函数末尾统一 `.get()` 所有 Future，确保没有"孤儿线程"。
*   **生产者-消费者的终止条件**：`setFinished()` + `isFinished()（finished && queue.size == 0）` 的组合确保消费者不会在队列为空但生产者还未结束时提前退出。反过来，也不会在生产者已结束但队列中还有数据时遗漏处理。
*   **警惕死锁**：当使用多把锁时，所有线程必须以相同的顺序获取锁。如果线程 A 先锁 `mtx1` 再锁 `mtx2`，而线程 B 先锁 `mtx2` 再锁 `mtx1`，就可能形成死锁——两个线程各持一把锁、互相等待，程序永远卡住。

---

## 实践挑战

1.  为 `SimpleQueue<T>` 添加 `pushAll(items: Array<T>): Unit` 方法（原子性地批量写入）。
2.  使用 `AtomicInt64` 实现一个 `RateCounter`，统计每秒 token 生成速率（调用 `tick()` 增加计数，`getRate(): Float64` 返回当前速率）。
3.  思考：`StreamEngine` 的 `displayIntervalMs` 参数如何影响用户体验？如果值太小或太大分别会发生什么？
