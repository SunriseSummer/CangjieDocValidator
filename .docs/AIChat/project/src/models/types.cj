/**
 * 数据模型类型定义
 *
 * 定义 AI 对话中的核心数据结构：
 * - ChatMessage：单条对话消息（角色 + 内容）
 * - ChatRequest：发送给 AI 的请求（模型、消息列表、参数）
 * - ConversationHistory：对话历史管理器（滚动窗口策略）
 */
package aichat.models

import std.collection.ArrayList

/**
 * 对话消息类
 *
 * 表示一条对话中的消息，包含角色（user/assistant/system）和内容。
 */
public class ChatMessage {
    public let role: String      // 消息角色：user（用户）、assistant（AI）、system（系统）
    public let content: String   // 消息内容

    public init(role: String, content: String) {
        this.role = role
        this.content = content
    }
}

/**
 * AI 聊天请求类
 *
 * 封装发送给 AI API 的请求参数：
 * - model：模型标识符
 * - messages：对话消息列表
 * - stream：是否使用流式输出（SSE）
 * - temperature：生成温度（0.0-1.0，越高越随机）
 */
public class ChatRequest {
    public let model: String
    public let messages: ArrayList<ChatMessage>
    public let stream: Bool
    public let temperature: Float64

    public init(
        model: String,
        messages: ArrayList<ChatMessage>,
        stream!: Bool = true,
        temperature!: Float64 = 0.7
    ) {
        this.model = model
        this.messages = messages
        this.stream = stream
        this.temperature = temperature
    }
}

/**
 * 对话历史管理器
 *
 * 采用滚动窗口策略管理对话历史：
 * - 当消息数量达到上限时，自动移除最早的一对消息（问/答）
 * - 防止对话历史无限增长，避免内存溢出或超出 AI API 的 token 限制
 */
public class ConversationHistory {
    private let messages: ArrayList<ChatMessage> = ArrayList<ChatMessage>()
    private let maxSize: Int64  // 最大消息数量

    public init(maxSize!: Int64 = 20) {
        this.maxSize = maxSize
    }

    /**
     * 添加一条消息到历史
     *
     * 当超出容量时，移除最早的两条消息（一问一答），
     * 保持对话上下文的完整性。
     */
    public func add(role: String, content: String): Unit {
        if (messages.size >= maxSize) {
            messages.remove(at: 0)
            if (messages.size > 0) { messages.remove(at: 0) }
        }
        messages.add(ChatMessage(role, content))
    }

    /** 返回当前所有消息的副本，用于构建 API 请求 */
    public func toArrayList(): ArrayList<ChatMessage> {
        let result = ArrayList<ChatMessage>()
        for (i in 0..messages.size) {
            result.add(messages[i])
        }
        return result
    }

    /** 清空对话历史 */
    public func clear(): Unit { messages.clear() }

    /** 当前消息数量 */
    public prop size: Int64 { get() { messages.size } }
}
