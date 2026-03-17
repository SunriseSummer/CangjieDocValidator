/**
 * 配置管理器
 *
 * ConfigManager 集中管理所有 AI 模型的配置信息：
 * - API Key 管理：设置、查询各模型的密钥
 * - 模型注册：预置支持的模型（Kimi、GLM、Minimax）的 URL 和标识
 * - 模型切换：在多个模型之间切换，并进行合法性校验
 * - 配置验证：启动时检查当前模型是否已配置 API Key（快速失败策略）
 */
package aichat.config

import std.collection.HashMap

/**
 * 配置错误异常
 *
 * 当配置不合法时抛出，如空 API Key、不支持的模型名称等。
 */
public class ConfigError <: Exception {
    public init(msg: String) { super(msg) }
}

/**
 * 配置管理器类
 *
 * 使用 HashMap 存储各模型的 API Key、基础 URL 和模型标识符，
 * 通过 currentModel 跟踪当前激活的模型。
 */
public class ConfigManager {
    private let apiKeys: HashMap<String, String> = HashMap<String, String>()    // 模型名 -> API Key
    private let baseUrls: HashMap<String, String> = HashMap<String, String>()   // 模型名 -> API 基础 URL
    private let modelIds: HashMap<String, String> = HashMap<String, String>()   // 模型名 -> 模型标识符
    private var currentModel: String = "kimi"  // 当前选中的模型，默认 Kimi

    /**
     * 初始化：预置支持的模型列表
     *
     * 目前支持三个国产大模型：
     * - kimi（月之暗面 Moonshot AI）
     * - glm（智谱 AI）
     * - minimax（MiniMax）
     */
    public init() {
        baseUrls.add("kimi", "https://api.moonshot.cn/v1")
        baseUrls.add("glm", "https://open.bigmodel.cn/api/paas/v4")
        baseUrls.add("minimax", "https://api.minimax.chat/v1")

        modelIds.add("kimi", "moonshot-v1-8k")
        modelIds.add("glm", "glm-4")
        modelIds.add("minimax", "abab6.5-chat")
    }

    /** 设置指定模型的 API Key，空值将抛出 ConfigError */
    public func setApiKey(model: String, key: String): Unit {
        if (key.isEmpty()) {
            throw ConfigError("API Key 不能为空 (model: ${model})")
        }
        apiKeys.add(model, key)
    }

    /** 获取指定模型的 API Key，未配置则返回空字符串 */
    public func getApiKey(model: String): String {
        apiKeys.get(model) ?? ""
    }

    /** 覆盖指定模型的 API 基础 URL（用于测试或自定义部署） */
    public func setBaseUrl(model: String, url: String): Unit {
        baseUrls.add(model, url)
    }

    /** 获取指定模型的 API 基础 URL */
    public func getBaseUrl(model: String): String {
        baseUrls.get(model) ?? ""
    }

    /** 获取指定模型的模型标识符 */
    public func getModelId(model: String): String {
        modelIds.get(model) ?? model
    }

    /** 获取当前选中的模型名称 */
    public func getCurrentModel(): String { currentModel }

    /**
     * 切换当前模型
     *
     * 仅允许切换到预置的合法模型，否则抛出 ConfigError。
     */
    public func setCurrentModel(name: String): Unit {
        let valid = ["kimi", "glm", "minimax"]
        var found = false
        for (m in valid) {
            if (m == name) { found = true; break }
        }
        if (!found) {
            throw ConfigError("不支持的模型: '${name}'，可选: kimi, glm, minimax")
        }
        currentModel = name
    }

    /** 检查指定模型是否已配置 API Key */
    public func hasApiKey(model: String): Bool {
        let key = apiKeys.get(model) ?? ""
        return !key.isEmpty()
    }

    /**
     * 验证当前配置是否可用
     *
     * 在启动时调用，确保当前模型的 API Key 已配置。
     * 采用"快速失败"策略，尽早暴露配置问题。
     */
    public func validate(): Unit {
        if (!hasApiKey(currentModel)) {
            throw ConfigError("当前模型 '${currentModel}' 的 API Key 未配置，请设置环境变量")
        }
    }
}
