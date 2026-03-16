# 第三章：路由分发 (流程控制)

> 服务器需要根据 URL 的不同，执行不同的业务逻辑。这就是"路由"。我们将实现一个简单的路由匹配器，理解"路径到处理函数"的映射关系。

## 本章目标

*   理解路由分发在 Web 框架中的职责。
*   学会使用映射结构组织路径与处理函数。
*   认识默认路由与错误响应的处理方式。

路由（Routing）是 Web 框架最核心的功能之一。想象一家大型百货公司：门口的导购员（路由器）根据顾客的需求（URL 路径）引导他们前往不同的楼层和柜台（处理函数）。如果某个柜台不存在，导购员会礼貌地告知"没有这个商品"（404 Not Found）。路由器扮演的正是这个"请求分发员"的角色。

在技术层面，路由器维护着一张**路由表**——本质上是一个从 URL 路径到处理函数的映射字典。当一个请求到来时，路由器在字典中查找对应路径，找到则调用相应处理函数，找不到则返回 404 响应。使用 `HashMap` 实现路由表，查找时间复杂度为 **O(1)**，无论注册了多少条路由，每次分发的速度都是恒定的，这是 Web 框架高性能的重要基础。

## 1. 基础路由逻辑

在很多微框架中，路由本质上就是一个巨大的 `match` 或 `if-else` 结构。

`type Handler = (Context) -> Unit` 这行代码定义了一个**类型别名**，将"接受 Context 参数、无返回值的函数"命名为 `Handler`。类型别名使代码更具可读性——`HashMap<String, Handler>` 比 `HashMap<String, (Context) -> Unit>` 更清晰地表达了"路由表"的意图。这里的 `Handler` 也体现了函数式编程的思想：**函数是一等公民**，可以像普通值一样存储在容器中、传递给其他函数。

路由处理函数通常以 **Lambda 表达式（闭包）** 的形式注册。闭包可以捕获外部变量，这使得处理函数能够访问数据库连接、配置对象等上下文信息，而无需通过参数显式传递。这正是 Web 框架中"依赖注入"思想的轻量级体现。

<!-- check:run -->
```cangjie
import std.collection.*

enum HttpMethod {
    | GET
    | POST
    | PUT
    | DELETE
}

class Context {
    let path: String
    let method: HttpMethod
    var responseBody: String = ""
    var statusCode: Int64 = 200
    public init(path: String, method: HttpMethod) {
        this.path = path
        this.method = method
    }
    public func string(content: String) {
        this.responseBody = content
    }
    public func json(json: String) {
        this.responseBody = json
    }
}

// 定义一个处理函数类型
type Handler = (Context) -> Unit

class Router {
    // 简单路由表：路径 -> 处理函数
    var routes = HashMap<String, Handler>()

    public func add(path: String, handler: Handler) {
        routes[path] = handler
    }

    public func handle(ctx: Context) {
        // 查找路由
        if (routes.contains(ctx.path)) {
            let handler = routes[ctx.path]
            handler(ctx) // 执行业务逻辑
        } else {
            // 404 处理
            ctx.statusCode = 404
            ctx.string("404 Not Found")
        }
    }
}

main() {
    let router = Router()

    // 注册路由
    router.add("/index") { ctx =>
        ctx.string("Welcome to Index Page")
    }

    router.add("/user") { ctx =>
        ctx.json("{\"name\": \"User1\"}")
    }

    // 模拟请求
    let req1 = Context("/index", HttpMethod.GET)
    router.handle(req1)
    println("[${req1.statusCode}] ${req1.responseBody}")

    let req2 = Context("/unknown", HttpMethod.GET)
    router.handle(req2)
    println("[${req2.statusCode}] ${req2.responseBody}")
}
```

<!-- expected_output:
[200] Welcome to Index Page
[404] 404 Not Found
-->

```bash
[200] Welcome to Index Page
[404] 404 Not Found
```

**代码解析：**

- `var routes = HashMap<String, Handler>()`：路由表用 `HashMap` 实现，键为路径字符串，值为对应的处理函数。`HashMap` 的哈希查找保证了 O(1) 的分发速度。
- `router.add("/index") { ctx => ... }`：使用**尾随 Lambda** 语法注册路由处理器，`{ ctx => ... }` 是一个闭包，它会在路由匹配时被调用，并接收请求上下文 `ctx`。
- `if (routes.contains(ctx.path))`：先检查路由是否存在，避免空指针异常，这是防御性编程的基本习惯。
- `ctx.statusCode = 404`：直接修改 `Context` 对象的状态码——这正是我们在第二章中选择 `class`（引用类型）的原因，修改会直接反映在调用方持有的对象上。
- 输出 `[200]` 和 `[404]`：分别对应找到路由和未找到路由的两种情况，验证了路由逻辑的正确性。

**💡 核心要点**

- **路由表 = 字典**：路由的本质是一张从"路径"到"处理函数"的映射表，`HashMap` 提供 O(1) 查找效率。
- **类型别名 `type Handler`**：让函数类型拥有有意义的名称，提升代码可读性，体现函数作为一等公民的思想。
- **闭包作为处理器**：Lambda 表达式可捕获外部状态，是将业务逻辑绑定到路由的简洁方式。
- **集中式 404 处理**：在路由层统一处理未匹配请求，避免 404 逻辑散落在各业务处理函数中。

## 工程化提示

*   路由匹配建议支持动态参数与方法过滤，本例只演示核心思路。
*   404 等错误响应应统一处理，避免分散在业务逻辑中。
*   处理函数最好保持幂等，避免重复调用造成副作用。

## 小试身手

1. 为 `Router` 增加 `remove` 方法，支持删除路由。
2. 让路由表支持按 `HttpMethod` 匹配（例如 GET/POST 不同处理器）。
