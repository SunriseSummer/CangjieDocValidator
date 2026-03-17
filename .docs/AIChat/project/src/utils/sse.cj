/**
 * SseParser —— Server-Sent Events 流式解析器
 *
 * SSE 是 AI API 流式响应使用的协议，格式为：
 *   data: {"choices":[{"delta":{"content":"你"}}]}
 *   data: {"choices":[{"delta":{"content":"好"}}]}
 *   data: [DONE]
 *
 * 本解析器提供两个核心功能：
 * - parseStream()：从字节流中逐行解析 SSE 事件
 * - extractDelta()：从单条 JSON 中提取 delta.content 文本
 *
 * 解析策略：将接收到的字节累积到缓冲区，按换行符切分为行，
 * 处理所有完整行，保留最后一个可能不完整的行到下一轮循环。
 * 这正确处理了网络数据包与逻辑行之间的边界错位问题。
 */
package aichat.utils

import stdx.encoding.json.*
import std.io.InputStream

public class SseParser {
    /**
     * 从输入流中解析 SSE 事件
     *
     * @param body    HTTP 响应体的输入流
     * @param onData  每解析到一条有效数据时调用的回调函数
     *
     * 解析逻辑：
     * 1. 循环读取字节到缓冲区
     * 2. 将字节转为字符串并累积到 pending
     * 3. 按 "\n" 分割为行
     * 4. 处理所有完整行（最后一行可能不完整，留到下轮）
     * 5. 识别 "data: " 前缀的行，忽略 [DONE] 终止标记
     */
    public static func parseStream(body: InputStream, onData: (String) -> Unit): Unit {
        let buf = Array<UInt8>(4096, repeat: 0)
        var pending = ""

        var bytesRead = body.read(buf)
        while (bytesRead > 0) {
            // 将读取的字节追加到待处理缓冲区
            pending = pending + String.fromUtf8(buf[0..bytesRead])
            let lines = pending.split("\n")
            // 处理除最后一行外的所有完整行
            for (i in 0..(lines.size - 1)) {
                let line = lines[i].trimAscii()
                if (line.startsWith("data: ")) {
                    let data = line[6..line.size]
                    if (data != "[DONE]" && !data.isEmpty()) {
                        onData(data)
                    }
                }
            }
            // 保留最后一个可能不完整的行
            pending = lines[lines.size - 1]
            bytesRead = body.read(buf)
        }
    }

    /**
     * 从单条 SSE JSON 中提取 delta.content 文本
     *
     * AI API 的流式响应格式（OpenAI 兼容）：
     * {"choices":[{"delta":{"content":"文本片段"}}]}
     *
     * 逐层解析：choices[0] → delta → content
     * 解析失败时静默返回空字符串，不抛出异常。
     */
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
