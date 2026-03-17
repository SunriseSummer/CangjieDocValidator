/**
 * StreamEngine —— 流式显示引擎
 *
 * 在独立线程中以轮询方式从 CharQueue 中取出字符并逐个打印，
 * 实现"边接收边输出"的打字机效果。
 *
 * displayIntervalMs 控制无数据时的休眠间隔：
 * - 间隔过短：浪费 CPU 资源
 * - 间隔过长：用户感到输出卡顿
 * 默认 30ms 是一个兼顾响应灵敏度与 CPU 占用的折中值。
 */
package aichat.stream

import std.sync.*

public class StreamEngine {
    private let queue: CharQueue           // 字符缓冲队列
    private let mtx: Mutex                 // 互斥锁（与 CharQueue 共享）
    private let displayIntervalMs: Int64   // 无数据时的轮询间隔（毫秒）

    public init(queue: CharQueue, mtx: Mutex, displayIntervalMs!: Int64 = 30) {
        this.queue = queue
        this.mtx = mtx
        this.displayIntervalMs = displayIntervalMs
    }

    /**
     * 启动显示线程
     *
     * 使用 spawn 创建新线程，持续从队列中取出字符并打印，
     * 直到队列标记为已完成且所有字符都已消费。
     * 返回 Future<Unit>，调用方可通过 get() 等待显示完成。
     */
    public func startDisplay(): Future<Unit> {
        spawn {
            while (!queue.isFinished()) {
                var hasOutput = false
                var ch = queue.poll()
                // 使用 while-let 模式匹配，持续取出字符直到队列为空
                while (let Some(c) <- ch) {
                    print(c.toString())
                    hasOutput = true
                    ch = queue.poll()
                }
                // 队列暂时为空但未结束，短暂休眠后继续轮询
                if (!hasOutput) {
                    sleep(Duration.millisecond * displayIntervalMs)
                }
            }
            println("")  // 输出完成后换行
        }
    }
}
