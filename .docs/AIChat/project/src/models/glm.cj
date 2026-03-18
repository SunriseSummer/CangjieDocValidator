/**
 * GlmModel —— GLM（智谱 AI）模型实现
 *
 * 实现 BaseChatModel 接口，对接智谱 AI 的 GLM API。
 * GLM API 遵循 OpenAI 兼容格式，与 KimiModel 的请求/响应结构基本一致：
 * - 使用 Bearer Token 认证
 * - 支持 SSE 流式响应
 * - JSON 请求体包含 model、stream、messages 字段
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

public class GlmModel <: BaseChatModel {
    private let configManager: ConfigManager  // 配置管理器引用
    private let client: Client                // HTTP 客户端

    /**
     * 构造 GlmModel
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
        return "glm"
    }

    /**
     * 发送聊天请求到 GLM API
     *
     * GLM 的 API 格式与 OpenAI 兼容，
     * 认证方式为 Bearer Token。
     */
    public func chat(request: ChatRequest, queue: CharQueue, mtx: Mutex): Unit {
        let apiKey = configManager.getApiKey("glm")
        if (apiKey.isEmpty()) {
            synchronized(mtx) {
                queue.addMany("[系统] 错误：GLM API Key 未配置")
            }
            return
        }

        let baseUrl = configManager.getBaseUrl("glm")
        let url = "${baseUrl}/chat/completions"

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
