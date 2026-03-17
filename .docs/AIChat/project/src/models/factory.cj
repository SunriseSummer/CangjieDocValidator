/**
 * ModelFactory —— 模型工厂
 *
 * 使用工厂模式根据模型名称创建对应的 BaseChatModel 实例。
 * 通过 match 表达式实现模型分发，支持：
 * - kimi → KimiModel
 * - glm → GlmModel
 * - minimax → MinimaxModel
 *
 * 返回 Option 类型，未知模型名返回 None。
 */
package aichat.models

import aichat.config.ConfigManager

public class ModelFactory {
    /**
     * 根据模型名称创建模型实例
     *
     * @param modelName     模型名称（kimi/glm/minimax）
     * @param configManager 配置管理器
     * @return 成功返回 Some(model)，未知模型返回 None
     */
    public static func createModel(modelName: String, configManager: ConfigManager): ?BaseChatModel {
        match (modelName) {
            case "kimi" => Some(KimiModel(configManager))
            case "glm" => Some(GlmModel(configManager))
            case "minimax" => Some(MinimaxModel(configManager))
            case _ => None
        }
    }
}
