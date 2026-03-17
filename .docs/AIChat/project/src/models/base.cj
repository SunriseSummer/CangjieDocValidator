/**
 * BaseChatModel 接口
 *
 * 定义 AI 聊天模型的统一接口，所有具体模型（KimiModel、GlmModel 等）
 * 都需要实现此接口。这体现了面向接口编程的策略模式：
 * - chat()：发送请求并将响应写入字符队列
 * - getName()：获取模型名称
 * - getModelId()：获取模型标识符
 */
package aichat.models

import std.sync.Mutex
import aichat.stream.CharQueue

/**
 * AI 聊天模型的统一接口
 *
 * chat 方法的三个参数分别承载不同职责：
 * - request：包含消息列表和模型参数的请求数据
 * - queue：线程安全的字符队列，用于将响应文本传递给显示线程
 * - mtx：互斥锁，用于同步对 queue 的写入操作
 */
public interface BaseChatModel {
    func chat(request: ChatRequest, queue: CharQueue, mtx: Mutex): Unit
    func getName(): String
    func getModelId(): String
}
