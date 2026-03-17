/**
 * AIChatPro 主入口
 *
 * 简洁的入口点：创建 ReplRunner 并启动。
 * 所有配置（API Key、模型选择等）由 ConfigManager 从 config.json 自动加载。
 *
 * 使用方式：
 *   cjpm run                    # 交互模式
 *   cjpm run -- 你好             # 单次调用模式
 *
 * 环境变量（可选，优先级高于 config.json）：
 *   KIMI_API_KEY   Kimi API 密钥
 *   GLM_API_KEY    GLM API 密钥
 *   MOCK_API_URL   自定义 API URL（测试用）
 */
package aichat

import std.env.*
import aichat.repl.ReplRunner

main(args: Array<String>): Int64 {
    let runner = ReplRunner()

    // 支持通过环境变量覆盖 API Key（优先级高于 config.json）
    let kimiKey = getVariable("KIMI_API_KEY") ?? ""
    if (!kimiKey.isEmpty()) {
        runner.overrideApiKey("kimi", kimiKey)
    }
    let glmKey = getVariable("GLM_API_KEY") ?? ""
    if (!glmKey.isEmpty()) {
        runner.overrideApiKey("glm", glmKey)
    }

    // 支持自定义 API URL（用于模拟测试）
    let mockUrl = getVariable("MOCK_API_URL") ?? ""
    if (!mockUrl.isEmpty()) {
        runner.overrideBaseUrl("kimi", mockUrl)
        runner.overrideBaseUrl("glm", mockUrl)
        runner.overrideBaseUrl("minimax", mockUrl)
        println("[系统] 使用自定义 API URL: ${mockUrl}")
    }

    runner.run(args)
    0
}

