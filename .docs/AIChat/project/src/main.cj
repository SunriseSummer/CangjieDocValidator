/**
 * AIChatPro 主入口
 *
 * 程序启动的三段式流程：
 * 1. 配置阶段：从环境变量加载 API Key
 * 2. 组装阶段：创建 ConfigManager、模型实例
 * 3. 运行阶段：启动 REPL 交互循环
 *
 * 环境变量：
 * - KIMI_API_KEY：Kimi（月之暗面）的 API 密钥
 * - GLM_API_KEY：GLM（智谱 AI）的 API 密钥
 *
 * 使用方式：
 *   export KIMI_API_KEY="sk-xxxx"
 *   cjpm run
 */
package aichat

import std.env.*
import aichat.config.{ConfigManager, ConfigError}
import aichat.models.KimiModel
import aichat.repl.ReplRunner

/**
 * 安全获取环境变量，不存在时返回空字符串
 *
 * 使用 std.env.getVariable() 读取环境变量，
 * 该函数返回 ?String（Option 类型），用 ?? 运算符提供默认值。
 */
func getEnvOrEmpty(key: String): String {
    getVariable(key) ?? ""
}

main(): Unit {
    let configManager = ConfigManager()

    // 从环境变量加载 Kimi API Key
    let kimiKey = getEnvOrEmpty("KIMI_API_KEY")
    if (!kimiKey.isEmpty()) {
        try {
            configManager.setApiKey("kimi", kimiKey)
        } catch (e: ConfigError) {
            println("配置警告: ${e.message}")
        }
    }

    // 从环境变量加载 GLM API Key
    let glmKey = getEnvOrEmpty("GLM_API_KEY")
    if (!glmKey.isEmpty()) {
        try {
            configManager.setApiKey("glm", glmKey)
        } catch (e: ConfigError) {
            println("配置警告: ${e.message}")
        }
    }

    // 支持自定义 API URL（用于模拟测试）
    // 设置 MOCK_API_URL 环境变量可将请求指向本地模拟服务器
    let mockUrl = getEnvOrEmpty("MOCK_API_URL")
    if (!mockUrl.isEmpty()) {
        configManager.setBaseUrl("kimi", mockUrl)
        println("[系统] 使用自定义 API URL: ${mockUrl}")
    }

    // 创建 Kimi 模型实例并启动 REPL
    let model = KimiModel(configManager)
    let repl = ReplRunner(configManager, model)
    repl.run()
}
