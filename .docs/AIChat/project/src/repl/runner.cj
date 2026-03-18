/**
 * ReplRunner —— REPL 交互循环
 *
 * 用户直接面对的交互界面，负责：
 * - 读取用户输入
 * - 识别和分发斜杠命令（/help、/clear、/switch、/status、/exit）
 * - 动态检查并提示输入 API Key
 * - 协调聊天流程：使用 ModelFactory 创建模型，通过 CharQueue 和 StreamEngine 实现流式输出
 *
 * 核心设计：
 * - 网络线程（Producer）：调用 AI 模型的 chat() 方法，将响应写入 CharQueue
 * - 显示线程（Consumer）：StreamEngine 从 CharQueue 逐字符取出并打印
 * - 两个线程通过 CharQueue 和 Mutex 协同工作
 */
package aichat.repl

import std.sync.*
import std.collection.ArrayList
import aichat.config.ConfigManager
import aichat.models.{BaseChatModel, ChatMessage, ChatRequest, ModelFactory}
import aichat.stream.{CharQueue, StreamEngine}

public class ReplRunner {
    private let configManager: ConfigManager             // 配置管理器
    private let messages: ArrayList<ChatMessage> = ArrayList<ChatMessage>()  // 对话历史
    private var currentModel: String                     // 当前选中的模型名
    private let mtx: Mutex = Mutex()                     // 线程同步锁

    public init() {
        this.configManager = ConfigManager()
        this.currentModel = configManager.getCurrentModel()
    }

    /**
     * 启动 REPL
     *
     * 支持两种模式：
     * - 无参数：进入交互模式
     * - 有参数：将参数拼接为消息直接发送（单次调用模式）
     */
    public func run(args: Array<String>): Unit {
        if (args.size == 0) {
            runInteractive()
        } else {
            // 单次调用模式：将所有参数拼接为一条消息
            let input = String.join(args, delimiter: " ")
            processMessage(input)
        }
    }

    /**
     * 通过环境变量覆盖 API Key（优先级高于 config.json）
     *
     * 直接设置内存中的配置，不写入文件，不打印提示。
     */
    public func overrideApiKey(modelName: String, apiKey: String): Unit {
        if (let Some(modelConfig) <- configManager.config.models.get(modelName)) {
            modelConfig.apiKey = apiKey
        }
    }

    /**
     * 覆盖指定模型的 API 基础 URL（用于测试或自定义部署）
     */
    public func overrideBaseUrl(modelName: String, url: String): Unit {
        configManager.setBaseUrl(modelName, url)
    }

    /**
     * 交互模式主循环
     *
     * 循环读取用户输入，根据是否以 "/" 开头分发到命令处理或聊天流程。
     */
    private func runInteractive(): Unit {
        println("╔══════════════════════════════════════╗")
        println("║       AIChatPro — 仓颉版              ║")
        println("║  输入 /help 查看可用命令               ║")
        println("╚══════════════════════════════════════╝")
        println("当前模型: ${currentModel}")
        println("")

        while (true) {
            print("你> ")
            let input = readln().trimAscii()

            if (input.isEmpty()) {
                continue
            }

            if (input.startsWith("/")) {
                if (!handleCommand(input)) {
                    break
                }
                continue
            }

            // 发送消息前检查 API Key
            if (!checkAndPromptApiKey()) {
                continue
            }

            processMessage(input)
        }
    }

    /**
     * 处理斜杠命令
     *
     * 支持的命令：
     * - /help：显示帮助信息
     * - /switch <model>：切换模型（kimi/glm/minimax）
     * - /clear：清空对话历史
     * - /status：显示当前状态
     * - /exit：退出程序
     *
     * 返回 true 表示继续循环，false 表示退出程序。
     */
    private func handleCommand(cmd: String): Bool {
        let parts = cmd.split(" ")
        let command = parts[0]

        match (command) {
            case "/help" =>
                println("可用命令:")
                println("  /switch <model>  切换模型 (kimi/glm/minimax)")
                println("  /clear           清空对话历史")
                println("  /status          显示当前状态")
                println("  /exit            退出程序")
                println("  /help            显示此帮助")
            case "/switch" =>
                if (parts.size < 2) {
                    println("用法: /switch <model>")
                    println("可选模型: kimi, glm, minimax")
                } else {
                    let newModel = parts[1]
                    if (configManager.setCurrentModel(newModel)) {
                        currentModel = newModel
                        println("[系统] 已切换到模型: ${currentModel}")
                    } else {
                        println("[系统] 未知模型: ${newModel}")
                        println("可选模型: kimi, glm, minimax")
                    }
                }
            case "/clear" =>
                messages.clear()
                println("[系统] 对话历史已清空")
            case "/status" =>
                println("当前模型: ${currentModel}")
                println("对话历史: ${messages.size} 条消息")
                let apiKey = configManager.getApiKey(currentModel)
                let keyStatus = if (apiKey.isEmpty()) { "未配置" } else { "已配置" }
                println("API Key: ${keyStatus}")
            case "/exit" | "/quit" =>
                println("\n再见！感谢使用 AIChatPro。")
                return false
            case _ =>
                println("[系统] 未知命令: ${command}，输入 /help 查看帮助")
        }

        return true
    }

    /**
     * 检查当前模型的 API Key 是否已配置
     *
     * 如果未配置，提示用户输入并自动保存到 config.json。
     * 返回 true 表示 API Key 已就绪，false 表示用户取消输入。
     */
    private func checkAndPromptApiKey(): Bool {
        let apiKey = configManager.getApiKey(currentModel)
        if (apiKey.isEmpty()) {
            println("[系统] ${currentModel} 的 API Key 未配置")
            print("请输入 ${currentModel} API Key: ")
            let key = readln().trimAscii()

            if (key.isEmpty()) {
                println("[系统] API Key 不能为空")
                return false
            }

            // 保存 API Key 到配置文件
            configManager.saveApiKey(currentModel, key)
        }
        return true
    }

    /**
     * 发送用户消息并显示 AI 回复
     *
     * 流程：
     * 1. 将用户消息加入对话历史
     * 2. 使用 ModelFactory 创建模型实例
     * 3. 构建聊天请求（包含模型标识符和消息列表）
     * 4. 在后台线程中发送请求，主线程运行 StreamEngine 显示输出
     * 5. 等待完成后，将 AI 回复记录到对话历史
     */
    private func processMessage(input: String): Unit {
        // 将用户输入加入对话历史
        messages.add(ChatMessage("user", input))

        // 使用工厂模式创建模型实例
        let modelOpt = ModelFactory.createModel(currentModel, configManager)
        match (modelOpt) {
            case Some(model) =>
                let queue = CharQueue()
                let settings = configManager.config.streamSettings

                // 构建聊天请求，使用模型标识符映射
                let request = ChatRequest(getModelName(currentModel), messages)

                print("\nAI> ")

                // 在后台线程发送网络请求（生产者）
                let producer = spawn {
                    model.chat(request, queue, mtx)
                    queue.setFinished()
                }

                // 在当前线程运行流式显示引擎（消费者）
                let engine = StreamEngine(queue, settings, mtx)
                engine.run()

                // 等待网络线程完成
                producer.get()

                // 记录 AI 回复到对话历史
                let assistantContent = queue.getCollectedContent()
                messages.add(ChatMessage("assistant", assistantContent))

                println("")
            case None =>
                eprintln("[系统] 错误：无法创建模型实例")
        }
    }

    /**
     * 将模型类型名映射为 API 中的模型标识符
     *
     * 不同 AI 提供商使用不同的模型 ID：
     * - kimi → moonshot-v1-8k
     * - glm → glm-4-flash
     * - minimax → abab6.5s-chat
     */
    private func getModelName(modelType: String): String {
        match (modelType) {
            case "kimi" => "moonshot-v1-8k"
            case "glm" => "glm-4-flash"
            case "minimax" => "abab6.5s-chat"
            case _ => modelType
        }
    }
}

