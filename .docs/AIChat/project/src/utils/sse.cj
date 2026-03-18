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
 * 解析策略：在字节级别按换行符（0x0A）分割，只在完整行上进行
 * UTF-8 → String 转换。由于换行符是单字节 ASCII 字符，在 UTF-8 编码中
 * 不会出现在多字节字符内部，因此按换行字节分割总是安全的，
 * 不会打断中文等多字节字符。
 *
 * 这修复了旧版本中 String.fromUtf8(buf[0..bytesRead]) 在网络读取边界处
 * 分割多字节 UTF-8 字符导致中文显示乱码的问题。
 */
package aichat.utils

import stdx.encoding.json.*
import std.io.InputStream
import std.collection.ArrayList

public class SseParser {
    /**
     * 从输入流中解析 SSE 事件
     *
     * @param body    HTTP 响应体的输入流
     * @param onData  每解析到一条有效数据时调用的回调函数
     *
     * 解析逻辑：
     * 1. 循环读取原始字节
     * 2. 逐字节扫描，按换行字节（0x0A）分割为行
     * 3. 只在找到完整行后才进行 UTF-8 → String 转换
     * 4. 识别 "data: " 前缀的行，忽略 [DONE] 终止标记
     *
     * 关键：不在 read() 返回后直接对原始字节做 String.fromUtf8()，
     * 而是先在字节级别找到行边界，再对完整行做转换。
     * 这避免了多字节 UTF-8 字符被 read() 边界切断导致中文乱码。
     */
    public static func parseStream(body: InputStream, onData: (String) -> Unit): Unit {
        let readBuf = Array<UInt8>(4096, repeat: 0)
        let lineBuf = ArrayList<UInt8>()

        var bytesRead = body.read(readBuf)
        while (bytesRead > 0) {
            for (i in 0..bytesRead) {
                if (readBuf[i] == UInt8(10)) {
                    // 找到换行字节，处理已累积的一行
                    if (lineBuf.size > 0) {
                        handleSseLine(lineBuf, onData)
                    }
                    lineBuf.clear()
                } else {
                    lineBuf.add(readBuf[i])
                }
            }
            bytesRead = body.read(readBuf)
        }

        // 处理流末尾可能残留的数据
        if (lineBuf.size > 0) {
            handleSseLine(lineBuf, onData)
        }
    }

    /**
     * 将字节列表转换为字符串并作为 SSE 数据行处理
     *
     * 此时 lineBuf 包含一个完整行的所有字节（不含换行符），
     * 因此 String.fromUtf8 不会遇到被截断的多字节字符。
     */
    private static func handleSseLine(lineBytes: ArrayList<UInt8>, onData: (String) -> Unit): Unit {
        let arr = Array<UInt8>(lineBytes.size, repeat: 0)
        for (i in 0..lineBytes.size) {
            arr[i] = lineBytes[i]
        }
        let line = String.fromUtf8(arr).trimAscii()
        if (line.startsWith("data: ")) {
            let data = line[6..line.size]
            if (data != "[DONE]" && !data.isEmpty()) {
                onData(data)
            }
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
