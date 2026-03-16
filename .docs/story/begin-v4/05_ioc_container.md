# 第五章：IoC 容器 (泛型与接口)

> 为了解耦业务代码，现代框架通常提供依赖注入（Dependency Injection）功能。我们需要构建一个简单的 IoC (Inversion of Control) 容器，让服务注册与使用分离。

## 本章目标

*   理解依赖注入与控制反转的核心概念。
*   学会用接口与泛型容器管理服务实例。
*   认识构造注入在模块解耦中的作用。

想象一个场景：`UserController` 需要使用 `DatabaseService` 查询数据，同时需要 `CacheService` 缓存结果。如果 `UserController` 自己创建这些依赖（`let db = DatabaseService()`），就会产生**紧耦合**——更换数据库实现时，必须修改 `UserController` 的代码。这违反了"开闭原则"：对扩展开放，对修改关闭。

**控制反转（IoC，Inversion of Control）**是解决这个问题的核心思想：将"谁来创建依赖"的控制权从组件自身转移到外部容器。就像去酒店入住，你不需要自己搬床铺——前台（IoC 容器）会为你分配好房间（依赖实例），你直接入住（使用）即可。**依赖注入（DI）**是实现 IoC 的最常见方式：通过构造函数或方法参数将依赖"注入"进组件，而非由组件自行创建。

类比现实：工厂流水线上，工人不需要自己去仓库取零件，物料员（IoC 容器）会按需把零件送到工位（注入依赖）。工人专注于装配（业务逻辑），不关心零件从哪来。

## 1. 容器定义 (Generics)

我们需要一个万能的字典，可以存储任意类型的服务实例。

`interface Service` 定义了所有可注册服务的统一契约。通过让 `Container` 存储 `Service` 接口类型（而非具体类型），容器可以管理任意实现了该接口的服务，实现了对具体实现的**隔离**。这是面向接口编程（Programming to Interface）的核心思想——调用方只依赖抽象，不依赖具体实现，使得替换底层实现时上层代码无需改动。

<!-- check:run project=ioc_container -->
```cangjie
import std.collection.*

// 抽象服务接口
interface Service {
    func getName(): String
}

class Container {
    // 简化版：Key 是服务名，Value 是服务实例
    // 真实框架会使用反射或 TypeId
    var services = HashMap<String, Service>()

    public func register(name: String, svc: Service) {
        services[name] = svc
        println("IoC: 注册服务 [${name}]")
    }

    // 获取服务
    public func resolve(name: String): Option<Service> {
        if (services.contains(name)) {
            return Some(services[name])
        }
        return None
    }
}
```

## 2. 服务注册与获取

容器的使用分为三步：**注册**（告诉容器"有这个服务"）→ **解析**（向容器申请该服务）→ **注入**（将服务传递给需要它的组件）。`resolve` 方法返回 `Option<Service>` 而非直接返回 `Service`，是因为请求的服务可能未注册。`Option` 类型强制调用方处理"找不到"的情况，消除了空指针异常的隐患——这正是仓颉类型系统安全性的体现。

模式匹配 `case db: DatabaseService => db` 实现了从接口类型到具体类型的**安全向下转型**（Downcast）。在强类型语言中，向下转型需要显式声明，编译器会确保你处理了转型失败的情况（`case _`），从而避免了运行时类型错误。

<!-- check:run project=ioc_container -->
```cangjie
class DatabaseService <: Service {
    public func getName(): String { "Database" }
    public func query(): String { "SELECT * FROM users" }
}

class CacheService <: Service {
    public func getName(): String { "Redis" }
    public func get(key: String): String { "Value for ${key}" }
}

class UserController {
    let db: DatabaseService

    // 构造注入
    public init(db: DatabaseService) {
        this.db = db
    }

    public func getUser() {
        println("Controller 调用 DB: " + db.query())
    }
}

main() {
    let container = Container()

    // 1. 注册依赖
    container.register("db", DatabaseService())
    container.register("cache", CacheService())

    // 2. 解析依赖
    if (let Some(svc) <- container.resolve("db")) {
        // 使用模式匹配进行类型转换
        let db: DatabaseService = match (svc) {
            case db: DatabaseService => db
            case _ => throw Exception("not DatabaseService")
        }

        // 3. 注入 Controller
        let ctrl = UserController(db)
        ctrl.getUser()
    }
}
```

<!-- expected_output:
IoC: 注册服务 [db]
IoC: 注册服务 [cache]
Controller 调用 DB: SELECT * FROM users
-->

```bash
IoC: 注册服务 [db]
IoC: 注册服务 [cache]
Controller 调用 DB: SELECT * FROM users
```

**代码解析：**

- `container.register("db", DatabaseService())`：将 `DatabaseService` 的实例以名称 `"db"` 注册到容器中。容器持有实例的引用，后续所有解析调用都将返回同一个实例（单例行为）。
- `if (let Some(svc) <- container.resolve("db"))`：`resolve` 返回 `Option`，使用 `if-let` 解构安全取值——如果服务未注册，`None` 分支自动跳过，不会产生运行时错误。
- `case db: DatabaseService => db`：类型模式匹配，安全地将 `Service` 接口类型转换为具体的 `DatabaseService` 类型，以便调用其特有方法 `query()`。
- `UserController(db)`：构造注入——通过构造函数参数传入依赖，`UserController` 自身不知道也不关心 `db` 是如何创建的。

**💡 核心要点**

- **IoC（控制反转）**：将依赖的创建权从组件转移到外部容器，实现组件间解耦。
- **DI（依赖注入）**：IoC 的实现方式，通过构造函数、方法参数等途径将依赖"送入"组件。
- **面向接口编程**：容器存储接口类型，调用方依赖抽象，实现对具体实现的隔离，便于单元测试与替换。
- **`Option` 返回值**：比返回 `null` 更安全的缺失值表示，强制调用方显式处理"找不到"的情况。

## 工程化提示

*   真实 IoC 容器需要生命周期管理与依赖图校验，本例仅演示核心流程。
*   强类型语言中应避免随意类型转换，建议引入明确的注册与解析接口。
*   服务命名建议统一规范，避免重复注册或歧义。

## 小试身手

1. 为 `Container` 增加 `unregister` 方法，并验证服务移除。
2. 给 `UserController` 增加 `CacheService` 依赖并完成注入。
