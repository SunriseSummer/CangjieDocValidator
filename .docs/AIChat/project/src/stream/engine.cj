/**
 * StreamEngine —— 流式显示引擎
 *
 * 在独立线程中以轮询方式从 CharQueue 中取出字符并逐个打印，
 * 实现"边接收边输出"的打字机效果。
 *
 * 支持自适应速率控制：
 * - 队列积压超过 burstThreshold 时，切换到 catchupIntervalMs（快速追赶模式）
 * - 正常状态使用 baseIntervalMs（舒适阅读速度）
 */
package aichat.stream

import std.sync.Mutex
import aichat.config.StreamSettings

public class StreamEngine {
    private let queue: CharQueue            // 字符缓冲队列
    private let settings: StreamSettings    // 流式输出设置
    private let mtx: Mutex                  // 互斥锁

    public init(queue: CharQueue, settings: StreamSettings, mtx: Mutex) {
        this.queue = queue
        this.settings = settings
        this.mtx = mtx
    }

    /**
     * 启动显示循环（在当前线程运行）
     *
     * 持续从队列中取出字符并打印，直到队列标记为已完成且所有字符都已消费。
     * 根据队列积压情况自适应调节轮询间隔。
     */
    public func run(): Unit {
        while (!queue.isFinished()) {
            // 根据队列积压量自适应调节间隔
            let queueSize = queue.size()
            let interval = if (queueSize > settings.burstThreshold) {
                settings.catchupIntervalMs  // 积压多，快速追赶
            } else {
                settings.baseIntervalMs     // 正常速度
            }

            if (let Some(ch) <- queue.poll()) {
                print(ch)
            } else {
                sleep(Duration.millisecond * interval)
            }
        }
    }
}

