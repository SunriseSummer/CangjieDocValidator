/**
 * MinimaxModel —— Minimax 模型实现
 *
 * 实现 BaseChatModel 接口，对接 Minimax 的聊天 API。
 * Minimax 与其他模型的主要差异：
 * - 需要额外的 GroupId 参数，通过 URL 查询参数传递
 * - URL 格式：{base_url}/chat/completions?GroupId={group_id}
 * - 其余请求/响应格式与 OpenAI 兼容
 */
package aichat.models

import stdx.net.http.*
import stdx.net.tls.*
import stdx.encoding.json.stream.*
import std.io.{ByteBuffer, readToEnd}
import std.sync.Mutex
import aichat.config.ConfigManager
import aichat.stream.CharQueue
import aichat.utils.SseParser

public class MinimaxModel <: BaseChatModel {
    private let configManager: ConfigManager  // 配置管理器引用
    private let client: Client                // HTTP 客户端

    /**
     * 构造 MinimaxModel
     *
     * 创建支持 TLS 的 HTTP 客户端。
     */
    public init(configManager: ConfigManager) {
        this.configManager = configManager
        var tlsConfig = TlsClientConfig()
        tlsConfig.verifyMode = TrustAll
        this.client = ClientBuilder()
            .tlsConfig(tlsConfig)
            .build()
    }

    /** 返回模型名称标识 */
    public func getName(): String {
        return "minimax"
    }

    /**
     * 发送聊天请求到 Minimax API
     *
     * Minimax 特殊之处：
     * 1. 需要检查 GroupId 是否已配置
     * 2. GroupId 通过 URL 查询参数传递
     */
    public func chat(request: ChatRequest, queue: CharQueue, mtx: Mutex): Unit {
        let apiKey = configManager.getApiKey("minimax")
        if (apiKey.isEmpty()) {
            synchronized(mtx) {
                queue.addMany("[系统] 错误：Minimax API Key 未配置")
            }
            return
        }

        // Minimax 需要 GroupId
        let groupId = configManager.getGroupId("minimax")
        if (groupId.isEmpty()) {
            synchronized(mtx) {
                queue.addMany("[系统] 错误：Minimax Group ID 未配置")
            }
            return
        }

        let baseUrl = configManager.getBaseUrl("minimax")
        let url = "${baseUrl}/chat/completions?GroupId=${groupId}"

        try {
            let reqBody = buildRequestBody(request)

            let req = HttpRequestBuilder()
                .post()
                .url(url)
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer ${apiKey}")
                .body(reqBody)
                .build()

            let resp = client.send(req)

            if (resp.status != 200) {
                synchronized(mtx) {
                    queue.addMany("[系统] HTTP 错误: ${resp.status}")
                }
                return
            }

            // 解析 SSE 流式响应
            SseParser.parseStream(resp.body) { jsonStr =>
                let delta = SseParser.extractDelta(jsonStr)
                if (!delta.isEmpty()) {
                    synchronized(mtx) { queue.addMany(delta) }
                }
            }
        } catch (e: Exception) {
            synchronized(mtx) {
                queue.addMany("\n[系统] 网络错误: ${e}")
            }
        }
    }

    /** 构建请求体 JSON */
    private func buildRequestBody(request: ChatRequest): String {
        let buf = ByteBuffer()
        let writer = JsonWriter(buf)

        writer.startObject()
        writer.writeName("model").writeValue(request.model)
        writer.writeName("stream").writeValue(request.stream)
        writer.writeName("messages")

        writer.startArray()
        for (msg in request.messages) {
            writer.startObject()
            writer.writeName("role").writeValue(msg.role)
            writer.writeName("content").writeValue(msg.content)
            writer.endObject()
        }
        writer.endArray()

        writer.endObject()
        writer.flush()

        return String.fromUtf8(readToEnd(buf))
    }
}
