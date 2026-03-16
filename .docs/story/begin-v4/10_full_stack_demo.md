# 第十章：全栈博客实战 (CangjieWeb 综合演示)

> 终于，我们的 `CangjieWeb` 框架初具雏形。现在，让我们用它来构建一个真实的博客后端 API。我们将串联起所有知识点，并演示"分层 + 依赖注入"的开发方式。

## 本章目标

*   综合运用模型、服务与控制器的分层思路。
*   理解 IoC 注入与路由分发的完整流程。
*   建立"全链路设计"的系统观念。

软件工程中有一条黄金法则：**关注点分离（Separation of Concerns）**。不同职责的代码不应混杂在一起——数据定义、业务逻辑、请求处理应分属不同层次。这正是 **MVC（Model-View-Controller）** 架构和**分层架构**的核心思想。

在我们的博客后端中，职责划分如下：**Model 层**只负责定义数据结构（`Post`），不包含任何业务逻辑；**Service 层**封装业务逻辑（创建文章、查询文章列表），通过接口隔离具体实现；**Controller 层**负责解析请求、调用 Service、构建响应，是 HTTP 世界与业务世界的桥梁；**Main 入口**完成 IoC 装配，将所有组件粘合在一起。

这种分层设计的价值在于：每层只有一个变化的理由（单一职责原则）。数据库从 MySQL 换成 PostgreSQL？只需修改 `Service` 实现；HTTP 框架从自研换成标准库？只需修改 `Controller`；业务规则变化？只修改 `Service`。各层相互独立，修改互不影响。

## 1. 架构设计

*   **Models**: 定义 `Post` (文章)。
*   **Service**: 处理业务逻辑（IoC 注入）。
*   **Controller**: 处理路由与请求。
*   **Main**: 启动服务。

各层之间通过**接口（Interface）**通信而非直接依赖具体类。`BlogController` 持有的是 `BlogService` 接口引用，而非 `BlogServiceImpl`——这意味着在测试时可以注入一个 Mock Service，无需真实数据库即可验证 Controller 的行为。这就是分层架构与依赖注入结合所带来的**可测试性**。

## 2. 完整代码实现

<!-- check:run -->
```cangjie
import std.collection.*

// === 1. Core Framework (迷你版) ===
class Context {
    let path: String
    public init(path: String) { this.path = path }
    public func json(data: String) { println("HTTP 200 OK\nContent-Type: application/json\n\n${data}") }
}

// === 2. Models ===
struct Post {
    let id: Int64
    let title: String
    let content: String
    public init(id: Int64, title: String, content: String) {
        this.id = id
        this.title = title
        this.content = content
    }
}

// === 3. Services (Interface & Impl) ===
interface BlogService {
    func getAllPosts(): String
    func createPost(title: String): Unit
}

class BlogServiceImpl <: BlogService {
    var posts = ArrayList<Post>()

    public init() {
        posts.add(Post(1, "Hello Cangjie", "First Post"))
        posts.add(Post(2, "Web Dev", "Framework Design"))
    }

    public func getAllPosts(): String {
        // 模拟 JSON 序列化
        var json = "["
        for (p in posts) {
            json = json + "{\"id\": ${p.id}, \"title\": \"${p.title}\"},"
        }
        json = json + "]"
        return json
    }

    public func createPost(title: String) {
        let newId = posts.size + 1
        posts.add(Post(newId, title, "Content..."))
        println("Service: 文章 '${title}' 已创建")
    }
}

// === 4. Controller ===
class BlogController {
    let service: BlogService

    // 依赖注入
    public init(svc: BlogService) {
        this.service = svc
    }

    // GET /posts
    public func list(ctx: Context) {
        println("Processing GET /posts ...")
        let data = service.getAllPosts()
        ctx.json(data)
    }

    // POST /posts/new
    public func create(ctx: Context) {
        println("Processing POST /posts/new ...")
        service.createPost("New Article")
        ctx.json("{\"status\": \"created\"}")
    }
}

// === 5. App Entry ===
main() {
    println(">>> 启动博客后端 API...")

    // 1. IoC 组装
    let service = BlogServiceImpl()
    let controller = BlogController(service)

    // 2. 模拟路由分发 (Router Loop)
    let requests = [
        Context("/posts"),
        Context("/posts/new"),
        Context("/posts") // 再次查询验证数据更新
    ]

    for (req in requests) {
        println("\n>>> Incoming Request: ${req.path}")

        if (req.path == "/posts") {
            controller.list(req)
        } else if (req.path == "/posts/new") {
            controller.create(req)
        } else {
            println("404 Not Found")
        }

        sleep(Duration.millisecond * 200)
    }
}
```

<!-- expected_output:
>>> 启动博客后端 API...
>>> Incoming Request: /posts
Processing GET /posts ...
HTTP 200 OK
Content-Type: application/json
[{"id": 1, "title": "Hello Cangjie"},{"id": 2, "title": "Web Dev"},]
>>> Incoming Request: /posts/new
Processing POST /posts/new ...
Service: 文章 'New Article' 已创建
HTTP 200 OK
Content-Type: application/json
{"status": "created"}
>>> Incoming Request: /posts
Processing GET /posts ...
HTTP 200 OK
Content-Type: application/json
[{"id": 1, "title": "Hello Cangjie"},{"id": 2, "title": "Web Dev"},{"id": 3, "title": "New Article"},]
-->

```bash
>>> 启动博客后端 API...
>>> Incoming Request: /posts
Processing GET /posts ...
HTTP 200 OK
Content-Type: application/json
[{"id": 1, "title": "Hello Cangjie"},{"id": 2, "title": "Web Dev"},]
>>> Incoming Request: /posts/new
Processing POST /posts/new ...
Service: 文章 'New Article' 已创建
HTTP 200 OK
Content-Type: application/json
{"status": "created"}
>>> Incoming Request: /posts
Processing GET /posts ...
HTTP 200 OK
Content-Type: application/json
[{"id": 1, "title": "Hello Cangjie"},{"id": 2, "title": "Web Dev"},{"id": 3, "title": "New Article"},]
```

**代码解析：**

- **`interface BlogService`**：定义服务层契约，`BlogController` 只依赖这个接口，不关心具体实现。这是第五章 IoC 思想在实战中的体现。
- **`BlogServiceImpl` 的内存存储**：`var posts = ArrayList<Post>()` 用内存列表模拟数据库，`getAllPosts()` 手动拼接 JSON 字符串模拟序列化。真实项目会使用数据库驱动和 JSON 库替换这部分。
- **`BlogController(service)` 构造注入**：Controller 通过构造函数接收 Service 依赖，`main` 函数负责创建并传入，Controller 自身不知道也不关心 Service 如何创建。
- **三次请求的验证**：第一次 GET 返回 2 篇文章；POST 创建第 3 篇；第二次 GET 返回 3 篇文章——验证了 Service 的状态在跨请求间正确保持（内存持久化）。

**💡 核心要点：十章知识融合**

本章将前九章的知识点融合成一个完整的应用，以下是各章知识在本例中的对应位置：

- **第一章（服务核心）**：`main()` 是入口，模拟服务启动与请求循环。
- **第二章（HTTP 协议）**：`Context` 类封装请求上下文，`json()` 方法模拟响应构建。
- **第三章（路由分发）**：`if/else if` 模拟路由匹配，将请求分发给 Controller 方法。
- **第四章（中间件）**：本例省略中间件层以聚焦分层架构，实际框架会在 Controller 调用前后穿插中间件。
- **第五章（IoC 容器）**：`BlogController(service)` 是构造注入，`BlogService` 接口实现控制反转。
- **第六章（状态管理）**：`posts` 列表跨请求保持状态，`createPost` 改变状态后 `getAllPosts` 能看到更新。
- **第七章（并发）**：`sleep(Duration.millisecond * 200)` 模拟请求处理时间，真实场景会用 `spawn` 并发处理。
- **第八章（配置）**：`BlogServiceImpl.init()` 预置初始数据，类比配置加载的初始化阶段。
- **第九章（DSL/宏）**：本例的路由注册是手动的，宏 DSL 会让这部分自动化生成。

## 终章：架构师之路

恭喜！你不仅学会了仓颉语言的语法，更重要的是，你通过构建 `CangjieWeb` 框架，深入理解了：
*   **IoC 与解耦**
*   **中间件洋葱模型**
*   **并发处理模型**
*   **领域建模**

这正是从"码农"进阶为"架构师"的必经之路。继续探索吧，用仓颉构建更宏大的数字大厦！

## 工程化提示

*   JSON 序列化应使用可靠库，避免手工拼接引入格式问题。
*   路由分发应统一处理 404 与异常响应，保持接口一致。
*   业务服务层应与控制器解耦，便于测试与扩展。

## 小试身手

1. 为 `Post` 增加 `author` 字段，并在输出中体现。
2. 添加 `delete` 接口示例，并模拟删除文章流程。
