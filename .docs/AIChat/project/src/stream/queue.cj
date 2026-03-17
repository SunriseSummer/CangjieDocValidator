/**
 * CharQueue —— 线程安全的字符缓冲队列
 *
 * 作为网络线程（生产者）与显示线程（消费者）之间的桥梁：
 * - 网络线程从 AI API 接收到文本后，通过 addMany() 写入队列
 * - 显示线程通过 poll() 逐字符取出并打印
 *
 * 所有操作都在 synchronized(mtx) 保护下进行，确保线程安全。
 * collected 列表记录所有已消费的字符，用于最终组装完整的 AI 回复。
 */
package aichat.stream

import std.sync.Mutex
import std.collection.ArrayList

public class CharQueue {
    private let queue: ArrayList<Rune> = ArrayList<Rune>()         // 待消费的字符队列
    private let collected: ArrayList<Rune> = ArrayList<Rune>()     // 已消费的字符记录
    private let mtx: Mutex = Mutex()                               // 内部互斥锁
    private var finished: Bool = false                              // 生产者是否已完成

    /**
     * 批量添加字符到队列
     *
     * 将字符串拆分为 Rune（Unicode 字符）后逐个入队，
     * 确保中文等多字节字符的正确处理。
     */
    public func addMany(str: String): Unit {
        synchronized(mtx) {
            for (ch in str.runes()) { queue.add(ch) }
        }
    }

    /**
     * 取出队列头部的一个字符
     *
     * 返回 Option 类型：有字符返回 Some(ch)，队列为空返回 None。
     * 同时将字符记录到 collected 列表中。
     */
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

    /** 获取当前队列中待消费的字符数量 */
    public func size(): Int64 {
        synchronized(mtx) { queue.size }
    }

    /** 标记生产者已完成（网络请求结束） */
    public func setFinished(): Unit {
        synchronized(mtx) { finished = true }
    }

    /** 判断是否已完成：生产者结束且队列已全部消费 */
    public func isFinished(): Bool {
        synchronized(mtx) { finished && queue.size == 0 }
    }

    /** 获取所有已消费字符组成的完整字符串（即 AI 的完整回复） */
    public func getCollected(): String {
        synchronized(mtx) {
            let sb = StringBuilder()
            for (ch in collected) { sb.append(ch) }
            sb.toString()
        }
    }

    /** 重置队列状态，用于开始新一轮对话 */
    public func clear(): Unit {
        synchronized(mtx) {
            queue.clear()
            collected.clear()
            finished = false
        }
    }
}
