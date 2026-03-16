# 第四章：中间件 (闭包与函数式编程)

> 现代 Web 框架的灵魂是"洋葱模型"的中间件系统。日志记录、鉴权、耗时统计等功能都可以作为中间件层层包裹业务逻辑，让核心业务保持干净。

## 本章目标

*   理解中间件链的执行顺序与职责边界。
*   学会使用闭包构建"前后包裹"的逻辑。
*   认识中间件在横切关注点中的价值。

试想一下，如果每个路由处理函数都需要自己记录日志、自己验证权限、自己统计耗时，代码会变成什么样？每个函数都会充斥着与业务无关的"样板代码"，难以维护，且修改日志格式时需要改动所有处理函数。这类问题在软件工程中被称为**横切关注点（Cross-Cutting Concerns）**——它们不属于某个特定业务，却影响系统的每个角落。

中间件（Middleware）是解决横切关注点的经典模式。就像洋葱的层层包裹，每个中间件在业务逻辑"外面"添加一层能力：

```
请求进入
  ↓ [日志中间件：记录开始]
    ↓ [鉴权中间件：验证身份]
      ↓ [业务逻辑：处理请求]
    ↑ [鉴权中间件：（无后处理）]
  ↑ [日志中间件：记录结束、状态码]
响应返回
```

这就是著名的**洋葱模型（Onion Model）**：请求从外层穿入，响应从内层穿出，每个中间件都有机会在请求前后执行逻辑。

## 1. 定义中间件 (Handler Chaining)

中间件本质上是一个"包装函数"，它接收下一个处理函数，返回一个新的处理函数。

实现洋葱模型的关键在于 **`next()` 函数**。每个中间件接收一个 `next` 参数，调用 `next()` 表示"将控制权交给后续层"，不调用则"短路"整个链条（例如鉴权失败时直接拦截）。`dispatch(index)` 是一个**递归闭包**：当 index 等于中间件数量时执行业务逻辑，否则取出第 index 个中间件，将 `dispatch(index+1)` 包装成 `next` 传入，从而形成嵌套调用链。这种"递归构建调用栈"的技术是函数式编程中的经典范式。

<!-- check:run project=middleware_chain -->
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

type Handler = (Context) -> Unit

// Next 代表后续的处理逻辑
type Next = () -> Unit

// 中间件签名
type Middleware = (Context, Next) -> Unit

class Engine {
    var middlewares = ArrayList<Middleware>()

    public func use(mw: Middleware) {
        middlewares.add(mw)
    }

    // 模拟执行链
    public func run(ctx: Context, finalHandler: Handler) {
        // 构建洋葱模型
        // 这里用简化的递归模拟：index 指向当前中间件
        func dispatch(index: Int64): Unit {
            if (index >= middlewares.size) {
                finalHandler(ctx) // 链条末端，执行业务
                return
            }

            let mw = middlewares[index]
            // next 函数：指向下一个中间件
            let next = { => dispatch(index + 1) }

            // 执行当前中间件
            mw(ctx, next)
        }

        dispatch(0)
    }
}
```

## 2. 实战：日志与鉴权

有了这套机制，添加新能力只需调用一次 `app.use()`，完全不影响业务代码。日志中间件在 `next()` 调用前后分别记录请求开始和结束，由于仓颉的函数调用是栈式的，`next()` 之后的代码会等到整条链执行完毕后才运行，这正是"洋葱穿透"效果的代码体现。鉴权中间件则展示了**短路**机制：一旦检测到无权限路径，直接设置 403 状态并返回，不调用 `next()`，后续的业务逻辑完全不会被触达。

<!-- check:run project=middleware_chain -->
```cangjie
main() {
    let app = Engine()

    // 1. 日志中间件
    app.use { ctx, next =>
        println("[Log] Start Request: ${ctx.path}")
        next() // 执行后续逻辑
        println("[Log] End Request (Status: ${ctx.statusCode})")
    }

    // 2. 鉴权中间件
    app.use { ctx, next =>
        if (ctx.path == "/admin") {
            println("[Auth] 权限不足！拦截请求。")
            ctx.statusCode = 403
            ctx.string("Forbidden")
            // 不调用 next()，请求到此终止
        } else {
            next()
        }
    }

    // 业务处理
    let handler = { ctx: Context =>
        println("==> 执行业务逻辑...")
        ctx.string("Success")
    }

    // 测试 1: 普通请求
    println("=== 测试 /home ===")
    app.run(Context("/home", HttpMethod.GET), handler)

    // 测试 2: 受限请求
    println("")
    println("=== 测试 /admin ===")
    app.run(Context("/admin", HttpMethod.GET), handler)
}
```

<!-- expected_output:
=== 测试 /home ===
[Log] Start Request: /home
==> 执行业务逻辑...
[Log] End Request (Status: 200)
=== 测试 /admin ===
[Log] Start Request: /admin
[Auth] 权限不足！拦截请求。
[Log] End Request (Status: 403)
-->

```bash
=== 测试 /home ===
[Log] Start Request: /home
==> 执行业务逻辑...
[Log] End Request (Status: 200)
=== 测试 /admin ===
[Log] Start Request: /admin
[Auth] 权限不足！拦截请求。
[Log] End Request (Status: 403)
```

**代码解析：**

- **`/home` 请求**：日志中间件先打印"Start"，然后调用 `next()` 交给鉴权中间件；鉴权中间件发现路径合法，再次调用 `next()` 交给业务处理；业务处理完成后，控制权依次返回——日志中间件打印"End"。这就是完整的洋葱穿透路径。
- **`/admin` 请求**：日志中间件打印"Start"并调用 `next()`；鉴权中间件检测到 `/admin` 路径，打印拒绝信息、设置 403，**不调用 `next()`**，业务逻辑被跳过；控制权返回日志中间件，打印"End (Status: 403)"——注意日志中间件依然能看到最终状态码，体现了洋葱模型中外层中间件对整个过程的"包裹"能力。
- `println("")` 打印空行用于分隔两次测试的输出，对应预期输出中两个测试块之间的空行。

**💡 核心要点**

- **洋葱模型**：请求从外层穿入（中间件前处理），响应从内层穿出（中间件后处理），每层都有机会"包裹"整个处理过程。
- **`next()` 是控制权转交信号**：调用 `next()` = 继续执行后续层；不调用 = 短路拦截，适用于鉴权、限流等场景。
- **闭包捕获 `index`**：`let next = { => dispatch(index + 1) }` 是一个捕获了 `index` 变量的闭包，这是用闭包实现延迟执行的经典技巧。
- **顺序即优先级**：中间件的注册顺序决定了执行顺序，日志通常放最外层，鉴权紧随其后，业务逻辑在最内层。

## 工程化提示

*   中间件顺序要固定并可配置，避免逻辑混乱。
*   鉴权中间件应返回统一错误格式，便于前端处理。
*   洋葱模型执行时注意异常传播，确保日志完整输出。

## 小试身手

1. 添加一个"耗时统计"中间件，输出请求执行耗时。
2. 将 `Engine` 改为支持在运行时插入全局错误处理中间件。
