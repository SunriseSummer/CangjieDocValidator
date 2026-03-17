/**
 * 配置类型定义
 *
 * 定义 AIChatPro 项目中所有配置相关的数据类型，包括：
 * - ModelConfig：AI 模型配置信息（名称、API 地址、模型标识）
 * - StreamSettings：流式输出设置（刷新间隔、历史容量）
 * - AppConfig：应用全局配置
 */
package aichat.config

/**
 * AI 模型配置结构体
 *
 * 使用 struct（值类型），因为配置信息一旦创建后不可变，
 * 适合用值语义来传递和复制。
 */
public struct ModelConfig {
    public let displayName: String       // 模型显示名称（如 "Kimi"）
    public let apiUrl: String            // API 接口地址
    public let defaultModelId: String    // 默认模型标识符（如 "moonshot-v1-8k"）

    public init(displayName: String, apiUrl: String, defaultModelId: String) {
        this.displayName = displayName
        this.apiUrl = apiUrl
        this.defaultModelId = defaultModelId
    }
}

/**
 * 流式输出设置结构体
 *
 * 控制流式显示的行为参数：
 * - displayIntervalMs：无数据时的轮询休眠间隔（毫秒），过短浪费 CPU，过长影响体验
 * - maxHistorySize：对话历史最大消息数，防止内存无限增长
 */
public struct StreamSettings {
    public let displayIntervalMs: Int64
    public let maxHistorySize: Int64

    public init(displayIntervalMs!: Int64 = 30, maxHistorySize!: Int64 = 20) {
        this.displayIntervalMs = displayIntervalMs
        this.maxHistorySize = maxHistorySize
    }
}

/**
 * 应用全局配置类
 *
 * 使用 class（引用类型），因为全局配置需要在多个模块间共享引用。
 */
public class AppConfig {
    public let streamSettings: StreamSettings  // 流式输出配置

    public init(streamSettings!: StreamSettings = StreamSettings()) {
        this.streamSettings = streamSettings
    }
}
