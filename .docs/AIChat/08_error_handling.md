# 08. 错误处理：健壮的配置管理

> 程序崩溃不是因为出了错，而是因为没有预料到会出错。优雅的错误处理让 AIChatPro 在 API Key 缺失、网络超时、配置文件损坏时，都能从容应对，而不是直接退出。

## 本章目标

*   掌握 `try/catch/finally` 基本语法。
*   定义自定义异常类（继承 `Exception`）。
*   理解 `Option<T>` 与异常的适用场景边界。
*   使用多重 `catch` 精确处理不同错误类型。
*   构建 AIChatPro 的 `ConfigManager` 配置管理器。

---

## 1. 异常基础

仓颉使用 `try/catch/finally` 处理运行时错误。`throw` 抛出异常，`catch` 捕获并处理。

### 1.1 基本结构

<!-- check:run -->
```cangjie
func divide(a: Int64, b: Int64): Int64 {
    if (b == 0) {
        throw Exception("除数不能为零")
    }
    return a / b
}

main() {
    // 正常情况
    try {
        let result = divide(10, 2)
        println("10 / 2 = ${result}")
    } catch (e: Exception) {
        println("错误: ${e.message}")
    }

    // 触发异常
    try {
        let result = divide(10, 0)
        println("结果: ${result}")
    } catch (e: Exception) {
        println("捕获异常: ${e.message}")
    }

    println("程序继续运行")
}
```

<!-- expected_output:
10 / 2 = 5
捕获异常: 除数不能为零
程序继续运行
-->

### 1.2 finally 块

`finally` 中的代码无论是否发生异常都会执行，适合释放资源：

<!-- check:run -->
```cangjie
func riskyOperation(succeed: Bool): String {
    println("操作开始")
    try {
        if (!succeed) {
            throw Exception("操作失败")
        }
        return "成功结果"
    } catch (e: Exception) {
        println("捕获: ${e.message}")
        return "默认结果"
    } finally {
        println("清理资源（总是执行）")
    }
}

main() {
    println("=== 成功路径 ===")
    let r1 = riskyOperation(true)
    println("返回值: ${r1}")

    println("=== 失败路径 ===")
    let r2 = riskyOperation(false)
    println("返回值: ${r2}")
}
```

<!-- expected_output:
=== 成功路径 ===
操作开始
清理资源（总是执行）
返回值: 成功结果
=== 失败路径 ===
操作开始
捕获: 操作失败
清理资源（总是执行）
返回值: 默认结果
-->

---

## 2. 自定义异常

继承 `Exception` 可以定义带有语义的自定义异常，让错误处理更精确。

### 2.1 基本自定义异常

<!-- check:run -->
```cangjie
class ConfigError <: Exception {
    public init(msg: String) {
        super(msg)
    }
}

class ApiKeyNotFoundError <: Exception {
    let modelName: String

    public init(modelName: String) {
        super("API Key not found for model: ${modelName}")
        this.modelName = modelName
    }
}

class InvalidModelError <: Exception {
    let modelName: String

    public init(modelName: String) {
        super("Invalid model name: '${modelName}'")
        this.modelName = modelName
    }
}

func validateModelName(name: String): Unit {
    let valid = ["kimi", "glm", "minimax"]
    for (m in valid) {
        if (m == name) { return }
    }
    throw InvalidModelError(name)
}

main() {
    // 测试 ConfigError
    try {
        throw ConfigError("配置文件格式错误")
    } catch (e: ConfigError) {
        println("配置错误: ${e.message}")
    }

    // 测试 ApiKeyNotFoundError
    try {
        throw ApiKeyNotFoundError("kimi")
    } catch (e: ApiKeyNotFoundError) {
        println("API Key 缺失, 模型: ${e.modelName}")
        println("错误信息: ${e.message}")
    }

    // 测试 InvalidModelError
    try {
        validateModelName("gpt-4")
    } catch (e: InvalidModelError) {
        println("模型无效: ${e.modelName}")
    }
}
```

<!-- expected_output:
配置错误: 配置文件格式错误
API Key 缺失, 模型: kimi
错误信息: API Key not found for model: kimi
模型无效: gpt-4
-->

### 2.2 异常层次结构

可以建立异常层次，用父类捕获所有子类异常：

<!-- check:run -->
```cangjie
open class AppError <: Exception {
    public init(msg: String) { super(msg) }
}

open class NetworkError <: AppError {
    let statusCode: Int64
    public init(code: Int64) {
        super("Network error: HTTP ${code}")
        this.statusCode = code
    }
}

class TimeoutError <: NetworkError {
    public init() { super(408) }
}

func simulateRequest(scenario: Int64): Unit {
    match (scenario) {
        case 1 => throw TimeoutError()
        case 2 => throw NetworkError(500)
        case 3 => throw AppError("未知应用错误")
        case _ => println("请求成功")
    }
}

main() {
    for (s in 0..4) {
        try {
            simulateRequest(s)
        } catch (e: TimeoutError) {
            println("超时 (HTTP ${e.statusCode}): ${e.message}")
        } catch (e: NetworkError) {
            println("网络错误 (HTTP ${e.statusCode}): ${e.message}")
        } catch (e: AppError) {
            println("应用错误: ${e.message}")
        }
    }
}
```

<!-- expected_output:
请求成功
超时 (HTTP 408): Network error: HTTP 408
网络错误 (HTTP 500): Network error: HTTP 500
应用错误: 未知应用错误
-->

---

## 3. Option 与错误处理

`Option<T>` 适合表达"值可能不存在"——这不是错误，只是正常的缺失状态。异常则适合表达"预期之外的情况"。

### 3.1 何时用 Option，何时用异常

<!-- check:run -->
```cangjie
import std.collection.HashMap

class ConfigStore {
    private let data: HashMap<String, String> = HashMap<String, String>()

    public func set(key: String, value: String): Unit {
        data.add(key, value)
    }

    // Option：键可能不存在，这是正常情况
    public func get(key: String): ?String {
        data.get(key)
    }

    // 异常：如果调用者"保证"这个键存在，缺失就是错误
    public func require(key: String): String {
        let val = data.get(key)
        if (let Some(v) <- val) {
            return v
        }
        throw Exception("必需的配置项缺失: ${key}")
    }
}

main() {
    let store = ConfigStore()
    store.set("api_url", "https://api.example.com")

    // Option 风格：优雅降级
    let url = store.get("api_url") ?? "http://localhost:8080"
    let timeout = store.get("timeout") ?? "30"
    println("URL: ${url}")
    println("超时: ${timeout} 秒")

    // 带 if-let 的 Option 处理
    if (let Some(key) <- store.get("api_key")) {
        println("API Key: ${key}")
    } else {
        println("API Key 未设置，请先配置")
    }

    // 异常风格：调用方保证此键存在
    try {
        let required = store.require("database_url")
        println("数据库: ${required}")
    } catch (e: Exception) {
        println("启动失败: ${e.message}")
    }
}
```

<!-- expected_output:
URL: https://api.example.com
超时: 30 秒
API Key 未设置，请先配置
启动失败: 必需的配置项缺失: database_url
-->

### 3.2 Option 链式操作

`Option` 的真正威力在于可以"链式"组合：`??` 运算符可以串联多个可选值，`?.` 可以对 `Option` 内的值直接调用方法。

`Int64.parse()` 来自 `std.convert` 包，可以将字符串解析为整数，解析失败时抛出异常：

<!-- check:run -->
```cangjie
import std.collection.HashMap
import std.convert.*

func parsePort(portStr: ?String): Int64 {
    // Option 链：先检查是否存在，再解析
    if (let Some(s) <- portStr) {
        try {
            return Int64.parse(s)
        } catch (_: Exception) {
            return 8080
        }
    }
    return 8080
}

main() {
    let configs = HashMap<String, String>()
    configs.add("port", "3000")
    configs.add("bad_port", "not_a_number")

    println("端口 (有效): ${parsePort(configs.get("port"))}")
    println("端口 (无效): ${parsePort(configs.get("bad_port"))}")
    println("端口 (缺失): ${parsePort(configs.get("missing"))}")

    // ?? 运算符链
    let host = configs.get("host") ?? configs.get("fallback_host") ?? "127.0.0.1"
    println("主机: ${host}")
}
```

<!-- expected_output:
端口 (有效): 3000
端口 (无效): 8080
端口 (缺失): 8080
主机: 127.0.0.1
-->

---

## 4. 多重捕获

多个 `catch` 子句按顺序匹配，应将更具体的异常放在前面：

<!-- check:run -->
```cangjie
class ConfigError <: Exception {
    public init(msg: String) { super(msg) }
}
class NetworkError <: Exception {
    public init(msg: String) { super(msg) }
}
class AuthError <: Exception {
    public init(msg: String) { super(msg) }
}

func processRequest(errorType: Int64): String {
    match (errorType) {
        case 1 => throw ConfigError("配置无效")
        case 2 => throw NetworkError("连接超时")
        case 3 => throw AuthError("认证失败，请检查 API Key")
        case _ => return "处理成功"
    }
}

func safeProcess(errorType: Int64): String {
    try {
        return processRequest(errorType)
    } catch (e: ConfigError) {
        return "配置错误: ${e.message}"
    } catch (e: AuthError) {
        return "认证错误: ${e.message}"
    } catch (e: NetworkError) {
        return "网络错误: ${e.message}"
    } catch (e: Exception) {
        return "未知错误: ${e.message}"
    }
}

main() {
    for (i in 0..5) {
        println("场景 ${i}: ${safeProcess(i)}")
    }
}
```

<!-- expected_output:
场景 0: 处理成功
场景 1: 配置错误: 配置无效
场景 2: 网络错误: 连接超时
场景 3: 认证错误: 认证失败，请检查 API Key
场景 4: 处理成功
-->

---

## 5. 配置管理器

将以上知识整合，构建 AIChatPro 的 `ConfigManager`。

### 5.1 完整实现（内存版）

<!-- check:run -->
```cangjie
import std.collection.HashMap

class ConfigError <: Exception {
    public init(msg: String) { super(msg) }
}

class ConfigManager {
    private let apiKeys: HashMap<String, String> = HashMap<String, String>()
    private let baseUrls: HashMap<String, String> = HashMap<String, String>()
    private var currentModel: String = "kimi"

    public init() {
        // 预置默认 URL
        baseUrls.add("kimi", "https://api.moonshot.cn/v1")
        baseUrls.add("glm", "https://open.bigmodel.cn/api/paas/v4")
        baseUrls.add("minimax", "https://api.minimax.chat/v1")
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

    public func hasApiKey(model: String): Bool {
        let key = apiKeys.get(model) ?? ""
        return !key.isEmpty()
    }

    public func getBaseUrl(model: String): String {
        baseUrls.get(model) ?? "https://api.example.com/v1"
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

    public func validate(): Unit {
        if (!hasApiKey(currentModel)) {
            throw ConfigError("当前模型 '${currentModel}' 的 API Key 未配置")
        }
    }

    public func summary(): String {
        let keyStatus = if (hasApiKey(currentModel)) { "✓ 已配置" } else { "✗ 未配置" }
        return "当前模型: ${currentModel} | API Key: ${keyStatus} | URL: ${getBaseUrl(currentModel)}"
    }
}

main() {
    let config = ConfigManager()

    // 正常配置流程
    try {
        config.setApiKey("kimi", "sk-test-abc123")
        println("✓ API Key 已设置")
        println(config.summary())
    } catch (e: ConfigError) {
        println("配置失败: ${e.message}")
    }

    // 切换模型
    println("---切换模型---")
    try {
        config.setCurrentModel("glm")
        println("切换成功: ${config.getCurrentModel()}")
        println(config.summary())
    } catch (e: ConfigError) {
        println("切换失败: ${e.message}")
    }

    // 切换到不支持的模型
    try {
        config.setCurrentModel("gpt-4")
    } catch (e: ConfigError) {
        println("预期错误: ${e.message}")
    }

    // 设置空 API Key
    try {
        config.setApiKey("kimi", "")
    } catch (e: ConfigError) {
        println("预期错误: ${e.message}")
    }

    // 校验配置
    println("---校验---")
    config.setCurrentModel("kimi")
    try {
        config.validate()
        println("Kimi 配置有效")
    } catch (e: ConfigError) {
        println("校验失败: ${e.message}")
    }

    config.setCurrentModel("glm")
    try {
        config.validate()
        println("GLM 配置有效")
    } catch (e: ConfigError) {
        println("校验失败: ${e.message}")
    }
}
```

<!-- expected_output:
✓ API Key 已设置
当前模型: kimi | API Key: ✓ 已配置 | URL: https://api.moonshot.cn/v1
---切换模型---
切换成功: glm
当前模型: glm | API Key: ✗ 未配置 | URL: https://open.bigmodel.cn/api/paas/v4
预期错误: 不支持的模型: 'gpt-4'，可选: kimi, glm, minimax
预期错误: API Key 不能为空 (model: kimi)
---校验---
Kimi 配置有效
校验失败: 当前模型 'glm' 的 API Key 未配置
-->

### 5.2 带文件加载的 ConfigManager（编译检查）

实际项目中，ConfigManager 需要从文件或环境变量加载配置：

<!-- check:build_only -->
```cangjie
import std.collection.HashMap
import std.fs.*
import std.env.*

class ConfigError <: Exception {
    public init(msg: String) { super(msg) }
}

class ConfigManager {
    private let apiKeys: HashMap<String, String> = HashMap<String, String>()
    private let baseUrls: HashMap<String, String> = HashMap<String, String>()
    private var currentModel: String = "kimi"

    public init() {
        baseUrls.add("kimi", "https://api.moonshot.cn/v1")
        baseUrls.add("glm", "https://open.bigmodel.cn/api/paas/v4")
        baseUrls.add("minimax", "https://api.minimax.chat/v1")
        loadFromEnv()
    }

    private func loadFromEnv(): Unit {
        // 从环境变量加载 API Key
        let kimiKey = getEnv("KIMI_API_KEY") ?? ""
        if (!kimiKey.isEmpty()) { apiKeys.add("kimi", kimiKey) }

        let glmKey = getEnv("GLM_API_KEY") ?? ""
        if (!glmKey.isEmpty()) { apiKeys.add("glm", glmKey) }
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
        baseUrls.get(model) ?? "https://api.example.com/v1"
    }

    public func getCurrentModel(): String { currentModel }

    public func setCurrentModel(name: String): Unit {
        let valid = ["kimi", "glm", "minimax"]
        var found = false
        for (m in valid) {
            if (m == name) { found = true; break }
        }
        if (!found) {
            throw ConfigError("不支持的模型: '${name}'")
        }
        currentModel = name
    }

    public func hasApiKey(model: String): Bool {
        let key = apiKeys.get(model) ?? ""
        return !key.isEmpty()
    }

    public func validate(): Unit {
        if (!hasApiKey(currentModel)) {
            throw ConfigError("当前模型 '${currentModel}' 的 API Key 未配置")
        }
    }

    public func getBaseUrl(key: String, default!: String): String {
        baseUrls.get(key) ?? default
    }
}

func getEnv(key: String): ?String {
    None // 占位，实际用 std.env 模块
}

main() {
    let config = ConfigManager()
    config.setApiKey("kimi", "sk-placeholder")
    try {
        config.validate()
        println("配置加载成功: ${config.getCurrentModel()}")
    } catch (e: ConfigError) {
        println("配置错误: ${e.message}")
    }
}
```

---

## 工程化提示

*   **异常 vs Option 选择原则**：
    *   `Option<T>` — 值可能不存在，且这是**预期情况**（如查字典没找到）。
    *   `Exception` — 违反了函数的**前置条件**（如传入了空 API Key，调用方有责任避免）。
*   **异常粒度**：`ConfigError` 比 `Exception("config: xxx")` 好，因为调用方可以只捕获 `ConfigError` 而不影响其他异常。
*   **不要吞异常**：`catch (e: Exception) { }` 会掩盖所有错误。至少记录日志，或重新抛出更有意义的异常。
*   **finally 的保证**：文件、网络连接等外部资源应在 `finally` 中关闭，即使发生异常也能正确释放。

---

## 实践挑战

1.  为 `ConfigManager` 添加 `listConfiguredModels(): ArrayList<String>` 方法，返回已配置 API Key 的模型列表。
2.  定义一个 `RateLimitError <: Exception`，添加 `retryAfterSeconds: Int64` 字段，模拟 API 限流响应处理。
3.  思考：如果某个操作可能抛出多种异常，应如何设计一个 `Result<T, E>` 枚举（类似 Rust 的 Result 类型）来避免异常？用仓颉代码实现它。
