/**
 * 配置管理器
 *
 * ConfigManager 负责：
 * - 从 JSON 配置文件（config.json）加载配置
 * - 将配置保存回 JSON 文件
 * - 管理各模型的 API Key、基础 URL、GroupId
 * - 支持运行时动态保存 API Key
 *
 * 配置文件位于可执行文件所在目录，格式示例：
 * {
 *   "default_model": "kimi",
 *   "models": {
 *     "kimi": { "api_key": "sk-xxx", "base_url": "https://api.moonshot.cn/v1" },
 *     "glm": { "api_key": "", "base_url": "https://open.bigmodel.cn/api/paas/v4" },
 *     "minimax": { "api_key": "", "base_url": "https://api.minimax.chat/v1", "group_id": "" }
 *   },
 *   "stream_settings": { "base_interval_ms": 20, "burst_threshold": 50, "catchup_interval_ms": 5 }
 * }
 */
package aichat.config

import stdx.encoding.json.*
import std.fs.*
import std.env.*

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
 * 启动时自动从 config.json 加载配置，若文件不存在则创建默认配置。
 * 支持指定配置文件路径（用于测试）。
 */
public class ConfigManager {
    private let configPath: Path         // 配置文件路径
    public var config: AppConfig         // 全局配置对象

    /**
     * 默认构造：配置文件位于可执行文件所在目录的 config.json
     */
    public init() {
        let exePath = getExecutablePath()
        let exeDir = exePath.parent
        this.configPath = exeDir.join("config.json")
        this.config = AppConfig()
        loadOrCreate()
    }

    /**
     * 指定配置文件路径（用于测试或自定义部署）
     */
    public init(configPath: Path) {
        this.configPath = configPath
        this.config = AppConfig()
        loadOrCreate()
    }

    /**
     * 加载或创建配置文件
     *
     * 若 config.json 存在则加载，否则写入默认配置。
     */
    private func loadOrCreate(): Unit {
        if (exists(configPath)) {
            loadFromFile()
        } else {
            saveDefaultConfig()
        }
    }

    /**
     * 从 JSON 文件加载配置
     *
     * 解析各字段：default_model、models（含 api_key/base_url/group_id）、stream_settings。
     * 加载失败时回退到默认配置。
     */
    private func loadFromFile(): Unit {
        try {
            let data = File.readFrom(configPath)
            let jsonStr = String.fromUtf8(data)
            let jv = JsonValue.fromStr(jsonStr)
            let obj = jv.asObject()

            // 读取默认模型
            if (let Some(defaultModel) <- obj.get("default_model")) {
                config.defaultModel = defaultModel.asString().getValue()
            }

            // 读取各模型配置
            if (let Some(modelsObj) <- obj.get("models")) {
                let modelsMap = modelsObj.asObject().getFields()
                config.models.clear()

                for ((key, modelValue) in modelsMap) {
                    let modelObj = modelValue.asObject()
                    let modelConfig = ModelConfig()

                    if (let Some(apiKeyValue) <- modelObj.get("api_key")) {
                        modelConfig.apiKey = apiKeyValue.asString().getValue()
                    }
                    if (let Some(baseUrlValue) <- modelObj.get("base_url")) {
                        modelConfig.baseUrl = baseUrlValue.asString().getValue()
                    }
                    if (let Some(groupIdValue) <- modelObj.get("group_id")) {
                        modelConfig.groupId = groupIdValue.asString().getValue()
                    }

                    config.models.add(key, modelConfig)
                }
            }

            // 读取流式设置
            if (let Some(settingsObj) <- obj.get("stream_settings")) {
                let settingsMap = settingsObj.asObject()

                if (let Some(baseInterval) <- settingsMap.get("base_interval_ms")) {
                    config.streamSettings.baseIntervalMs = baseInterval.asInt().getValue()
                }
                if (let Some(burstThreshold) <- settingsMap.get("burst_threshold")) {
                    config.streamSettings.burstThreshold = burstThreshold.asInt().getValue()
                }
                if (let Some(catchupInterval) <- settingsMap.get("catchup_interval_ms")) {
                    config.streamSettings.catchupIntervalMs = catchupInterval.asInt().getValue()
                }
            }
        } catch (e: Exception) {
            eprintln("[系统] 加载配置失败: ${e}，使用默认配置")
            saveDefaultConfig()
        }
    }

    /** 写入默认配置到文件 */
    private func saveDefaultConfig(): Unit {
        saveToFile()
    }

    /**
     * 将当前配置保存到 JSON 文件
     *
     * 序列化 AppConfig 为格式化 JSON 并写入 config.json。
     */
    public func saveToFile(): Unit {
        try {
            let root = JsonObject()
            root.put("default_model", JsonString(config.defaultModel))

            // 序列化各模型配置
            let modelsObj = JsonObject()
            for ((name, modelConfig) in config.models) {
                let modelObj = JsonObject()
                modelObj.put("api_key", JsonString(modelConfig.apiKey))
                modelObj.put("base_url", JsonString(modelConfig.baseUrl))
                if (!modelConfig.groupId.isEmpty()) {
                    modelObj.put("group_id", JsonString(modelConfig.groupId))
                }
                modelsObj.put(name, modelObj)
            }
            root.put("models", modelsObj)

            // 序列化流式设置
            let settingsObj = JsonObject()
            settingsObj.put("base_interval_ms", JsonInt(config.streamSettings.baseIntervalMs))
            settingsObj.put("burst_threshold", JsonInt(config.streamSettings.burstThreshold))
            settingsObj.put("catchup_interval_ms", JsonInt(config.streamSettings.catchupIntervalMs))
            root.put("stream_settings", settingsObj)

            let jsonStr = root.toJsonString()
            File.writeTo(configPath, jsonStr.toArray())
        } catch (e: Exception) {
            eprintln("[系统] 保存配置失败: ${e}")
        }
    }

    /**
     * 保存 API Key 并持久化到配置文件
     *
     * 用户在 REPL 中输入 API Key 时调用，自动写回 config.json。
     */
    public func saveApiKey(modelName: String, apiKey: String): Unit {
        if (let Some(modelConfig) <- config.models.get(modelName)) {
            modelConfig.apiKey = apiKey
            saveToFile()
            println("[系统] ${modelName} 的 API Key 已保存到 config.json")
        } else {
            eprintln("[系统] 未找到模型: ${modelName}")
        }
    }

    /** 获取当前选中的模型名称 */
    public func getCurrentModel(): String {
        return config.defaultModel
    }

    /**
     * 切换当前模型
     *
     * 仅允许切换到已注册的模型，返回 true 表示成功。
     */
    public func setCurrentModel(modelName: String): Bool {
        if (config.models.contains(modelName)) {
            config.defaultModel = modelName
            return true
        }
        return false
    }

    /** 获取指定模型的 API Key，未配置则返回空字符串 */
    public func getApiKey(modelName: String): String {
        if (let Some(modelConfig) <- config.models.get(modelName)) {
            return modelConfig.apiKey
        }
        return ""
    }

    /** 获取指定模型的 API 基础 URL */
    public func getBaseUrl(modelName: String): String {
        if (let Some(modelConfig) <- config.models.get(modelName)) {
            return modelConfig.baseUrl
        }
        return ""
    }

    /** 获取指定模型的 GroupId（Minimax 等模型需要） */
    public func getGroupId(modelName: String): String {
        if (let Some(modelConfig) <- config.models.get(modelName)) {
            return modelConfig.groupId
        }
        return ""
    }

    /** 覆盖指定模型的 API 基础 URL（用于测试或自定义部署） */
    public func setBaseUrl(modelName: String, url: String): Unit {
        if (let Some(modelConfig) <- config.models.get(modelName)) {
            modelConfig.baseUrl = url
        }
    }
}

/**
 * 获取当前可执行文件的路径
 *
 * 使用 std.env.getCommand() 获取启动命令，
 * 配置文件 config.json 将存放在可执行文件同目录下。
 */
func getExecutablePath(): Path {
    let cmd = getCommand()
    if (!cmd.isEmpty()) {
        return Path(cmd)
    }
    return Path(".")
}

