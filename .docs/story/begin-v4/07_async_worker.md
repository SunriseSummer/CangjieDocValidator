# 第七章：并发 Worker 模型 (并发编程)

> Web 服务器必须能同时处理成千上万个请求。虽然仓颉的 `main` 是单线程的，但通过 `spawn` 我们可以实现高并发，并将耗时任务分发给 Worker。

## 本章目标

*   理解并发 Worker 的调度与同步方式。
*   学会用原子变量统计共享指标。
*   建立"异步处理 + 主线程协作"的工程认知。

在单核时代，程序按顺序一行一行执行，处理一个请求时其他请求只能排队等待。现代 Web 服务每秒需要应对数千个并发请求，如果仍然顺序处理，99% 的请求都会超时。**并发（Concurrency）**是解决方案：操作系统在多个任务之间快速切换，给每个任务都分配执行时间，从用户角度看好像在"同时"处理。**并行（Parallelism）**则是真正的同时：在多核处理器上，不同核心真的在同一时刻执行不同任务。

仓颉通过 `spawn` 关键字创建**轻量级线程（协程）**，运行时负责将这些协程调度到操作系统线程上执行。与操作系统线程相比，协程的创建开销极低（仅需数百字节栈空间），一台服务器可以运行数十万个协程，这正是现代高并发服务器的基础。

## 1. 请求处理 Worker

模拟一个能够并发处理请求的 Worker 池。

`spawn { ... }` 返回一个 `Future<Unit>` 对象，代表"一个将来会完成的计算"。`Future` 是异步编程的核心抽象：主线程可以继续执行其他任务，稍后再通过 `f.get()` 等待结果。这就像餐厅下单后拿到一张取餐票（Future），服务员（Worker）在后厨准备，顾客（主线程）可以先去做其他事，凭票取餐时才真正等待。

<!-- check:run -->
```cangjie
import std.sync.*
import std.collection.*

// 模拟耗时的业务逻辑
func handleRequest(id: Int64) {
    let processTime = Duration.millisecond * (id * 100) // 模拟不同耗时
    println("Worker [${id}]: 开始处理 (预计 ${id * 100}ms)")
    sleep(processTime)
    println("Worker [${id}]: 完成")
}

main() {
    println(">>> Web 服务器启动，准备接收并发请求...")

    let futures = ArrayList<Future<Unit>>()

    // 模拟瞬间涌入 5 个请求
    for (i in 1..=5) {
        // spawn 启动轻量级线程
        let f = spawn {
            handleRequest(i)
        }
        futures.add(f)
    }

    println(">>> 主线程：所有请求已分发，继续监听新请求...")

    // 模拟主线程做其他事
    sleep(Duration.second)

    // 等待所有请求完成 (实际 Server 不需要等，这里为了演示)
    for (f in futures) { f.get() }
    println(">>> 所有请求处理完毕。")
}
```

## 2. 线程安全计数器 (Atomic)

统计服务器的总请求数 (QPS)，必须保证线程安全。

为什么普通的 `var count = 0` 在并发场景中不安全？因为 `count += 1` 在 CPU 层面是三步操作：**读取** → **加一** → **写回**。当两个线程同时执行这三步时，可能出现：线程 A 读到 0，线程 B 也读到 0，两者都写回 1——本该加两次，结果只加了一次。这就是**竞态条件（Race Condition）**。

`AtomicInt64` 通过 CPU 的原子指令保证"读-改-写"三步不可分割，从硬件层面消除竞态条件，且无需加锁，性能远优于 `Mutex`。这是高并发计数器的标准实现方式，在监控系统、限流器、QPS 统计等场景中广泛使用。

<!-- check:run -->
```cangjie
import std.sync.*

main() {
    let totalRequests = AtomicInt64(0)

    // 并发增加计数
    for (i in 0..100) {
        spawn {
            totalRequests.fetchAdd(1)
        }
    }

    sleep(Duration.millisecond * 500)
    println("总请求数: ${totalRequests.load()}")
}
```

<!-- expected_output:
总请求数: 100
-->

**代码解析：**

- `AtomicInt64(0)`：创建一个初始值为 0 的原子整数。`AtomicInt64` 封装了底层的原子操作，对外提供 `fetchAdd`（原子加）和 `load`（原子读）等方法。
- `totalRequests.fetchAdd(1)`：原子地将计数加 1，返回加之前的旧值。无论多少个协程同时调用，每次调用都保证精确地加 1，不会有任何丢失。
- `sleep(Duration.millisecond * 500)`：等待 500ms，让所有 100 个协程完成计数。实际工程中应用 `Future.get()` 等待，这里用 `sleep` 演示效果。
- 最终输出 `100`：验证了 100 次并发计数全部正确记录，没有因竞态条件丢失任何计数。

**💡 核心要点**

- **`spawn` 创建轻量级线程**：仓颉协程开销极低，可大量创建，适合高并发 I/O 密集型任务。
- **`Future<T>` 表示异步结果**：`spawn` 的返回值，通过 `.get()` 阻塞等待并获取结果，实现主线程与协程的同步。
- **竞态条件（Race Condition）**：多线程共享可变状态时，非原子操作会导致数据不一致，这是并发编程的首要陷阱。
- **`AtomicInt64` vs `Mutex`**：原子操作通过 CPU 指令保证原子性，无需操作系统介入，性能优于互斥锁，适合计数器等简单共享变量。

## 工程化提示

*   真实服务会使用线程池或协程框架，本例仅演示核心概念。
*   计数器更新应考虑高并发下的性能瓶颈。
*   请求处理建议添加超时与异常捕获机制。

## 小试身手

1. 为 `handleRequest` 增加失败分支，并统计失败次数。
2. 将 `totalRequests` 统计改为"成功/失败"双计数。
