#!/usr/bin/env python3
"""
AIChatPro 模拟测试服务器

模拟 OpenAI 兼容的 AI API，用于在无法访问真实 AI 服务时测试 AIChatPro。
支持 SSE 流式响应和非流式响应。

使用方式：
    python3 mock_server.py [--port PORT]

测试 AIChatPro：
    # 终端 1：启动模拟服务器
    python3 mock_server.py --port 8080

    # 终端 2：设置环境变量指向模拟服务器，然后运行
    export KIMI_API_KEY="test-key"
    export MOCK_API_URL="http://localhost:8080/v1"
    cjpm run

API 端点：
    POST /v1/chat/completions  - 聊天补全接口（兼容 OpenAI 格式）
    GET  /health               - 健康检查
"""

import argparse
import json
import time
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

# 预设的模拟回复，根据用户输入的关键词匹配
MOCK_RESPONSES = {
    "你好": "你好！我是 AIChatPro 的模拟 AI 助手。很高兴为你服务！有什么可以帮你的吗？",
    "hello": "Hello! I'm a mock AI assistant for AIChatPro testing. How can I help you?",
    "仓颉": "仓颉是华为自研的面向全场景的新一代编程语言，兼具静态类型安全与现代语言的简洁表达力。它支持多范式编程，具有高性能和高安全性的特点。",
    "测试": "收到测试消息！AIChatPro 的 SSE 流式输出功能运行正常。当前模拟服务器已成功处理你的请求。",
    "cangjie": "Cangjie is a new programming language developed by Huawei, designed for all scenarios with static type safety and modern expressiveness.",
}

# 默认回复（当没有匹配到关键词时）
DEFAULT_RESPONSE = "这是模拟 AI 的回复。你说的是：\"{user_input}\"。AIChatPro 流式输出测试正常！"


def get_mock_response(user_input: str) -> str:
    """根据用户输入获取模拟回复"""
    for keyword, response in MOCK_RESPONSES.items():
        if keyword in user_input.lower():
            return response
    return DEFAULT_RESPONSE.format(user_input=user_input)


class MockAIHandler(BaseHTTPRequestHandler):
    """模拟 AI API 的 HTTP 请求处理器"""

    def log_message(self, format, *args):
        """自定义日志格式"""
        print(f"[MockServer] {args[0]}", file=sys.stderr)

    def do_GET(self):
        """处理 GET 请求（健康检查）"""
        parsed = urlparse(self.path)
        if parsed.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = json.dumps({"status": "ok", "server": "AIChatPro Mock Server"})
            self.wfile.write(response.encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        """处理 POST 请求（聊天补全）"""
        parsed = urlparse(self.path)

        if parsed.path != "/v1/chat/completions":
            self.send_response(404)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            error = json.dumps({"error": {"message": f"Unknown endpoint: {parsed.path}"}})
            self.wfile.write(error.encode("utf-8"))
            return

        # 验证 Authorization 头
        auth_header = self.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            self.send_response(401)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            error = json.dumps({"error": {"message": "Missing or invalid Authorization header"}})
            self.wfile.write(error.encode("utf-8"))
            return

        # 读取请求体
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)

        try:
            request_data = json.loads(body.decode("utf-8"))
        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            error = json.dumps({"error": {"message": "Invalid JSON in request body"}})
            self.wfile.write(error.encode("utf-8"))
            return

        # 提取用户消息
        messages = request_data.get("messages", [])
        user_input = ""
        for msg in reversed(messages):
            if msg.get("role") == "user":
                user_input = msg.get("content", "")
                break

        # 获取模拟回复
        mock_response = get_mock_response(user_input)
        is_stream = request_data.get("stream", False)
        model = request_data.get("model", "mock-model")

        print(f"[MockServer] 收到请求: model={model}, stream={is_stream}, input={user_input[:50]}...", file=sys.stderr)

        if is_stream:
            self._send_stream_response(mock_response, model)
        else:
            self._send_normal_response(mock_response, model)

    def _send_stream_response(self, response_text: str, model: str):
        """发送 SSE 流式响应，逐字符模拟 AI 输出"""
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.end_headers()

        # 将回复文本分成小片段，模拟逐 token 输出
        chunks = []
        i = 0
        while i < len(response_text):
            # 每次输出 1-3 个字符，模拟真实 token 分片
            chunk_size = min(2, len(response_text) - i)
            chunks.append(response_text[i:i + chunk_size])
            i += chunk_size

        for chunk in chunks:
            # 构建 SSE 数据行，格式与 OpenAI API 兼容
            sse_data = {
                "id": "mock-chat-001",
                "object": "chat.completion.chunk",
                "model": model,
                "choices": [{
                    "index": 0,
                    "delta": {"content": chunk},
                    "finish_reason": None
                }]
            }
            line = f"data: {json.dumps(sse_data, ensure_ascii=False)}\n\n"
            self.wfile.write(line.encode("utf-8"))
            self.wfile.flush()
            time.sleep(0.02)  # 模拟 token 生成延迟

        # 发送完成标记
        finish_data = {
            "id": "mock-chat-001",
            "object": "chat.completion.chunk",
            "model": model,
            "choices": [{
                "index": 0,
                "delta": {},
                "finish_reason": "stop"
            }]
        }
        self.wfile.write(f"data: {json.dumps(finish_data, ensure_ascii=False)}\n\n".encode("utf-8"))
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()

    def _send_normal_response(self, response_text: str, model: str):
        """发送非流式 JSON 响应"""
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

        response = {
            "id": "mock-chat-001",
            "object": "chat.completion",
            "model": model,
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": response_text
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": len(response_text),
                "total_tokens": 10 + len(response_text)
            }
        }
        self.wfile.write(json.dumps(response, ensure_ascii=False).encode("utf-8"))


def main():
    parser = argparse.ArgumentParser(description="AIChatPro 模拟测试服务器")
    parser.add_argument("--port", type=int, default=8080, help="服务器端口（默认 8080）")
    parser.add_argument("--host", default="127.0.0.1", help="服务器地址（默认 127.0.0.1）")
    args = parser.parse_args()

    server = HTTPServer((args.host, args.port), MockAIHandler)
    print(f"[MockServer] AIChatPro 模拟服务器已启动: http://{args.host}:{args.port}")
    print(f"[MockServer] 聊天接口: http://{args.host}:{args.port}/v1/chat/completions")
    print(f"[MockServer] 健康检查: http://{args.host}:{args.port}/health")
    print(f"[MockServer] 按 Ctrl+C 停止")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\n[MockServer] 服务器已停止")
        server.server_close()


if __name__ == "__main__":
    main()
