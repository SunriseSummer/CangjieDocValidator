# AIChatPro — 仓颉版多模型 AI 命令行对话工具

AIChatPro 是 [AIChat 系列教程](..) 的完整项目产出，使用仓颉语言从零构建的多模型 AI 命令行对话工具。

## 功能特性

- **多模型支持**：接入 Kimi（月之暗面）、GLM（智谱 AI）、Minimax 等国产大模型
- **流式输出**：逐 token 实时显示 AI 回复（SSE 协议）
- **对话历史管理**：自动维护上下文，支持多轮连续对话
- **命令系统**：`/help`、`/clear`、`/exit` 等命令

## 项目结构

```
src/
├── main.cj                  # 入口点 (package aichat)
├── config/
│   ├── types.cj             # 配置类型：ModelConfig, StreamSettings, AppConfig
│   └── manager.cj           # ConfigManager：API Key 管理、模型切换
├── models/
│   ├── types.cj             # 数据模型：ChatMessage, ChatRequest, ConversationHistory
│   ├── base.cj              # BaseChatModel 接口
│   └── kimi.cj              # KimiModel 实现（HTTPS + SSE）
├── stream/
│   ├── queue.cj             # CharQueue：线程安全字符缓冲队列
│   └── engine.cj            # StreamEngine：流式显示引擎
├── utils/
│   └── sse.cj               # SseParser：SSE 流式解析器
└── repl/
    └── runner.cj            # ReplRunner：REPL 交互循环
```

## 快速开始

### 一键构建

```bash
chmod +x setup.sh
./setup.sh
```

### 手动构建

1. 安装仓颉 SDK（v1.0.5）和 STDX 扩展库
2. 修改 `cjpm.toml` 中的 `path-option` 为你的 STDX 路径
3. 执行：

```bash
source /path/to/cangjie/envsetup.sh
cjpm build
```

### 运行

```bash
# 设置 API Key（以 Kimi 为例）
export KIMI_API_KEY="你的 API Key"

# 运行
cjpm run
```

### 模拟测试（无需真实 API Key）

```bash
# 使用 Python 模拟服务器进行自动化测试
python3 test_aichat.py
```

## 环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `KIMI_API_KEY` | Kimi（月之暗面）API 密钥 | `sk-xxxxxx` |
| `GLM_API_KEY` | GLM（智谱 AI）API 密钥 | `xxxxxx.xxxxxx` |
| `MOCK_API_URL` | 自定义 API URL（测试用） | `http://localhost:8080/v1` |

## 教程对应关系

| 章节 | 核心概念 | 在项目中的体现 |
|------|---------|---------------|
| 01 | main、变量、字符串插值 | 程序入口、启动横幅 |
| 02 | 类型系统、控制流 | 命令解析逻辑 |
| 03 | 函数、闭包、管道运算符 | SSE 回调处理 |
| 04 | struct/class | ChatMessage、ModelConfig |
| 05 | enum、Option、模式匹配 | 命令系统、Option 类型处理 |
| 06 | interface、extend | BaseChatModel 抽象 |
| 07 | ArrayList、HashMap、泛型 | ConversationHistory、ConfigManager |
| 08 | 异常处理 | ConfigError、网络错误恢复 |
| 09 | spawn、Future、Mutex | CharQueue、StreamEngine |
| 10 | stdx HTTP/TLS/JSON | KimiModel 网络调用 |
