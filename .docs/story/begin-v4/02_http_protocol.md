# 第二章：HTTP 协议封装 (结构体与枚举)

> HTTP 协议本质上是文本的交互。我们需要定义一套数据结构来描述"请求"和"响应"，这是框架通信的通用语言，也是中间件链的核心载体。

## 本章目标

*   学会用枚举表达有限集合的协议常量。
*   理解请求/响应模型的数据结构设计。
*   认识上下文对象在框架中的作用。

HTTP（HyperText Transfer Protocol）是互联网上最广泛使用的应用层协议。它的工作方式非常直观：客户端发送一条**请求消息**，服务器处理后返回一条**响应消息**。每条请求消息都携带三个关键要素：**方法**（做什么操作）、**路径**（操作哪个资源）以及**请求体**（携带什么数据）。

为了在代码中准确表达这套协议，我们需要精心设计数据结构。数据结构设计的质量直接决定了框架的可维护性与扩展性——它就像建筑的地基，后续所有的路由、中间件、控制器都将建立在这个基础之上。

## 1. 请求方法 (Enum)

HTTP 方法（GET, POST 等）是有限且固定的，非常适合使用枚举 (`enum`)。

HTTP 标准规定了一组固定的方法词汇：`GET` 用于获取资源，`POST` 用于创建资源，`PUT` 用于更新资源，`DELETE` 用于删除资源。这组词汇的特点是**有限且封闭**——不会凭空出现一个新的"JUMP"方法。

枚举（`enum`）天然适合表达这类有限集合。相比使用字符串（`"GET"`、`"POST"`），枚举的优势有三：首先，编译器会进行**穷举性检查**，确保你没有遗漏任何情况；其次，枚举值是**类型安全**的，不会出现拼写错误（例如把 `"GETT"` 误传入）；最后，`match` 语句能与枚举完美配合，让逻辑分支一目了然。

<!-- check:run project=http_protocol -->
```cangjie
enum HttpMethod {
    | GET
    | POST
    | PUT
    | DELETE
}

// 扩展枚举，增加实用方法
extend HttpMethod {
    func toString(): String {
        match (this) {
            case GET => "GET"
            case POST => "POST"
            case PUT => "PUT"
            case DELETE => "DELETE"
        }
    }
}
```

通过 `extend` 语法，我们为枚举附加了 `toString()` 方法，使其能够转换为人类可读的字符串，方便日志输出与调试。这体现了仓颉"数据与行为可分离定义"的灵活性。

## 2. 请求与响应 (Class)

请求对象需要在中间件链中传递和修改，适合用引用类型 (`class`)。

在 Web 框架中，一个请求从被接收到返回响应，会经历多个处理层（中间件、路由、业务逻辑）。每一层都可能读取或修改请求上下文（如添加用户身份、修改响应状态码）。这就要求上下文对象在整个处理链中是**同一份引用**——任何一层的修改都应对其他层可见。

这正是选择 `class`（引用类型）而非 `struct`（值类型）的根本原因：`struct` 在传递时会被**复制**，每层都持有独立副本，修改不会互相影响；而 `class` 传递的是**引用**，所有层共享同一个对象，中间件对 `statusCode` 或 `responseBody` 的修改会立即反映给其他层。

<!-- check:run project=http_protocol -->
```cangjie
class Context {
    let path: String
    let method: HttpMethod
    var responseBody: String = ""
    var statusCode: Int64 = 200

    public init(path: String, method: HttpMethod) {
        this.path = path
        this.method = method
    }

    // 辅助方法：发送响应
    public func string(content: String) {
        this.responseBody = content
    }

    public func json(json: String) {
        this.responseBody = json
        // 这里可以设置 Content-Type 头
    }
}

main() {
    // 模拟接收到一个 GET /home 请求
    let ctx = Context("/home", HttpMethod.GET)

    println("收到请求: ${ctx.method.toString()} ${ctx.path}")

    // 业务逻辑处理
    ctx.string("<h1>Hello Cangjie Web</h1>")

    println("响应内容: ${ctx.responseBody}")
}
```

<!-- expected_output:
收到请求: GET /home
响应内容: <h1>Hello Cangjie Web</h1>
-->

**代码解析：**

- `let path` / `let method`：用 `let` 声明为不可变字段，确保请求的路径和方法在创建后不会被意外修改，体现了"不变性优先"原则。
- `var responseBody` / `var statusCode`：用 `var` 声明为可变字段，允许业务逻辑层填充响应内容和状态码。
- `func string(content: String)`：封装了"设置文本响应"的操作，命名参考了 Go 语言的 gin 框架风格，使调用代码更具语义性。
- `ctx.method.toString()`：调用我们在第一个代码块中通过 `extend` 为枚举附加的方法，两段代码在同一 project 中协同工作。

**💡 核心要点**

- **枚举 vs 字符串**：用枚举表达有限集合，获得编译期类型检查和穷举保证，远优于裸字符串常量。
- **class vs struct**：需要跨层共享和修改的数据对象（如请求上下文）应使用 `class`（引用语义）；独立、不可变的数据快照适合 `struct`（值语义）。
- **`extend` 扩展**：仓颉允许在类型定义之外为其添加方法，有助于将数据定义与行为逻辑分离管理。
- **上下文对象（Context）**：框架设计中的核心模式，它承载了一次请求的完整生命周期信息，是中间件链和业务逻辑的共享载体。

## 工程化提示

*   协议字段的命名要与标准一致，避免歧义。
*   `Context` 应控制可变状态的访问路径，防止被随意修改。
*   序列化与内容类型需在真实项目中严格处理，本例仅示意。

## 小试身手

1. 为 `HttpMethod` 增加 `PATCH` 分支并补充转换逻辑。
2. 在 `Context` 中加入 `headers` 字段，并提供 `setHeader` 方法。
