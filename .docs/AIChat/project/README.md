# AIChatPro — 仓颉版多模型 AI 命令行对话工具

AIChatPro 是 [AIChat 系列教程](..) 的完整项目产出，使用仓颉语言从零构建的多模型 AI 命令行对话工具。

## 功能特性

- **多模型支持**：接入 Kimi（月之暗面）、GLM（智谱 AI）、Minimax 等国产大模型
- **动态模型切换**：运行时通过 `/switch` 命令在不同模型间切换
- **JSON 配置持久化**：自动在可执行文件目录生成 `config.json`，保存 API Key 和模型配置
- **流式输出**：逐 token 实时显示 AI 回复（SSE 协议），支持自适应速率控制
- **对话历史管理**：自动维护上下文，支持多轮连续对话
- **交互式 API Key 输入**：首次使用时提示输入 API Key，自动保存到配置文件
- **命令系统**：`/help`、`/switch`、`/status`、`/clear`、`/exit` 等命令

## 项目结构

```
src/
├── main.cj                  # 入口点 (package aichat)
├── config/
│   ├── types.cj             # 配置类型：ModelConfig, StreamSettings, AppConfig
│   └── manager.cj           # ConfigManager：JSON 配置读写、API Key 管理
├── models/
│   ├── types.cj             # 数据模型：ChatMessage, ChatRequest, ConversationHistory
│   ├── base.cj              # BaseChatModel 接口
│   ├── factory.cj           # ModelFactory 模型工厂
│   ├── kimi.cj              # KimiModel 实现（Moonshot AI）
│   ├── glm.cj               # GlmModel 实现（智谱 AI）
│   └── minimax.cj           # MinimaxModel 实现（MiniMax，含 GroupId）
├── stream/
│   ├── queue.cj             # CharQueue：线程安全字符缓冲队列
│   └── engine.cj            # StreamEngine：自适应流式显示引擎
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

首次运行时，程序会自动在可执行文件目录生成 `config.json` 配置文件。之后可以直接编辑该文件配置 API Key，或在 REPL 中输入。

### 模拟测试（无需真实 API Key）

```bash
# 使用 Python 模拟服务器进行自动化测试（10 项测试）
python3 test_aichat.py
```

## 交互命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助信息 |
| `/switch <model>` | 切换模型（kimi/glm/minimax） |
| `/status` | 显示当前状态（模型、历史、Key） |
| `/clear` | 清空对话历史 |
| `/exit` | 退出程序 |

## 配置文件

程序首次运行时自动生成 `config.json`，格式如下：

```json
{
  "default_model": "kimi",
  "models": {
    "kimi": { "api_key": "", "base_url": "https://api.moonshot.cn/v1" },
    "glm": { "api_key": "", "base_url": "https://open.bigmodel.cn/api/paas/v4" },
    "minimax": { "api_key": "", "base_url": "https://api.minimax.chat/v1", "group_id": "" }
  },
  "stream_settings": {
    "base_interval_ms": 20,
    "burst_threshold": 50,
    "catchup_interval_ms": 5
  }
}
```

## 环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `KIMI_API_KEY` | Kimi（月之暗面）API 密钥 | `sk-xxxxxx` |
| `GLM_API_KEY` | GLM（智谱 AI）API 密钥 | `xxxxxx.xxxxxx` |
| `MOCK_API_URL` | 自定义 API URL（测试用） | `http://localhost:8080/v1` |

环境变量优先级高于 `config.json` 中的配置。

## 教程对应关系

| 章节 | 核心概念 | 在项目中的体现 |
|------|---------|---------------|
| 01 | main、变量、字符串插值 | 程序入口、启动横幅 |
| 02 | 类型系统、控制流 | 命令解析逻辑 |
| 03 | 函数、闭包、管道运算符 | SSE 回调处理 |
| 04 | struct/class | ChatMessage、ModelConfig |
| 05 | enum、Option、模式匹配 | ModelFactory match 分发、命令系统 |
| 06 | interface、extend | BaseChatModel 抽象 |
| 07 | ArrayList、HashMap、泛型 | ConversationHistory、AppConfig |
| 08 | 异常处理 | ConfigError、网络错误恢复 |
| 09 | spawn、Future、Mutex | CharQueue、StreamEngine |
| 10 | stdx HTTP/TLS/JSON | KimiModel/GlmModel/MinimaxModel 网络调用 |

