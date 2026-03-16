# 08. 错误处理：健壮的配置管理

> 程序崩溃不是因为出了错，而是因为没有预料到会出错。优雅的错误处理让 AIChatPro 在 API Key 缺失、网络超时、配置文件损坏时，都能从容应对，而不是直接退出。

在真实的软件工程中，"正常路径"往往只占代码的一小部分——大量的工程精力花在处理各种边界情况和异常状态上。一个 API 调用可能因为网络波动而超时，一个配置文件可能被用户误删，一个必需的环境变量可能根本没有设置。如果我们的代码对这些情况毫无准备，用户看到的就是一条冷冰冰的崩溃堆栈。

本章将带你从零开始构建 AIChatPro 的错误处理体系。我们先学习仓颉的异常机制基础，再逐步引入自定义异常、`Option` 类型和多重捕获，最终将这些技术整合到一个完整的 `ConfigManager` 配置管理器中。

学完这一章后，你将能够为自己的程序设计出清晰的错误处理策略——什么时候该抛异常、什么时候该返回 `None`、什么时候该用默认值兜底，都将有据可依。

## 本章目标

*   掌握 `try/catch/finally` 基本语法，理解异常的抛出与捕获机制。
*   定义自定义异常类（继承 `Exception`），为错误赋予业务语义。
*   理解 `Option<T>` 与异常的适用场景边界，学会根据语义选择正确的错误表达方式。
*   使用多重 `catch` 精确处理不同错误类型，实现差异化的错误恢复策略。
*   构建 AIChatPro 的 `ConfigManager` 配置管理器，综合运用所有技术。

---

## 1. 异常基础

在没有异常机制的语言中（比如 C），错误通常通过返回值来传递——函数返回一个特殊值（如 `-1` 或 `NULL`）表示失败。这种方式的问题在于：调用者很容易忘记检查返回值，错误就这样被无声地忽略了。

仓颉使用 `try/catch/finally` 处理运行时错误——这是一种"结构化"的错误传播方式：当函数内部遇到无法处理的情况时，通过 `throw` 把异常"抛"给调用者；调用者则用 `catch` 来"接住"它并决定后续行为。异常不会被意外忽略——如果没有人捕获它，程序会终止并打印出完整的错误信息和调用栈，让问题无处遁形。这种机制让正常逻辑和错误处理逻辑自然分离，代码更加清晰。

### 1.1 基本结构

最核心的模式非常直观：`try` 块包裹可能出错的代码，`catch` 块定义出错后的应对策略。关键在于——即使发生了异常，程序也不会崩溃，而是从 `catch` 块之后继续执行。

下面我们用一个除法函数来演示：当除数为零时抛出异常，调用方在 `catch` 中处理这个错误，然后程序正常继续。

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

注意最后一行"程序继续运行"——这正是异常处理的核心价值。没有 `try/catch`，除以零的那一刻程序就终止了；有了它，我们可以优雅地报告问题并继续执行后续逻辑。在 AIChatPro 中，这意味着一次 API 调用失败不会导致整个应用崩溃——我们可以向用户展示友好的错误提示，同时保持其他功能正常运转。

`try/catch` 解决了"出错后怎么办"的问题，但还有一个场景没有覆盖：如果我们在 `try` 块中打开了一个文件，无论后续操作成功还是失败，文件都必须关闭。接下来的 `finally` 块正是为此设计的。

### 1.2 finally 块

现实中的程序经常需要管理外部资源：打开了文件要关闭，建立了网络连接要释放，获取了锁要归还。如果异常发生在资源释放之前，资源就会泄漏——文件描述符耗尽、连接池被占满，最终导致系统不可用。`finally` 块解决了这个问题——无论 `try` 中是正常返回还是异常跳出，`finally` 中的代码都**保证执行**。

可以把 `finally` 想象成一个"保险箱回锁"机制：不管你在保险箱前做了什么操作，离开时一定会自动上锁。

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

观察输出可以发现：无论成功还是失败，"清理资源（总是执行）"都会打印。在实际项目中，这里就是关闭文件句柄、释放数据库连接的地方。养成"申请资源就写 `finally`"的习惯，是避免资源泄漏的最佳实践。

至此，我们已经掌握了异常处理的基本工具箱：`try` 尝试执行、`catch` 捕获处理、`finally` 善后清理。但在大型项目中，仅靠通用的 `Exception` 类型是不够的——当所有错误都是同一个类型时，`catch` 块无法区分"这是配置问题"还是"这是网络问题"。接下来，我们将通过自定义异常来解决这个问题。

---

## 2. 自定义异常

通用的 `Exception` 虽然能用，但在一个稍具规模的项目中，所有错误都抛 `Exception` 就像所有函数都叫 `doSomething` 一样——调用者根本无法区分"配置错误"和"网络超时"到底发生了哪个。

自定义异常通过继承 `Exception` 来为错误赋予**语义**：`ConfigError` 表示配置问题，`ApiKeyNotFoundError` 表示密钥缺失。调用方可以精准捕获自己关心的错误类型，而让其他异常继续向上传播。打个比方，这就像是给不同的快递包裹贴上不同颜色的标签——收件室可以一眼看出哪些是加急件、哪些是普通件，而不需要打开每个包裹才能决定处理方式。

### 2.1 基本自定义异常

让我们为 AIChatPro 定义三个业务相关的异常类：

*   **`ConfigError`** — 通用的配置错误，例如配置文件格式不对、必需字段缺失等。
*   **`ApiKeyNotFoundError`** — 专门表示某个模型的 API Key 未配置。它额外携带 `modelName` 字段，这样错误处理代码就可以知道"哪个模型的 Key 缺了"，进而引导用户去正确的地方补充配置。
*   **`InvalidModelError`** — 表示用户指定了一个不支持的模型名称。同样携带 `modelName`，方便在错误提示中给出具体的无效值。

这种"异常类携带上下文字段"的模式非常实用。试想，如果只抛一个 `Exception("Key not found")`，调用者除了打印消息什么也做不了；但如果抛的是 `ApiKeyNotFoundError("kimi")`，调用者就可以根据 `modelName` 自动跳转到对应模型的配置页面。

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

可以看到，`ConfigError` 被精确捕获而不会干扰其他类型的异常，`ApiKeyNotFoundError` 不仅提供了错误消息，还通过 `e.modelName` 字段暴露了结构化的上下文信息。`validateModelName` 函数则演示了一个常见模式：**在数据进入系统的边界处进行校验**——越早发现无效输入，后续的处理逻辑就越安全。

### 2.2 异常层次结构

当异常类型较多时，扁平地定义一堆互不相关的异常类会让捕获逻辑变得繁琐。更好的做法是建立**层次结构**：让所有网络相关的异常都继承自 `NetworkError`，所有应用级异常都继承自 `AppError`。这样，调用者可以选择捕获精确的子类（"我只想处理超时"），也可以用父类"一网打尽"所有同族异常（"所有网络问题统一重试"）。

仓颉中，父类需要标记为 `open` 才能被继承——这是一种有意的设计，避免不希望被继承的类被随意扩展。`catch` 子句按**从上到下**的顺序匹配，因此要把更具体的子类放在前面——否则父类会先匹配，子类的 `catch` 永远不会执行。

下面的例子构建了一个三层异常体系：`AppError` → `NetworkError` → `TimeoutError`。我们通过模拟不同场景来观察匹配行为：

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

从输出中可以看到：`TimeoutError`（场景 1）被第一个 `catch` 精确捕获，而不是落入更宽泛的 `NetworkError` 分支。这种"从具体到一般"的匹配顺序是异常层次设计的关键原则。

> **设计启示**：在 AIChatPro 中，我们可以让所有与模型调用相关的异常都继承自一个 `ModelError` 基类——超时、限流、认证失败各自是子类。这样，上层业务代码可以用一个 `catch (e: ModelError)` 统一处理所有模型相关的问题，而底层的重试逻辑只关心 `TimeoutError`。层次结构让不同层次的调用者各取所需。

---

## 3. Option 与错误处理

学会了异常机制后，一个自然的问题是：**所有的"没有结果"都应该抛异常吗？** 答案是否定的。

并非所有"没有结果"的情况都是错误。在字典中查一个键、在列表中搜一个元素——找不到是完全正常的事情，不应该触发异常。如果每次 `HashMap.get()` 找不到键都抛一个 `KeyNotFoundException`，那整个代码就会被 `try/catch` 淹没，反而比不用异常更糟糕。

仓颉提供了 `Option<T>`（简写为 `?T`）来优雅地表达这种"值可能不存在"的语义。`Option` 有两种状态：`Some(value)` 表示有值，`None` 表示没有值。编译器会强制你处理 `None` 的情况，从而在编译期就杜绝了"空指针"类的错误。

两者的分界线很清晰：

*   **`Option<T>`** — 值的缺失是**预期中的正常状态**，调用者应该准备好处理 `None`。
*   **`Exception`** — 发生了**违反前置条件的意外情况**，调用者有责任避免但可能失败了。

### 3.1 何时用 Option，何时用异常

下面的 `ConfigStore` 同时提供了两种风格的查询接口，完美体现了这一原则。`get()` 返回 `?String`，适合"键可能不存在"的常见场景——这不是错误，只是一种正常状态。`require()` 抛出异常，适合"这个键必须存在，缺失就是 bug"的场景——调用者明确知道这个键应该在，如果不在，说明有人忘了配置。选择哪种风格取决于调用者的语义期望。

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

上面的代码展示了一个重要的设计模式：**同一个数据源可以同时提供 Option 风格和异常风格的访问接口**。`get()` 配合 `??` 运算符实现优雅降级（找不到就用默认值），而 `require()` 用于那些"绝对不能缺少"的配置项——如果缺失，说明系统状态有严重问题，应该立刻暴露出来。

在 AIChatPro 的实际使用中，`api_url` 这样的配置可以有默认值，缺失不致命，适合 `get() ?? default`；而 `database_url` 如果缺了程序根本无法启动，就应该用 `require()` 让问题在启动阶段立刻暴露。记住这条经验法则：**能优雅降级的用 Option，不能降级的用异常**。

### 3.2 Option 链式操作

`Option` 的真正威力在于可以"链式"组合：`??` 运算符可以串联多个可选值，形成一条"回退链"——依次尝试每个来源，直到找到一个有值的结果。这比嵌套的 `if-else` 判断要简洁得多。

下面的例子中，`Int64.parse()` 来自 `std.convert` 包，可以将字符串解析为整数，解析失败时抛出异常。我们用 `Option` + `try/catch` 的组合来安全地处理"端口号可能不存在，也可能不是合法数字"这两种情况。这种"层层防御"的风格在配置解析中非常典型——每一层都处理自己能处理的问题，无法处理的才交给上层：

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

三种情况——有效端口、格式错误、完全缺失——都被安全地处理，且最终都能返回一个合理的默认值。这种防御式编程风格在配置解析中尤为重要：用户填写的配置文件往往充满各种意外——多了个空格、写错了数字格式、甚至忘了填某个字段。好的配置解析代码应该像一个耐心的翻译官，尽最大努力理解用户的意图，实在理解不了再给出清晰的提示。

`??` 运算符链的模式（`configs.get("host") ?? configs.get("fallback_host") ?? "127.0.0.1"`）在实际项目中非常常见。它建立了一条清晰的"优先级链"：先看主配置，再看备用配置，最后使用硬编码的默认值。这比一层层嵌套 `if-else` 要简洁得多，也更容易维护。

---

## 4. 多重捕获

在前面的例子中，每个 `catch` 只捕获一种异常。但在实际业务中，一个操作往往可能失败出多种不同的原因——网络不通、配置错误、认证过期，每种情况需要不同的应对策略。

当一个操作可能抛出多种不同类型的异常时，我们需要用多个 `catch` 子句来分别处理。就像医院的分诊台——根据症状把患者分配到不同的科室，而不是所有人都去急诊。

多个 `catch` 子句按**声明顺序**依次匹配。第一个类型匹配的子句会被执行，后续子句被跳过。因此，更具体的异常类型应该放在前面，通用的 `Exception` 放在最后作为兜底。如果把 `Exception` 放在第一个，它会匹配一切，后面的子句永远不会执行。

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

在实际的 AIChatPro 中，`safeProcess` 这样的函数会出现在 HTTP 请求处理链中：配置错误提示用户检查设置，认证错误引导用户更新 API Key，网络错误触发自动重试——每种异常对应不同的恢复策略，这就是多重捕获的工程价值。

注意 `safeProcess` 函数的设计：它将"可能抛异常的操作"包裹在 `try/catch` 中，将所有异常路径都转化为正常的返回值。这种"异常转返回值"的包装函数是一个非常实用的模式——它让调用方不需要自己写 `try/catch`，从而保持主逻辑的简洁。在大型项目中，这类函数常常出现在系统边界处（如 HTTP 处理器、消息队列消费者），充当"防线"的角色。

---

## 5. 配置管理器

前面四个小节分别介绍了异常捕获、自定义异常、Option 类型和多重捕获——这些都是错误处理的"零部件"。单独看每个技术都不复杂，但真正的挑战在于：如何将它们有机地组合起来，构建一个既健壮又好用的模块？

现在，是时候把这些技术整合起来，构建一个真正实用的配置管理器了。

AIChatPro 需要管理多个 AI 模型的配置信息：每个模型有自己的 API Key 和接口地址，用户可以在运行时切换当前模型。`ConfigManager` 将承担这项职责——它需要在设置无效 Key 时抛出异常、在查询未配置的 Key 时安全降级、在切换到未知模型时给出清晰的错误提示。

我们将分两步构建这个模块。首先实现最核心的 API Key 存取和查询功能，然后在此基础上添加模型切换和配置校验能力。这种"核心先行，逐步扩展"的构建方式也是实际工程中推荐的迭代开发策略——先确保基础功能正确可靠，再在稳固的地基上添加新能力。

### 5.1 API Key 管理核心

我们先构建 `ConfigManager` 最基础的部分：存储和查询 API Key。这个版本的 `ConfigManager` 只关注一件事——安全地管理 API Key 的存取。

`ConfigError` 作为自定义异常，为配置相关的所有错误提供统一的语义标识。当上层代码看到 `ConfigError` 时，就知道"这是配置问题，需要引导用户检查设置"，而不是"可能是任何类型的错误"。

注意 `setApiKey` 方法中的参数校验——空字符串是一个典型的"违反前置条件"的场景，应该抛出异常而不是默默接受。而 `getApiKey` 和 `hasApiKey` 使用了 `Option` 的 `??` 运算符来优雅处理"键不存在"这种正常情况。

构造函数中预置了三个模型的接口地址。这是一种常见的"约定优于配置"策略——对于已知的服务商，我们提供合理的默认值，用户只需要填写 API Key 即可开始使用，无需关心接口细节。

<!-- check:run -->
```cangjie
import std.collection.HashMap

class ConfigError <: Exception {
    public init(msg: String) { super(msg) }
}

class ConfigManager {
    private let apiKeys: HashMap<String, String> = HashMap<String, String>()
    private let baseUrls: HashMap<String, String> = HashMap<String, String>()

    public init() {
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
}

main() {
    let config = ConfigManager()

    // 正常设置 API Key
    try {
        config.setApiKey("kimi", "sk-test-abc123")
        println("✓ API Key 已设置")
        println("Key 存在: ${config.hasApiKey("kimi")}")
        println("URL: ${config.getBaseUrl("kimi")}")
    } catch (e: ConfigError) {
        println("配置失败: ${e.message}")
    }

    // 空 Key 触发异常
    try {
        config.setApiKey("kimi", "")
    } catch (e: ConfigError) {
        println("预期错误: ${e.message}")
    }

    // 查询未配置的模型——安全降级，不抛异常
    println("GLM Key 存在: ${config.hasApiKey("glm")}")
    println("GLM URL: ${config.getBaseUrl("glm")}")
}
```

<!-- expected_output:
✓ API Key 已设置
Key 存在: true
URL: https://api.moonshot.cn/v1
预期错误: API Key 不能为空 (model: kimi)
GLM Key 存在: false
GLM URL: https://open.bigmodel.cn/api/paas/v4
-->

这段代码体现了本章反复强调的原则：**异常用于前置条件违反（空 Key），Option 用于正常的缺失状态（未配置的模型）**。`hasApiKey` 返回布尔值而不是抛异常，让调用方可以自由决定"未配置"时的后续行为——也许是提示用户配置，也许是跳过该模型，也许是使用备用方案。

同时注意 `getBaseUrl` 的降级策略：如果查询的模型不在预置列表中，它不会报错，而是返回一个通用的默认 URL。这种"尽最大努力提供有用的结果"的设计让调用方的代码更简洁——不需要先检查模型是否存在再获取 URL。

### 5.2 模型切换与配置校验

有了 Key 管理的基础，我们继续为 `ConfigManager` 添加模型切换和整体校验能力。这是完整版的 `ConfigManager`，在前一个版本的基础上增加了三个关键方法：

*   **`setCurrentModel`** — 切换当前使用的 AI 模型。它会校验模型名是否在支持列表中，防止用户误输入一个不存在的模型名。
*   **`validate`** — 全局配置校验。检查当前选中的模型是否已经配置了 API Key，适合在应用启动时调用。
*   **`summary`** — 将配置状态汇总为一行可读的文本，方便在日志中记录当前系统配置。

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
    config.setApiKey("kimi", "sk-test-abc123")
    println(config.summary())

    // 切换到已支持的模型
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

    // 校验配置完整性
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
当前模型: kimi | API Key: ✓ 已配置 | URL: https://api.moonshot.cn/v1
---切换模型---
切换成功: glm
当前模型: glm | API Key: ✗ 未配置 | URL: https://open.bigmodel.cn/api/paas/v4
预期错误: 不支持的模型: 'gpt-4'，可选: kimi, glm, minimax
---校验---
Kimi 配置有效
校验失败: 当前模型 'glm' 的 API Key 未配置
-->

`validate()` 方法展示了一个重要的设计理念——**快速失败（fail-fast）**。与其在实际发送 API 请求时才发现 Key 缺失，不如在启动阶段就主动检查配置完整性。这样，错误信息更加明确（"当前模型 'glm' 的 API Key 未配置"），而不是一个含糊的"401 Unauthorized"网络响应。

回顾这两个代码块，你会发现 `ConfigManager` 的设计综合运用了本章所有的技术：`ConfigError` 自定义异常提供了清晰的错误语义，`??` 运算符优雅地处理可选值的降级，`try/catch` 在每个可能出错的操作点进行防护，而 `validate()` 方法实现了系统级的配置校验。这就是错误处理体系化设计的力量——每一层都各司其职，共同构建起一个健壮的防线。

### 5.3 带文件加载的 ConfigManager（编译检查）

在真实项目中，硬编码的配置只适用于开发环境。生产环境的 `ConfigManager` 需要从环境变量或配置文件中加载敏感信息——API Key 绝不应该出现在源代码中。这不仅是安全最佳实践，也是 [12-Factor App](https://12factor.net/config) 方法论的核心原则之一。

下面的版本展示了如何在构造函数中自动读取环境变量，让配置管理更贴近实际部署场景。它在初始化时自动尝试从 `KIMI_API_KEY` 和 `GLM_API_KEY` 等环境变量加载密钥，用户无需手动调用 `setApiKey`——只要在部署环境中设好变量，应用启动后就能直接使用。

由于环境变量读取依赖运行时环境，这个示例仅做编译检查，不实际执行：

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

回顾本章的内容，我们从最基本的 `try/catch` 出发，一路走到了一个功能完整的 `ConfigManager`。以下几条原则值得在日常开发中反复践行：

*   **异常 vs Option 选择原则**：
    *   `Option<T>` — 值可能不存在，且这是**预期情况**（如查字典没找到）。调用者应该准备好处理 `None`，通常用 `??` 提供默认值或用 `if-let` 分支处理。
    *   `Exception` — 违反了函数的**前置条件**（如传入了空 API Key，调用方有责任避免）。异常表示"这不应该发生"，捕获后需要采取修复措施或向用户报告。
*   **异常粒度**：`ConfigError` 比 `Exception("config: xxx")` 好，因为调用方可以只捕获 `ConfigError` 而不影响其他异常。细粒度的异常类型让多重 `catch` 成为可能，也让代码的意图更加清晰。
*   **不要吞异常**：`catch (e: Exception) { }` 会掩盖所有错误，是最危险的反模式。至少记录日志，或重新抛出更有意义的异常。如果你不确定怎么处理某个异常，最好的选择是不捕获它，让它继续向上传播。
*   **finally 的保证**：文件、网络连接等外部资源应在 `finally` 中关闭，即使发生异常也能正确释放。这是防止资源泄漏的最后一道防线。
*   **快速失败**：在系统启动阶段就调用 `validate()` 检查配置完整性，比在运行时才发现问题要好得多——越早发现错误，修复成本越低。
*   **异常信息要可操作**：`"API Key 不能为空 (model: kimi)"` 比 `"参数无效"` 有用得多。好的错误信息应该告诉用户发生了什么、在哪里发生的、以及如何修复。

---

## 实践挑战

以下挑战帮助你巩固本章所学，并将错误处理思维延伸到更多场景：

1.  为 `ConfigManager` 添加 `listConfiguredModels(): ArrayList<String>` 方法，返回已配置 API Key 的模型列表。提示：遍历 `apiKeys` 的键集合，收集到 `ArrayList` 中返回。
2.  定义一个 `RateLimitError <: Exception`，添加 `retryAfterSeconds: Int64` 字段，模拟 API 限流响应处理。在 `catch` 块中读取 `retryAfterSeconds` 的值，给用户提示"请在 N 秒后重试"。
3.  思考：如果某个操作可能抛出多种异常，应如何设计一个 `Result<T, E>` 枚举（类似 Rust 的 Result 类型）来避免异常？用仓颉代码实现它。这种方式与异常相比，各有什么优劣？
