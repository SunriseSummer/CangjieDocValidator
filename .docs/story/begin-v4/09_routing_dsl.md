# 第九章：路由 DSL (宏与元编程)

> 现代框架（如 Flask, Spring）都喜欢用注解或简洁的语法来定义路由。在仓颉中，我们可以利用宏（Macro）来实现类似的 DSL（领域特定语言），让代码更具表达力，降低样板代码负担。

> *注：由于宏的实现较为复杂且涉及编译器扩展，本节主要展示宏的使用场景和概念模型。*

## 本章目标

*   理解 DSL 在提升路由声明可读性上的价值。
*   认识宏与元编程的核心概念与边界。
*   学会区分"编译期生成"与"运行期执行"的差异。

**DSL（Domain-Specific Language，领域特定语言）**是针对特定问题域设计的小型语言，专注于表达该领域的核心概念，而非通用编程。你每天都在使用 DSL——SQL 是查询关系数据库的 DSL，HTML 是描述网页结构的 DSL，正则表达式是匹配文本模式的 DSL。好的 DSL 让代码读起来像是在陈述"做什么"，而非"怎么做"。

在 Web 路由场景中，手动注册路由是"怎么做"的命令式写法；而使用注解（`@Get("/users")`）是"做什么"的声明式写法。后者更接近人类语言，减少认知负担。Spring Boot、Flask 等框架之所以广受欢迎，很大程度上得益于其优雅的 DSL 设计。

## 1. 宏的概念

宏是在编译期间运行的代码。它可以读取你的代码结构，并生成新的代码。

假设我们定义了一个 `@Route` 宏。

**元编程（Metaprogramming）**是"编写能操作代码的代码"的技术。宏是元编程的一种形式：宏在**编译期**运行，接收源代码的**抽象语法树（AST，Abstract Syntax Tree）**作为输入，输出转换后的新 AST。最终编译的是宏展开后的代码，而非原始源码。这就是为什么注解 `@Get("/users")` 能自动生成路由注册代码——宏在编译时将注解"展开"为等价的函数调用。

<!-- check:ast -->
```cangjie
// 概念代码：宏定义 (伪代码)
// macro Route(path: String, method: String) {
//     return quote {
//         Router.register(path, method, func)
//     }
// }
```

## 2. 使用 DSL 定义 API

如果不使用宏，我们需要手动注册：

<!-- check:ast -->
```cangjie
// 手动方式
// router.add("/user", GET, handleUser)
```

如果有了宏，我们可以这样写（更加声明式）：

<!-- check:ast -->
```cangjie
/*
@Controller("/api")
class UserApi {

    @Get("/info")
    func userInfo() {
        return "User Info"
    }

    @Post("/login")
    func login() {
        return "Login Success"
    }
}
*/
```

对比两种写法，声明式的宏版本优势明显：路由路径与处理函数紧密相邻，一眼就能看出"哪个函数处理哪个路径"；添加新路由只需增加一个注解，无需修改任何注册代码；路由路径的拼写错误可以在宏展开时就被发现，而非等到运行时。这就是"声明式优于命令式"在框架设计中的价值。

## 3. 模拟宏生成的代码

既然宏在编译期生成代码，我们可以模拟一下宏"展开"后的样子。这就是元编程的本质：**写代码的代码**。

理解宏展开的最好方法是"手动模拟"：假设宏已经扫描了 `UserApi` 类的所有注解，并生成了对应的路由注册代码。`GeneratedUserApiRoutes.registerRoutes` 就是这份生成代码的代表，它完成了原本需要开发者手写的所有 `router.add(...)` 调用。在真实的框架中，这一步完全由宏自动完成，开发者只需写带注解的类即可。

<!-- check:run -->
```cangjie
// 复用之前的 Router 类定义 (简化版)
class Router {
    public func add(path: String, handler: (String)->Unit) {
        println("Registered: ${path}")
    }
}

// 模拟宏展开后的结果
class GeneratedUserApiRoutes {
    public static func registerRoutes(router: Router) {
        println("Macro: 正在扫描注解并生成路由表...")

        router.add("/api/info") { ctx =>
            println("调用 UserApi.userInfo()")
        }

        router.add("/api/login") { ctx =>
            println("调用 UserApi.login()")
        }
    }
}

main() {
    let r = Router()
    // 宏在幕后自动完成了这一步
    GeneratedUserApiRoutes.registerRoutes(r)
}
```

<!-- expected_output:
Macro: 正在扫描注解并生成路由表...
Registered: /api/info
Registered: /api/login
-->

**代码解析：**

- `class Router { func add(...) { println("Registered: ...") } }`：简化版路由器，不实际存储路由，仅打印注册记录，便于验证宏生成代码的执行效果。
- `GeneratedUserApiRoutes.registerRoutes(router)`：这个静态方法代表了"宏展开后生成的代码"。在真实框架中，开发者永远不会手写这个类——它由编译器在宏处理阶段自动生成。
- `println("Macro: 正在扫描注解...")`：模拟宏展开时的日志输出，帮助理解宏的执行时机——虽然实际宏在编译期运行，但展开后的代码在运行期输出此信息。
- 两条 `Registered: /api/...` 输出对应两个模拟注解 `@Get("/info")` 和 `@Post("/login")` 分别生成的路由注册。

**💡 核心要点**

- **DSL 的价值**：将"如何注册路由"的实现细节隐藏在语法糖背后，让代码直接表达"这个函数处理这个 URL"的业务意图。
- **编译期 vs 运行期**：宏在**编译期**运行，生成代码；生成的代码在**运行期**执行。这是宏与普通函数的根本区别——宏的"执行"对最终用户不可见。
- **AST（抽象语法树）**：宏操作的是代码的树形结构表示，而非文本字符串。这保证了宏变换的正确性和类型安全。
- **零运行时开销**：宏在编译期完成所有代码生成，运行时执行的是已展开的普通代码，没有任何反射或动态分发开销。

## 工程化提示

*   DSL 设计要保持一致性，避免引入歧义。
*   宏生成代码要可追踪，便于调试与错误定位。
*   真实框架需结合编译器能力实现宏，本例仅用于概念说明。

## 小试身手

1. 设计一个 `@Put` 路由宏的使用示例，并描述生成代码。
2. 在宏展开示例中添加"路由分组"逻辑。
