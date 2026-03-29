/**
 * SseParser —— Server-Sent Events 流式解析器
 *
 * SSE 是 AI API 流式响应使用的协议，格式为：
 *   data: {"choices":[{"delta":{"content":"你"}}]}
 *   data: {"choices":[{"delta":{"content":"好"}}]}
 *   data: [DONE]
 *
 * 本解析器提供两个核心功能：
 * - parseStream()：从响应流中按事件边界解析 SSE 数据
 * - extractDelta()：从单条 JSON 中提取 delta.content 文本
 *
 * 解析策略：在字节级别累积原始数据，按 "data: " 和 "\n\n" 标记
 * 搜索完整的 SSE 事件。只对完整事件做 UTF-8 → String 转换，
 * 避免在多字节字符中间截断导致中文显示乱码。
 */
package aichat.utils

import stdx.encoding.json.*
import std.io.InputStream
import std.collection.ArrayList

public class SseParser {
    /**
     * 从输入流中解析 SSE 事件
     *
     * @param body      HTTP 响应体的输入流
     * @param callback  每解析到一条有效数据时调用的回调函数
     *
     * 解析逻辑：
     * 1. 在字节级别累积原始数据，按换行字节(0x0A)分割为行
     * 2. 对完整行做 UTF-8 → String 转换（换行字节是单字节 ASCII，
     *    不会出现在多字节 UTF-8 字符内部，因此按换行分割不会打断中文字符）
     * 3. 识别 "data: " 前缀的行，忽略 [DONE] 终止标记
     * 4. 空行（SSE 事件分隔符）自动跳过
     */
    public static func parseStream(body: InputStream, callback: (String) -> Unit): Unit {
        let buf = Array<UInt8>(4096, repeat: 0)
        let lineBuf = ArrayList<UInt8>()

        var len = body.read(buf)
        while (len > 0) {
            for (i in 0..len) {
                if (buf[i] == UInt8(10)) {
                    // 找到换行字节，处理已累积的一行
                    if (lineBuf.size > 0) {
                        let arr = toArray(lineBuf)
                        let line = String.fromUtf8(arr).trimAscii()
                        if (line.startsWith("data: ")) {
                            let data = line[6..line.size]
                            if (data != "[DONE]" && !data.isEmpty()) {
                                callback(data)
                            }
                        }
                    }
                    lineBuf.clear()
                } else {
                    lineBuf.add(buf[i])
                }
            }
            len = body.read(buf)
        }

        // 处理流末尾可能残留的数据
        if (lineBuf.size > 0) {
            let arr = toArray(lineBuf)
            try {
                let line = String.fromUtf8(arr).trimAscii()
                if (line.startsWith("data: ")) {
                    let data = line[6..line.size]
                    if (data != "[DONE]" && !data.isEmpty()) {
                        callback(data)
                    }
                }
            } catch (_: Exception) {
                // 流末尾的残留字节可能是不完整的 UTF-8 序列（网络截断），
                // 此时无法形成有效的 SSE 数据行，静默忽略即可。
            }
        }
    }

    /**
     * 将 ArrayList<UInt8> 转换为 Array<UInt8>
     */
    private static func toArray(list: ArrayList<UInt8>): Array<UInt8> {
        let arr = Array<UInt8>(list.size, repeat: 0)
        for (i in 0..list.size) {
            arr[i] = list[i]
        }
        return arr
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
