/**
 * KimiModel —— Kimi（月之暗面）模型实现
 *
 * 实现 BaseChatModel 接口，对接 Moonshot AI 的 Kimi API。
 * 核心流程：
 * 1. 使用 JsonWriter 构建请求体 JSON
 * 2. 通过 HTTPS 发送 POST 请求到 Kimi API
 * 3. 使用 SseParser 解析流式 SSE 响应
 * 4. 将解析出的文本片段写入 CharQueue 供显示线程消费
 *
 * 错误处理覆盖三种场景：
 * - API Key 未配置
 * - HTTP 状态码异常
 * - 网络连接异常
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

public class KimiModel <: BaseChatModel {
    private let configManager: ConfigManager  // 配置管理器引用
    private let client: Client                // HTTP 客户端（可复用，内含连接池）

    /**
     * 构造 KimiModel
     *
     * 初始化时创建 HTTP 客户端，配置 TLS 为 TrustAll 模式。
     * 注意：TrustAll 仅用于开发环境，生产环境应使用 Default 模式。
     */
    public init(configManager: ConfigManager) {
        this.configManager = configManager
        var tlsConfig = TlsClientConfig()
        tlsConfig.verifyMode = TrustAll  // 开发环境跳过证书验证
        this.client = ClientBuilder()
            .tlsConfig(tlsConfig)
            .build()
    }

    /** 返回模型名称标识 */
    public func getName(): String {
        return "kimi"
    }

    /**
     * 发送聊天请求并将流式响应写入字符队列
     *
     * 流程：
     * 1. 检查 API Key 是否已配置
     * 2. 构建请求 JSON 并发送 HTTP POST
     * 3. 检查 HTTP 状态码
     * 4. 使用 SseParser 解析 SSE 流，提取文本写入队列
     */
    public func chat(request: ChatRequest, queue: CharQueue, mtx: Mutex): Unit {
        let apiKey = configManager.getApiKey("kimi")
        if (apiKey.isEmpty()) {
            synchronized(mtx) {
                queue.addMany("[系统] 错误：Kimi API Key 未配置")
            }
            return
        }

        // 拼接完整的 API URL
        let baseUrl = configManager.getBaseUrl("kimi")
        let url = "${baseUrl}/chat/completions"
        try {
            // 构建 JSON 请求体
            let reqBody = buildRequestBody(request)
            // 构建 HTTP 请求：POST + JSON 载荷 + Bearer Token 认证
            let req = HttpRequestBuilder()
                .post()
                .url(url)
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer ${apiKey}")
                .body(reqBody)
                .build()

            // 发送请求
            let resp = client.send(req)
            if (resp.status != 200) {
                synchronized(mtx) {
                    queue.addMany("[系统] HTTP 错误: ${resp.status}")
                }
                return
            }

            // 解析 SSE 流式响应，逐片段写入字符队列
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

    /**
     * 使用 JsonWriter 流式构建请求体 JSON
     *
     * 格式示例：
     * {
     *   "model": "moonshot-v1-8k",
     *   "stream": true,
     *   "messages": [
     *     {"role": "user", "content": "你好"}
     *   ]
     * }
     */
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

