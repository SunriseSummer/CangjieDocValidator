/**
 * ReplRunner —— REPL 交互循环
 *
 * 用户直接面对的交互界面，负责：
 * - 读取用户输入
 * - 识别和分发斜杠命令（/help、/clear、/exit）
 * - 协调聊天流程：启动网络线程和显示线程，实现边接收边输出
 *
 * 核心设计：
 * - 网络线程（Producer）：调用 AI 模型的 chat() 方法，将响应写入 CharQueue
 * - 显示线程（Consumer）：StreamEngine 从 CharQueue 逐字符取出并打印
 * - 两个线程通过 CharQueue 和 Mutex 协同工作
 */
package aichat.repl

import std.sync.*
import aichat.config.ConfigManager
import aichat.models.{BaseChatModel, ChatRequest, ConversationHistory}
import aichat.stream.{CharQueue, StreamEngine}

public class ReplRunner {
    private let configManager: ConfigManager      // 配置管理器
    private var currentModel: BaseChatModel       // 当前使用的 AI 模型
    private let history: ConversationHistory       // 对话历史管理器
    private let mtx: Mutex = Mutex()               // 线程同步锁

    public init(configManager: ConfigManager, model: BaseChatModel) {
        this.configManager = configManager
        this.currentModel = model
        this.history = ConversationHistory(maxSize: 20)
    }

    /**
     * 启动 REPL 主循环
     *
     * 循环读取用户输入，根据是否以 "/" 开头分发到命令处理或聊天流程。
     * 当用户输入 /exit 或 /quit 时退出循环。
     */
    public func run(): Unit {
        printBanner()

        while (true) {
            print("\n你> ")
            let line = readln()
            let input = line.trimAscii()
            if (input.isEmpty()) { continue }

            if (input.startsWith("/")) {
                if (!handleCommand(input)) { break }  // /exit 返回 false
            } else {
                sendMessage(input)
            }
        }
        println("\n再见！感谢使用 AIChatPro。")
    }

    /** 打印启动横幅 */
    private func printBanner(): Unit {
        println("╔══════════════════════════════════════╗")
        println("║       AIChatPro — 仓颉版              ║")
        println("║  输入 /help 查看可用命令               ║")
        println("╚══════════════════════════════════════╝")
        println("当前模型: ${currentModel.getName()} (${currentModel.getModelId()})")
    }

    /**
     * 处理斜杠命令
     *
     * 返回 true 表示继续循环，false 表示退出程序。
     */
    private func handleCommand(cmd: String): Bool {
        if (cmd == "/exit" || cmd == "/quit") {
            return false
        } else if (cmd == "/help") {
            println("可用命令:")
            println("  /help     显示帮助")
            println("  /clear    清空对话历史")
            println("  /exit     退出程序")
        } else if (cmd == "/clear") {
            history.clear()
            println("[系统] 对话历史已清空")
        } else {
            println("[系统] 未知命令: ${cmd}，输入 /help 查看帮助")
        }
        return true
    }

    /**
     * 发送用户消息并显示 AI 回复
     *
     * 流程：
     * 1. 将用户消息加入对话历史
     * 2. 构建聊天请求
     * 3. 创建字符队列和流式显示引擎
     * 4. 同时启动网络线程（发送请求）和显示线程（打印输出）
     * 5. 等待两个线程都完成
     * 6. 将 AI 的完整回复记录到对话历史
     */
    private func sendMessage(userInput: String): Unit {
        // 将用户输入加入对话历史
        history.add("user", userInput)

        // 构建聊天请求（包含完整对话历史）
        let messages = history.toArrayList()
        let request = ChatRequest(
            currentModel.getModelId(),
            messages
        )

        // 创建字符队列和流式显示引擎
        let queue = CharQueue()
        let engine = StreamEngine(queue, mtx)

        print("\nAI> ")
        // 启动显示线程（消费者）
        let displayFuture = engine.startDisplay()

        // 启动网络线程（生产者）
        let modelRef = currentModel
        let chatFuture = spawn {
            modelRef.chat(request, queue, mtx)
        }

        // 等待网络请求和显示都完成
        chatFuture.get()
        displayFuture.get()

        // 将 AI 回复记录到对话历史
        let response = queue.getCollected()
        if (!response.isEmpty()) {
            history.add("assistant", response)
        }
    }
}
