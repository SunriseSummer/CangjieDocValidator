# 第八章：配置加载器 (IO 与异常)

> 硬编码配置是架构的大忌。我们需要从文件系统读取 `config.json` 或 `.env` 文件，并优雅地处理文件不存在或格式错误的情况，保障服务可以启动。

## 本章目标

*   理解配置加载的基本流程与风险点。
*   学会使用异常捕获提供降级策略。
*   建立"配置可覆盖、可回退"的工程习惯。

将端口号、数据库地址、日志级别等参数直接写死在代码中（硬编码），是软件工程的反模式。一旦需要更换数据库地址，就必须修改代码、重新编译、重新部署，代价极高。更糟的是，如果数据库密码硬编码在代码里，版本控制系统会永久记录这个敏感信息，造成安全漏洞。

良好的配置管理遵循**十二要素应用（Twelve-Factor App）**原则：配置与代码分离，通过文件（`config.json`、`.env`）或环境变量注入。同时，配置加载必须是**容错的**——文件缺失或格式错误时，服务应使用安全的默认值继续启动（**降级策略**），而不是直接崩溃。这在生产环境中至关重要：一个因配置文件路径错误而拒绝启动的服务，远不如一个用默认配置启动并发出警告日志的服务。

## 1. 模拟文件读取 (File IO)

假设我们有一个读取文件的底层函数。

在真实的文件系统操作中，"文件不存在"、"权限不足"、"磁盘损坏"等情况随时可能发生。仓颉使用**异常（Exception）**机制来传递这类错误信号：当错误发生时，抛出一个包含描述信息的 `Exception` 对象，中断当前执行流，将错误"向上冒泡"直到被 `try-catch` 捕获。

<!-- check:run project=config_loader -->
```cangjie
// 模拟 std.fs 的读取
func readFileContent(path: String): String {
    if (path == "config.json") {
        return "{\"port\": 8080, \"db\": \"mysql\"}"
    } else {
        // 抛出异常：文件未找到
        throw Exception("FileNotFound: ${path}")
    }
}
```

## 2. 安全配置加载 (Try-Catch)

`try-catch` 块是异常处理的核心语法。`try` 块中的代码如果抛出异常，会立即跳转到对应的 `catch` 块，`try` 块中异常行之后的代码不会执行。这使得"正常流程"和"错误处理"清晰分离，避免了在每一行可能出错的代码后都写 `if error != nil` 的繁琐模式。

**降级策略（Graceful Degradation）**是生产级服务的标配：当主要功能失败时，自动切换到可接受的备选方案，而不是让整个系统崩溃。配置加载的降级策略就是"文件加载失败 → 使用内置默认值"，确保服务在任何情况下都能启动。

<!-- check:run project=config_loader -->
```cangjie
struct AppConfig {
    var port: Int64 = 80
    var dbType: String = "sqlite"

    public func printInfo() {
        println("配置加载: Port=${port}, DB=${dbType}")
    }
}

func loadConfig(path: String): AppConfig {
    println("正在加载配置: ${path} ...")

    try {
        let content = readFileContent(path)
        println("读取成功: ${content}")
        // 这里应该有 JSON 解析逻辑，简化为模拟赋值
        var config = AppConfig()
        config.port = 8080
        config.dbType = "mysql"
        return config

    } catch (e: Exception) {
        println("配置加载失败: ${e.message}")
        println("回退到默认配置")
        return AppConfig() // 返回默认值
    }
}

main() {
    // 场景 1: 文件存在
    let conf1 = loadConfig("config.json")
    conf1.printInfo()

    println("----------------")

    // 场景 2: 文件不存在
    let conf2 = loadConfig("missing.yaml")
    conf2.printInfo()
}
```

<!-- expected_output:
正在加载配置: config.json ...
读取成功: {"port": 8080, "db": "mysql"}
配置加载: Port=8080, DB=mysql
----------------
正在加载配置: missing.yaml ...
配置加载失败: FileNotFound: missing.yaml
回退到默认配置
配置加载: Port=80, DB=sqlite
-->

**代码解析：**

- `struct AppConfig` 的字段使用默认值（`port = 80`，`dbType = "sqlite"`）：仓颉 `struct` 支持字段默认值，`AppConfig()` 无参构造时自动使用这些默认值，无需额外的"默认配置工厂函数"。
- `try { ... } catch (e: Exception) { ... }`：`try` 块包裹了可能失败的文件读取和解析逻辑；一旦 `readFileContent` 抛出异常，立即跳到 `catch` 块，`try` 块中的后续行（包括 `return config`）不会执行。
- `e.message`：访问异常的描述信息（就是 `throw Exception("FileNotFound: ...")` 中传入的字符串），输出到日志供排查。
- `return AppConfig()`：在 `catch` 块中返回默认配置，是降级策略的代码体现——异常被"吸收"而非向上传播，调用方（`main`）无感知地获得了一个可用的配置对象。

**💡 核心要点**

- **硬编码配置 = 反模式**：端口、数据库地址、密钥等配置应从外部文件或环境变量注入，与代码分离。
- **异常 vs 返回值**：仓颉用 `throw/catch` 处理"意外情况"（文件不存在），用正常返回值处理"预期情况"（配置已加载）。两者分工明确，避免混淆。
- **降级策略（Graceful Degradation）**：关键操作失败时使用安全默认值继续运行，比直接崩溃更具鲁棒性。
- **`struct` 字段默认值**：为配置结构体的每个字段提供合理的默认值，简化默认配置的创建。

## 工程化提示

*   配置读取应区分"缺失"与"格式错误"，并提供清晰提示。
*   生产环境建议支持多级配置覆盖（默认、环境变量、文件）。
*   JSON 解析需使用可靠库，本例只演示结构。

## 小试身手

1. 为 `AppConfig` 增加 `logLevel` 字段并在输出中展示。
2. 添加一个 `loadConfigOrDefault` 函数，显式返回默认配置。
