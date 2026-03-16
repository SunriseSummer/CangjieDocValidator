# 10. 网络编程与项目总装：AI 聊天工具诞生

> 代码的最终使命，是在真实世界中运行。我们用 10 章积累的每一块砖——类型、函数、集合、并发、错误处理——在这里拼成一座真正可以对话的 AI 终端工具。

## 本章目标

*   了解 `stdx` 扩展库的能力与使用方式。
*   使用 `ClientBuilder` 和 `HttpRequestBuilder` 发送 HTTP 请求。
*   配置 TLS（`TlsClientConfig`）支持 HTTPS。
*   构建和解析 AI 接口的 JSON 请求/响应。
*   解析 Server-Sent Events（SSE）流式响应。
*   将所有组件组装成完整的 AIChatPro 项目。

---

## 1. stdx 扩展库简介

`stdx` 是仓颉的官方扩展标准库，提供标准库之外的高级功能：

| 包 | 功能 |
|---|---|
| `stdx.net.http` | HTTP/1.1 客户端与服务端 |
| `stdx.net.tls` | TLS/HTTPS 安全连接 |
| `stdx.encoding.json` | JSON 序列化与反序列化 |
| `stdx.encoding.json.stream` | 流式 JSON 读写（JsonWriter/JsonReader） |

在 `cjpm.toml` 中添加依赖：

<!-- check:build_only -->
```cangjie
// 依赖配置示例（cjpm.toml 中已配置，此处仅为展示导入方式）
import stdx.net.http.*
import stdx.net.tls.*
import stdx.encoding.json.*
import stdx.encoding.json.stream.*

main() {
    // 模块导入验证
    let _ = JsonObject()
    println("stdx 模块导入成功")
}
```

---

## 2. HTTP 客户端

### 2.1 ClientBuilder 与请求构建

HTTP 客户端通过 `ClientBuilder` 配置，请求通过 `HttpRequestBuilder` 构建：

<!-- check:build_only -->
```cangjie
import stdx.net.http.*
import stdx.net.tls.*

main() {
    // 配置 TLS
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = TrustAll  // 开发环境用；生产环境应验证证书

    // 构建客户端（可复用）
    let client = ClientBuilder()
        .tlsConfig(tlsConfig)
        .build()

    // 构建 GET 请求
    let getReq = HttpRequestBuilder()
        .get()
        .url("https://httpbin.org/get")
        .header("User-Agent", "AIChatPro/1.0")
        .build()

    // 构建 POST 请求（带 JSON body）
    let body = "{\"message\":\"hello\"}"
    let postReq = HttpRequestBuilder()
        .post()
        .url("https://api.example.com/chat")
        .header("Content-Type", "application/json")
        .header("Authorization", "Bearer sk-xxxx")
        .body(body)
        .build()

    println("HTTP 客户端已配置")
    println("GET URL: ${getReq.url}")
    println("POST URL: ${postReq.url}")
}
```

### 2.2 发送请求与读取响应

<!-- check:build_only -->
```cangjie
import stdx.net.http.*
import stdx.net.tls.*
import std.io.InputStream
import std.collection.ArrayList

func readBodyString(body: InputStream): String {
    let chunks = ArrayList<String>()
    let buf = Array<UInt8>(8192, repeat: 0)
    var n = body.read(buf)
    while (n > 0) {
        chunks.add(String.fromUtf8(buf[0..n]))
        n = body.read(buf)
    }
    let sb = StringBuilder()
    for (chunk in chunks) { sb.append(chunk) }
    return sb.toString()
}

func fetchJson(url: String): String {
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = TrustAll
    let client = ClientBuilder().tlsConfig(tlsConfig).build()

    let req = HttpRequestBuilder()
        .get()
        .url(url)
        .header("Accept", "application/json")
        .build()

    let resp = client.send(req)

    if (resp.status != 200) {
        throw Exception("HTTP 错误: ${resp.status}")
    }

    return readBodyString(resp.body)
}

main() {
    try {
        let json = fetchJson("https://httpbin.org/json")
        println("响应长度: ${json.size} 字节")
        println("前 50 字符: ${json}")
    } catch (e: Exception) {
        println("请求失败: ${e.message}")
    }
}
```

---

## 3. TLS 配置

### 3.1 TLS 验证模式

<!-- check:build_only -->
```cangjie
import stdx.net.http.*
import stdx.net.tls.*

func createProductionClient(): Client {
    // 生产环境：验证服务器证书（默认）
    var tlsConfig = TlsClientConfig()
    // tlsConfig.verifyMode = Default  // 默认就是验证证书
    return ClientBuilder().tlsConfig(tlsConfig).build()
}

func createDevelopmentClient(): Client {
    // 开发/测试环境：信任所有证书（不验证）
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = TrustAll
    return ClientBuilder().tlsConfig(tlsConfig).build()
}

main() {
    let prodClient = createProductionClient()
    let devClient = createDevelopmentClient()
    println("生产客户端: 已创建（证书验证）")
    println("开发客户端: 已创建（TrustAll）")
}
```

---

## 4. JSON 构建与解析

### 4.1 构建 AI 请求 JSON

使用 `stdx.encoding.json` 的对象 API 构建结构化 JSON：

<!-- check:run -->
```cangjie
import stdx.encoding.json.*

main() {
    // 构建请求 JSON
    let root = JsonObject()
    root.put("model", JsonString("moonshot-v1-8k"))
    root.put("stream", JsonBool(true))
    root.put("temperature", JsonFloat(0.7))

    let messages = JsonArray()

    let sysMsg = JsonObject()
    sysMsg.put("role", JsonString("system"))
    sysMsg.put("content", JsonString("你是一名专业的 AI 助手"))
    messages.add(sysMsg)

    let userMsg = JsonObject()
    userMsg.put("role", JsonString("user"))
    userMsg.put("content", JsonString("你好！"))
    messages.add(userMsg)

    root.put("messages", messages)

    println(root.toJsonString())
}
```

<!-- expected_output:
{
  "model": "moonshot-v1-8k",
  "stream": true,
  "temperature": 0.7,
  "messages": [
    {
      "role": "system",
      "content": "你是一名专业的 AI 助手"
    },
    {
      "role": "user",
      "content": "你好！"
    }
  ]
}
-->

### 4.2 使用 JsonWriter 流式构建

`JsonWriter` 适合构建大型 JSON，避免中间对象分配：

<!-- check:build_only -->
```cangjie
import stdx.encoding.json.stream.*
import std.io.{ByteBuffer, readToEnd}

func buildChatRequest(model: String, messages: Array<(String, String)>, stream!: Bool = true): String {
    let buf = ByteBuffer()
    let writer = JsonWriter(buf)

    writer.startObject()
    writer.writeName("model").writeValue(model)
    writer.writeName("stream").writeValue(stream)
    writer.writeName("messages")
    writer.startArray()
    for ((role, content) in messages) {
        writer.startObject()
        writer.writeName("role").writeValue(role)
        writer.writeName("content").writeValue(content)
        writer.endObject()
    }
    writer.endArray()
    writer.endObject()
    writer.flush()

    return String.fromUtf8(readToEnd(buf))
}

main() {
    let msgs: Array<(String, String)> = [
        ("system", "你是 AI 助手"),
        ("user", "仓颉语言有哪些特点？")
    ]
    let json = buildChatRequest("moonshot-v1-8k", msgs)
    println("请求体长度: ${json.size}")
    println("包含 model: ${json.contains("moonshot-v1-8k")}")
    println("包含 messages: ${json.contains("messages")}")
}
```

### 4.3 解析 AI 流式响应 JSON

<!-- check:run -->
```cangjie
import stdx.encoding.json.*

func extractContent(jsonStr: String): String {
    try {
        let jv = JsonValue.fromStr(jsonStr)
        let obj = jv.asObject()
        if (let Some(choices) <- obj.get("choices")) {
            let arr = choices.asArray()
            if (arr.size() > 0) {
                let choice = arr[0].asObject()
                if (let Some(delta) <- choice.get("delta")) {
                    let deltaObj = delta.asObject()
                    if (let Some(content) <- deltaObj.get("content")) {
                        return content.asString().getValue()
                    }
                }
            }
        }
    } catch (e: Exception) {}
    return ""
}

main() {
    // 模拟 AI SSE 流中的 JSON 片段
    let r1 = "{\"choices\":[{\"delta\":{\"content\":\"你好！\"}}]}"
    let r2 = "{\"choices\":[{\"delta\":{\"content\":\"我是 AI 助手。\"}}]}"
    let r3 = "{\"choices\":[{\"delta\":{\"content\":\"有什么可以帮你？\"}}]}"
    let r4 = "{\"choices\":[{\"delta\":{}}]}"
    let r5 = "{\"choices\":[{\"finish_reason\":\"stop\"}]}"
    let mockResponses = [r1, r2, r3, r4, r5]

    let sb = StringBuilder()
    for (resp in mockResponses) {
        let content = extractContent(resp)
        if (!content.isEmpty()) {
            sb.append(content)
        }
    }
    println(sb.toString())
}
```

<!-- expected_output:
你好！我是 AI 助手。有什么可以帮你？
-->

---

## 5. SSE 流式解析

Server-Sent Events（SSE）是 AI 流式响应的标准格式，每行形如：

```
data: {"choices":[{"delta":{"content":"你"}}]}
data: {"choices":[{"delta":{"content":"好"}}]}
data: [DONE]
```

### 5.1 SSE 解析器

<!-- check:build_only -->
```cangjie
import stdx.encoding.json.*
import std.io.*

class SseParser {
    // 从字节流中解析 SSE，每条 data 行调用一次 onData 回调
    public static func parseStream(body: InputStream, onData: (String) -> Unit): Unit {
        let buf = Array<UInt8>(4096, repeat: 0)
        var pending = ""

        var bytesRead = body.read(buf)
        while (bytesRead > 0) {
            pending = pending + String.fromUtf8(buf[0..bytesRead])
            let lines = pending.split("\n")
            // 处理所有完整行（最后一行可能不完整，留到下次）
            for (i in 0..(lines.size - 1)) {
                let line = lines[i].trimAscii()
                if (line.startsWith("data: ")) {
                    let data = line[6..line.size]
                    if (data != "[DONE]" && !data.isEmpty()) {
                        onData(data)
                    }
                }
            }
            pending = lines[lines.size - 1]
            bytesRead = body.read(buf)
        }
    }

    // 从单个 JSON 字符串中提取 delta.content
    public static func extractDelta(jsonStr: String): String {
        try {
            let jv = JsonValue.fromStr(jsonStr)
            let obj = jv.asObject()
            if (let Some(choices) <- obj.get("choices")) {
                let arr = choices.asArray()
                if (arr.size() > 0) {
                    let choice = arr[0].asObject()
                    if (let Some(delta) <- choice.get("delta")) {
                        let deltaObj = delta.asObject()
                        if (let Some(content) <- deltaObj.get("content")) {
                            return content.asString().getValue()
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        return ""
    }
}

main() {
    println("SseParser 类定义成功")
}
```

---

## 6. 完整项目实现

将所有组件组装成完整的 AIChatPro。项目采用多包结构，每个文件属于独立子包。

### 项目结构

```
src/
├── main.cj                  # 入口点 (package aichat)
├── config/
│   ├── types.cj             # 配置类型 (package aichat.config)
│   └── manager.cj           # ConfigManager (package aichat.config)
├── models/
│   ├── types.cj             # ChatMessage, ChatRequest (package aichat.models)
│   ├── base.cj              # BaseChatModel 接口 (package aichat.models)
│   └── kimi.cj              # KimiModel 实现 (package aichat.models)
├── stream/
│   ├── queue.cj             # CharQueue (package aichat.stream)
│   └── engine.cj            # StreamEngine (package aichat.stream)
├── utils/
│   └── sse.cj               # SseParser (package aichat.utils)
└── repl/
    └── runner.cj            # ReplRunner (package aichat.repl)
```

每个子包职责单一，相互之间通过 `import` 引用。下面我们逐一实现每个文件。

> **阅读提示**：这些代码块是完整项目的各个片段，直接按照文件路径组合即可运行。每一节都有注释解释关键设计决策。

### 6.1 配置类型

<!-- check:build_only project=aichat file=src/config/types.cj -->
```cangjie
package aichat.config

public struct ModelConfig {
    public let displayName: String
    public let apiUrl: String
    public let defaultModelId: String

    public init(displayName: String, apiUrl: String, defaultModelId: String) {
        this.displayName = displayName
        this.apiUrl = apiUrl
        this.defaultModelId = defaultModelId
    }
}

public struct StreamSettings {
    public let displayIntervalMs: Int64
    public let maxHistorySize: Int64

    public init(displayIntervalMs!: Int64 = 30, maxHistorySize!: Int64 = 20) {
        this.displayIntervalMs = displayIntervalMs
        this.maxHistorySize = maxHistorySize
    }
}

public class AppConfig {
    public let streamSettings: StreamSettings

    public init(streamSettings!: StreamSettings = StreamSettings()) {
        this.streamSettings = streamSettings
    }
}
```

### 6.2 ConfigManager

<!-- check:build_only project=aichat file=src/config/manager.cj -->
```cangjie
package aichat.config

import std.collection.HashMap

public class ConfigError <: Exception {
    public init(msg: String) { super(msg) }
}

public class ConfigManager {
    private let apiKeys: HashMap<String, String> = HashMap<String, String>()
    private let baseUrls: HashMap<String, String> = HashMap<String, String>()
    private let modelIds: HashMap<String, String> = HashMap<String, String>()
    private var currentModel: String = "kimi"

    public init() {
        baseUrls.add("kimi", "https://api.moonshot.cn/v1")
        baseUrls.add("glm", "https://open.bigmodel.cn/api/paas/v4")
        baseUrls.add("minimax", "https://api.minimax.chat/v1")

        modelIds.add("kimi", "moonshot-v1-8k")
        modelIds.add("glm", "glm-4")
        modelIds.add("minimax", "abab6.5-chat")
    }

    public func setApiKey(model: String, key: String): Unit {
        if (key.isEmpty()) {
            throw ConfigError("API Key 不能为空 (model: ${model})")
        }
        apiKeys.add(model, key)
    }

    public func getApiKey(model: String): String {
        apiKeys.get(model) ?? ""
    }

    public func getBaseUrl(model: String): String {
        baseUrls.get(model) ?? ""
    }

    public func getModelId(model: String): String {
        modelIds.get(model) ?? model
    }

    public func getCurrentModel(): String { currentModel }

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

    public func hasApiKey(model: String): Bool {
        let key = apiKeys.get(model) ?? ""
        return !key.isEmpty()
    }

    public func validate(): Unit {
        if (!hasApiKey(currentModel)) {
            throw ConfigError("当前模型 '${currentModel}' 的 API Key 未配置，请设置环境变量")
        }
    }
}
```

### 6.3 数据模型类型

<!-- check:build_only project=aichat file=src/models/types.cj -->
```cangjie
package aichat.models

import std.collection.ArrayList

public class ChatMessage {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        this.role = role
        this.content = content
    }
}

public class ChatRequest {
    public let model: String
    public let messages: ArrayList<ChatMessage>
    public let stream: Bool
    public let temperature: Float64

    public init(
        model: String,
        messages: ArrayList<ChatMessage>,
        stream!: Bool = true,
        temperature!: Float64 = 0.7
    ) {
        this.model = model
        this.messages = messages
        this.stream = stream
        this.temperature = temperature
    }
}

public class ConversationHistory {
    private let messages: ArrayList<ChatMessage> = ArrayList<ChatMessage>()
    private let maxSize: Int64

    public init(maxSize!: Int64 = 20) {
        this.maxSize = maxSize
    }

    public func add(role: String, content: String): Unit {
        if (messages.size >= maxSize) {
            messages.remove(at: 0)
            if (messages.size > 0) { messages.remove(at: 0) }
        }
        messages.add(ChatMessage(role, content))
    }

    public func toArrayList(): ArrayList<ChatMessage> {
        let result = ArrayList<ChatMessage>()
        for (i in 0..messages.size) {
            result.add(messages[i])
        }
        return result
    }

    public func clear(): Unit { messages.clear() }

    public prop size: Int64 { get() { messages.size } }
}
```

### 6.4 BaseChatModel 接口

<!-- check:build_only project=aichat file=src/models/base.cj -->
```cangjie
package aichat.models

import std.sync.Mutex
import aichat.stream.CharQueue

public interface BaseChatModel {
    func chat(request: ChatRequest, queue: CharQueue, mtx: Mutex): Unit
    func getName(): String
    func getModelId(): String
}
```

### 6.5 CharQueue（字符缓冲队列）

<!-- check:build_only project=aichat file=src/stream/queue.cj -->
```cangjie
package aichat.stream

import std.sync.Mutex
import std.collection.ArrayList

public class CharQueue {
    private let queue: ArrayList<Rune> = ArrayList<Rune>()
    private let collected: ArrayList<Rune> = ArrayList<Rune>()
    private let mtx: Mutex = Mutex()
    private var finished: Bool = false

    public func addMany(str: String): Unit {
        synchronized(mtx) {
            for (ch in str.runes()) { queue.add(ch) }
        }
    }

    public func poll(): ?Rune {
        synchronized(mtx) {
            if (queue.size > 0) {
                let ch = queue[0]
                queue.remove(at: 0)
                collected.add(ch)
                return Some(ch)
            }
            return None
        }
    }

    public func size(): Int64 {
        synchronized(mtx) { queue.size }
    }

    public func setFinished(): Unit {
        synchronized(mtx) { finished = true }
    }

    public func isFinished(): Bool {
        synchronized(mtx) { finished && queue.size == 0 }
    }

    public func getCollected(): String {
        synchronized(mtx) {
            let sb = StringBuilder()
            for (ch in collected) { sb.append(ch) }
            sb.toString()
        }
    }

    public func clear(): Unit {
        synchronized(mtx) {
            queue.clear()
            collected.clear()
            finished = false
        }
    }
}
```

### 6.6 StreamEngine（流式显示引擎）

<!-- check:build_only project=aichat file=src/stream/engine.cj -->
```cangjie
package aichat.stream

import std.sync.*

public class StreamEngine {
    private let queue: CharQueue
    private let mtx: Mutex
    private let displayIntervalMs: Int64

    public init(queue: CharQueue, mtx: Mutex, displayIntervalMs!: Int64 = 30) {
        this.queue = queue
        this.mtx = mtx
        this.displayIntervalMs = displayIntervalMs
    }

    public func startDisplay(): Future<Unit> {
        spawn {
            while (!queue.isFinished()) {
                var hasOutput = false
                var ch = queue.poll()
                while (let Some(c) <- ch) {
                    print(c.toString())
                    hasOutput = true
                    ch = queue.poll()
                }
                if (!hasOutput) {
                    sleep(Duration.millisecond * displayIntervalMs)
                }
            }
            println("")
        }
    }
}
```

### 6.7 SSE 解析器

<!-- check:build_only project=aichat file=src/utils/sse.cj -->
```cangjie
package aichat.utils

import stdx.encoding.json.*
import std.io.InputStream

public class SseParser {
    public static func parseStream(body: InputStream, onData: (String) -> Unit): Unit {
        let buf = Array<UInt8>(4096, repeat: 0)
        var pending = ""

        var bytesRead = body.read(buf)
        while (bytesRead > 0) {
            pending = pending + String.fromUtf8(buf[0..bytesRead])
            let lines = pending.split("\n")
            for (i in 0..(lines.size - 1)) {
                let line = lines[i].trimAscii()
                if (line.startsWith("data: ")) {
                    let data = line[6..line.size]
                    if (data != "[DONE]" && !data.isEmpty()) {
                        onData(data)
                    }
                }
            }
            pending = lines[lines.size - 1]
            bytesRead = body.read(buf)
        }
    }

    public static func extractDelta(jsonStr: String): String {
        try {
            let jv = JsonValue.fromStr(jsonStr)
            let obj = jv.asObject()
            if (let Some(choices) <- obj.get("choices")) {
                let arr = choices.asArray()
                if (arr.size() > 0) {
                    let choice = arr[0].asObject()
                    if (let Some(delta) <- choice.get("delta")) {
                        let deltaObj = delta.asObject()
                        if (let Some(content) <- deltaObj.get("content")) {
                            return content.asString().getValue()
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        return ""
    }
}
```

### 6.8 KimiModel 实现

<!-- check:build_only project=aichat file=src/models/kimi.cj -->
```cangjie
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
    private let configManager: ConfigManager
    private let client: Client

    public init(configManager: ConfigManager) {
        this.configManager = configManager
        var tlsConfig = TlsClientConfig()
        tlsConfig.verifyMode = TrustAll
        this.client = ClientBuilder()
            .tlsConfig(tlsConfig)
            .build()
    }

    public func getName(): String { "kimi" }

    public func getModelId(): String {
        configManager.getModelId("kimi")
    }

    public func chat(request: ChatRequest, queue: CharQueue, mtx: Mutex): Unit {
        let apiKey = configManager.getApiKey("kimi")
        if (apiKey.isEmpty()) {
            synchronized(mtx) {
                queue.addMany("[系统] 错误：Kimi API Key 未配置")
            }
            queue.setFinished()
            return
        }

        let url = "${configManager.getBaseUrl("kimi")}/chat/completions"
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
                queue.setFinished()
                return
            }

            SseParser.parseStream(resp.body) { jsonStr =>
                let delta = SseParser.extractDelta(jsonStr)
                if (!delta.isEmpty()) {
                    synchronized(mtx) { queue.addMany(delta) }
                }
            }
        } catch (e: Exception) {
            synchronized(mtx) {
                queue.addMany("\n[系统] 网络错误: ${e.message}")
            }
        } finally {
            queue.setFinished()
        }
    }

    private func buildRequestBody(request: ChatRequest): String {
        let buf = ByteBuffer()
        let writer = JsonWriter(buf)
        writer.startObject()
        writer.writeName("model").writeValue(request.model)
        writer.writeName("stream").writeValue(request.stream)
        writer.writeName("temperature").writeValue(request.temperature)
        writer.writeName("messages")
        writer.startArray()
        for (i in 0..request.messages.size) {
            let msg = request.messages[i]
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
```

### 6.9 ReplRunner（REPL 交互循环）

<!-- check:build_only project=aichat file=src/repl/runner.cj -->
```cangjie
package aichat.repl

import std.sync.*
import aichat.config.ConfigManager
import aichat.models.{BaseChatModel, ChatRequest, ConversationHistory}
import aichat.stream.{CharQueue, StreamEngine}

public class ReplRunner {
    private let configManager: ConfigManager
    private var currentModel: BaseChatModel
    private let history: ConversationHistory
    private let mtx: Mutex = Mutex()

    public init(configManager: ConfigManager, model: BaseChatModel) {
        this.configManager = configManager
        this.currentModel = model
        this.history = ConversationHistory(maxSize: 20)
    }

    public func run(): Unit {
        printBanner()

        while (true) {
            print("\n你> ")
            let line = readln()
            let input = line.trimAscii()
            if (input.isEmpty()) { continue }

            if (input.startsWith("/")) {
                if (!handleCommand(input)) { break }
            } else {
                sendMessage(input)
            }
        }
        println("\n再见！感谢使用 AIChatPro。")
    }

    private func printBanner(): Unit {
        println("╔══════════════════════════════════════╗")
        println("║       AIChatPro — 仓颉版              ║")
        println("║  输入 /help 查看可用命令               ║")
        println("╚══════════════════════════════════════╝")
        println("当前模型: ${currentModel.getName()} (${currentModel.getModelId()})")
    }

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

    private func sendMessage(userInput: String): Unit {
        history.add("user", userInput)

        let messages = history.toArrayList()
        let request = ChatRequest(
            currentModel.getModelId(),
            messages
        )

        let queue = CharQueue()
        let engine = StreamEngine(queue, mtx)

        print("\nAI> ")
        let displayFuture = engine.startDisplay()

        let modelRef = currentModel
        let chatFuture = spawn {
            modelRef.chat(request, queue, mtx)
        }

        chatFuture.get()
        displayFuture.get()

        let response = queue.getCollected()
        if (!response.isEmpty()) {
            history.add("assistant", response)
        }
    }
}
```

### 6.10 主入口

<!-- check:build_only project=aichat file=src/main.cj -->
```cangjie
package aichat

import std.env.*
import aichat.config.{ConfigManager, ConfigError}
import aichat.models.KimiModel
import aichat.repl.ReplRunner

func getEnvOrEmpty(key: String): String {
    // 实际使用 std.env 获取环境变量
    // 此处为简化示例
    ""
}

main(): Unit {
    let configManager = ConfigManager()

    // 从环境变量加载 API Key（实际运行时需要真实 Key）
    let kimiKey = getEnvOrEmpty("KIMI_API_KEY")
    if (!kimiKey.isEmpty()) {
        try {
            configManager.setApiKey("kimi", kimiKey)
        } catch (e: ConfigError) {
            println("配置警告: ${e.message}")
        }
    }

    let glmKey = getEnvOrEmpty("GLM_API_KEY")
    if (!glmKey.isEmpty()) {
        try {
            configManager.setApiKey("glm", glmKey)
        } catch (e: ConfigError) {
            println("配置警告: ${e.message}")
        }
    }

    let model = KimiModel(configManager)
    let repl = ReplRunner(configManager, model)
    repl.run()
}
```

---

## 工程化提示

*   **TrustAll vs Default**：生产环境请使用 `Default` 证书验证，`TrustAll` 仅用于开发调试。接入 AI API 时，泄露请求内容的风险远大于证书验证带来的性能开销。
*   **Client 复用**：`ClientBuilder().build()` 应在初始化时创建一次，而非每次请求都新建。复用 Client 可以利用连接池，显著降低延迟。
*   **SSE 的鲁棒性**：真实 SSE 流可能出现跨缓冲区的行分割，本章的解析器用 `StringBuilder` 累积不完整行，正确处理了这种情况。
*   **包结构的好处**：将代码分散到 `models/`、`stream/`、`config/` 等子包，使每个包的职责清晰——这正是仓颉包系统的设计初衷。

---

## 系列总结

恭喜！你已经完成了 AIChatPro 的全部 10 章学习之旅：

| 章节 | 核心概念 | 在项目中的作用 |
|---|---|---|
| 01 | main、变量、字符串插值 | 程序入口、启动横幅 |
| 02 | 类型系统、控制流 | 命令解析逻辑 |
| 03 | 函数、闭包、管道运算符 | token 回调、SSE 处理 |
| 04 | struct/class | ChatMessage、ChatRequest 数据模型 |
| 05 | enum、Option、模式匹配 | Role 枚举、命令系统 |
| 06 | interface、extend | BaseChatModel 抽象、工具扩展 |
| 07 | ArrayList、HashMap、泛型 | ConversationHistory、配置存储 |
| 08 | 异常处理 | ConfigManager、API 错误恢复 |
| 09 | spawn、Future、Mutex | CharQueue、StreamEngine |
| 10 | stdx HTTP/TLS/JSON | KimiModel 真实网络调用 |

---

## 实践挑战

1.  为 AIChatPro 添加 `GlmModel`，复用 `BaseChatModel` 接口，只需修改 URL 和请求体格式。
2.  实现 `/switch <model>` 命令，让用户在 REPL 中动态切换模型（提示：`ReplRunner` 持有 `currentModel` 变量，将其改为 `var` 即可替换）。
3.  为 `ConversationHistory` 添加 `save(path: String)` 和 `load(path: String)` 方法，让对话历史持久化到本地文件（提示：使用 `std.fs.File`）。
