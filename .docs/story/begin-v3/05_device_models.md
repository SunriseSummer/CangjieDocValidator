# 第五章：设备建模 (结构体与类)

> 现实世界中，灯泡、恒温器、摄像头都有各自的属性和行为。我们需要在代码中对这些实体进行建模，确保数据快照与设备状态被正确区分。

## 本章目标

*   理解结构体与类在智能设备建模中的区别。
*   学会为实体添加初始化与行为方法。
*   认识状态对象在系统中的生命周期管理。

## 1. 数据采集点 (Struct)

传感器上报的数据包通常是只读的快照，适合使用 `struct`（值类型）。

**结构体（Struct）是什么？**

到目前为止，我们用独立的变量存储数据（一个变量存温度，另一个存单位……）。但当相关联的数据越来越多时，这种方式变得难以管理。**结构体**允许我们把一组相关的字段"打包"成一个有名字的整体。

类比现实：一个传感器数据包就像一张快递单——上面同时记录了发件人、收件人、重量、时间戳等多个信息。这张单子整体传递，不会把各个字段分开散落。`struct` 就是这张"快递单模板"，而每次创建实例就是填写了一张新的快递单。

**为什么传感器数据用 `struct`（值类型）而不是 `class`？**

`struct` 是**值类型**：当你把一个 `struct` 变量赋给另一个变量时，会创建一份独立的**拷贝**。这对于不应被修改的数据快照（如传感器读数）非常安全——接收方得到的是一份独立副本，不会意外修改原始数据。

`class` 是**引用类型**：多个变量可以指向同一个对象实例，修改其中一个会影响所有持有该引用的地方。这适合需要共享状态的场景，如下文中持续变化的物理设备。

<!-- check:run project=device_models -->
```cangjie
struct SensorPacket {
    let timestamp: Int64
    let value: Float64
    let unit: String

    public init(val: Float64, unit: String) {
        this.timestamp = 1718888888 // 模拟时间戳
        this.value = val
        this.unit = unit
    }

    public func log() {
        println("[Log] Value: ${value}${unit}")
    }
}
```

## 2. 物理设备 (Class)

一个真实的灯泡是有状态的（开/关，亮度），且在这个系统中是唯一的对象，适合使用 `class`（引用类型）。

**类（Class）是什么？**

`class` 是面向对象编程（OOP）的核心概念。它不仅是数据的容器（字段），还包含操作这些数据的方法（函数）。一个 `class` 定义就是一个"蓝图"——描述某类对象应该有哪些属性和能力。

类比现实：`SmartLight` 类就像智能灯泡的产品规格书：规格书上说每个灯泡有一个 ID（`id`）、一个亮度值（`brightness`）和一个开关状态（`isOn`），以及可以执行"开灯"和"调光"操作。工厂按照这份规格书生产出来的每一个具体灯泡，就是这个类的一个**实例（instance）**。

**`init` 构造函数**：创建对象时自动调用，负责将对象的字段初始化为合理的初始值。`this.id = id` 中，左边的 `this.id` 指对象自身的字段，右边的 `id` 是构造函数的参数。

**`public` 访问修饰符**：标记为 `public` 的方法可以从类的外部调用；不加修饰默认为 `internal`（包内可见）。这是**封装**的体现：只暴露必要的接口，隐藏内部实现细节。

<!-- check:run project=device_models -->
```cangjie
class SmartLight {
    let id: String
    var brightness: Int64
    var isOn: Bool

    public init(id: String) {
        this.id = id
        this.brightness = 0
        this.isOn = false
    }

    public func turnOn() {
        isOn = true
        brightness = 100
        println("💡 灯光 [${id}] 已开启")
    }

    public func dim(level: Int64) {
        if (isOn) {
            brightness = level
            println("💡 灯光 [${id}] 亮度调节为 ${level}%")
        }
    }
}

main() {
    // 收到一个传感器数据包
    let data = SensorPacket(25.5, "C")
    data.log()

    // 控制客厅主灯
    let livingRoomLight = SmartLight("L-001")
    livingRoomLight.turnOn()
    livingRoomLight.dim(50)
}
```

<!-- expected_output:
[Log] Value: 25.500000C
💡 灯光 [L-001] 已开启
💡 灯光 [L-001] 亮度调节为 50%
-->

**代码解析**：
- `let data = SensorPacket(25.5, "C")`：调用 `SensorPacket` 的 `init` 构造函数创建一个实例，传入温度值和单位。实例绑定到 `let` 变量表示"这个数据包对象本身不会被替换"。
- `data.log()`：通过点号 `.` 调用对象的方法，这是面向对象的标准调用语法。
- `let livingRoomLight = SmartLight("L-001")`：创建一个 `SmartLight` 对象，传入设备 ID。
- `livingRoomLight.dim(50)`：调用 `dim` 方法前，对象内部会检查 `isOn` 状态，只有已开启的灯才能调光——这体现了将业务规则封装在方法内部，而不是散落在调用代码中。

**💡 核心要点**

*   **值类型（struct）vs. 引用类型（class）**：`struct` 赋值时复制数据，`class` 赋值时共享引用。数据快照选 `struct`，有状态的实体选 `class`。
*   **封装**：将数据（字段）和操作数据的逻辑（方法）放在一起，并通过访问控制（`public`/`private`）限制外部直接访问内部状态。这是面向对象的三大特性之一（另外两个是继承和多态，将在后续章节介绍）。
*   **`this` 关键字**：在方法和 `init` 中，`this` 指代当前对象实例本身，用于区分同名的字段和参数。
*   好的建模原则：字段描述对象的**状态**（"是什么"），方法描述对象的**行为**（"能做什么"），两者共同构成完整的对象模型。

## 工程化提示

*   传感器数据应带上时间戳与来源，便于回溯。
*   对设备状态的修改建议集中在方法内，避免外部随意写入。
*   设备 ID 与业务命名需保持一致，避免资产管理混乱。

## 小试身手

1. 为 `SmartLight` 增加 `turnOff()` 方法并更新状态。
2. 在 `SensorPacket` 中加入 `sensorId` 字段并输出。
