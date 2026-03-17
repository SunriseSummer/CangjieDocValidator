/**
 * 配置类型定义
 *
 * 定义 AIChatPro 项目中所有配置相关的数据类型：
 * - ModelConfig：AI 模型配置（API Key、基础 URL、GroupId）
 * - StreamSettings：流式输出设置（自适应间隔控制）
 * - AppConfig：应用全局配置（默认模型、模型列表、流式设置）
 *
 * 参考 Cangjie-Examples/AIChatPro 项目实现，
 * 所有配置类使用 class（引用类型）以支持运行时修改并序列化到 JSON。
 */
package aichat.config

import std.collection.HashMap

/**
 * AI 模型配置类
 *
 * 存储单个模型的连接信息，包括：
 * - apiKey：模型的 API 密钥
 * - baseUrl：API 基础地址（如 https://api.moonshot.cn/v1）
 * - groupId：部分模型（如 Minimax）需要的分组标识
 */
public class ModelConfig {
    public var apiKey: String = ""
    public var baseUrl: String = ""
    public var groupId: String = ""

    public init() {}

    public init(apiKey: String, baseUrl: String, groupId!: String = "") {
        this.apiKey = apiKey
        this.baseUrl = baseUrl
        this.groupId = groupId
    }
}

/**
 * 流式输出设置类
 *
 * 控制流式显示的自适应行为：
 * - baseIntervalMs：基础轮询间隔（毫秒），队列较空时使用
 * - burstThreshold：突发阈值，队列字符超过此值时切换到快速模式
 * - catchupIntervalMs：快速模式间隔（毫秒），用于追赶大量积压字符
 */
public class StreamSettings {
    public var baseIntervalMs: Int64 = 20
    public var burstThreshold: Int64 = 50
    public var catchupIntervalMs: Int64 = 5

    public init() {}

    public init(baseIntervalMs: Int64, burstThreshold: Int64, catchupIntervalMs: Int64) {
        this.baseIntervalMs = baseIntervalMs
        this.burstThreshold = burstThreshold
        this.catchupIntervalMs = catchupIntervalMs
    }
}

/**
 * 应用全局配置类
 *
 * 汇总所有配置项，初始化时预置三个国产大模型：
 * - kimi（月之暗面 Moonshot AI）
 * - glm（智谱 AI）
 * - minimax（MiniMax）
 *
 * 配置信息可通过 ConfigManager 从 JSON 文件加载或保存。
 */
public class AppConfig {
    public var defaultModel: String = "kimi"                                        // 默认使用的模型
    public var models: HashMap<String, ModelConfig> = HashMap<String, ModelConfig>() // 模型名 -> 配置
    public var streamSettings: StreamSettings = StreamSettings()                    // 流式输出设置

    public init() {
        // 预置支持的模型及其默认 API 地址
        models.add("kimi", ModelConfig("", "https://api.moonshot.cn/v1"))
        models.add("glm", ModelConfig("", "https://open.bigmodel.cn/api/paas/v4"))
        models.add("minimax", ModelConfig("", "https://api.minimax.chat/v1", groupId: ""))
    }
}

