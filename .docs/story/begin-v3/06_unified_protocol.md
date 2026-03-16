# 第六章：统一协议 (接口与扩展)

> 你的系统需要支持小米、飞利浦、华为等不同品牌的设备。你不可能为每个品牌写一套代码。你需要定义一个"统一控制协议"（Interface），把差异隔离在适配层。

## 本章目标

*   学会使用接口抽象跨品牌设备能力。
*   理解多态在统一控制中的作用。
*   掌握扩展标准类型的安全方式。

## 1. 定义协议标准 (Interface)

不管是什么设备，只要接在电源上，就应该能"开关"。

**什么是接口（Interface）？**

接口是一份**行为契约**——它只声明"这类对象能做什么"（方法签名），而不规定"具体怎么做"（方法实现）。任何声明了实现某个接口的类，都必须提供接口中所有方法的具体实现，否则编译不通过。

类比现实：`Switchable` 接口就像"中国国家标准插头规格"——无论是小米的产品还是飞利浦的产品，只要宣称符合这个标准（实现了接口），就能被任何符合规格的插座（控制中心）使用。规格书本身不生产任何产品，它只定义了"要能用，必须满足哪些条件"。

**接口解决了什么问题？**

没有接口时，如果你想统一控制 10 个不同品牌的设备，你需要为每个品牌写专门的控制代码。有了接口，控制中心只需要"会用 `Switchable` 接口"，就能控制所有实现了该接口的设备，不论它们内部实现有何差异。这是**面向抽象编程**的核心价值。

<!-- check:run project=unified_protocol -->
```cangjie
interface Switchable {
    func on(): Unit
    func off(): Unit
    func getStatus(): String
}
```

## 2. 厂商适配 (Implementation)

不同厂商的设备底层指令可能不同，但都必须实现上述接口。

**接口实现语法**

在仓颉中，用 `class 类名 <: 接口名` 的语法声明"这个类实现了某个接口"。`<:` 可以理解为"是一种……"，即"PhilipsHue 是一种 Switchable（可开关的）设备"。

每个实现类必须提供接口中所有方法的具体实现。飞利浦灯通过 Zigbee 协议发送指令，小米插座通过 Wi-Fi 发送指令——两者的实现细节完全不同，但对外暴露的接口是完全一致的。这种差异被"封装"在各自的实现类中，不会泄漏到控制中心。

<!-- check:run project=unified_protocol -->
```cangjie
class PhilipsHue <: Switchable {
    public func on() { println("Hue: 发送 Zigbee 开启指令") }
    public func off() { println("Hue: 发送 Zigbee 关闭指令") }
    public func getStatus(): String { return "Hue Online" }
}

class XiaomiPlug <: Switchable {
    public func on() { println("Mi: 发送 Wi-Fi 开启指令") }
    public func off() { println("Mi: 发送 Wi-Fi 关闭指令") }
    public func getStatus(): String { return "Mi Plug Active" }
}
```

## 3. 统一控制中心 (多态)

控制中心不需要知道设备品牌，只认 `Switchable` 协议。

**什么是多态（Polymorphism）？**

多态是面向对象的三大特性之一，字面意思是"多种形态"。当一个参数的类型是接口类型（如 `Switchable`）时，你可以传入任何实现了该接口的具体对象（`PhilipsHue`、`XiaomiPlug` 等）。程序在运行时会自动调用该具体对象的方法实现，而调用方（`masterSwitch`）完全不需要关心是哪个具体类型。

类比现实：`masterSwitch` 函数就像一个万能遥控器，只要是符合"可开关协议"的设备，不管是电视还是空调还是灯，按下按钮就能控制。万能遥控器不需要知道设备的品牌，它只认协议。

这正是"面向接口编程，而非面向实现编程"的核心价值：控制中心与具体设备解耦，新增设备只需实现接口，无需修改控制中心代码。

<!-- check:run project=unified_protocol -->
```cangjie
func masterSwitch(device: Switchable, state: Bool) {
    if (state) { device.on() } else { device.off() }
}

main() {
    let lamp = PhilipsHue()
    let fan = XiaomiPlug()

    println("--- 一键全开 ---")
    masterSwitch(lamp, true)
    masterSwitch(fan, true)
}
```

<!-- expected_output:
--- 一键全开 ---
Hue: 发送 Zigbee 开启指令
Mi: 发送 Wi-Fi 开启指令
-->

**代码解析**：
- `func masterSwitch(device: Switchable, state: Bool)`：参数 `device` 的类型是接口 `Switchable`，这意味着任何实现了该接口的对象都可以被传入。
- `device.on()` 和 `device.off()`：运行时仓颉会根据 `device` 的实际类型（`PhilipsHue` 或 `XiaomiPlug`）调用对应的具体实现。这正是多态的运作机制。
- 尽管 `lamp` 和 `fan` 是不同类型的设备，`masterSwitch` 用完全相同的方式处理它们——这就是接口带来的统一性。

**💡 核心要点**

*   **接口（interface）** 定义行为契约（"能做什么"），不包含实现（"怎么做"）。
*   **`class 名 <: 接口名`** 语法声明实现关系，实现类必须提供所有接口方法的具体实现。
*   **多态**：同一段调用代码（`device.on()`）在运行时会因对象的实际类型不同而产生不同行为。
*   接口是实现"开闭原则"的关键工具：对扩展开放（新增设备只需实现接口），对修改关闭（控制中心代码无需改动）。

## 4. 扩展现有功能 (Extensions)

你想让所有的字符串（比如设备日志）都能自动加上时间戳，但不能修改系统 String 类的源码。

**什么是扩展（Extension）？**

有时你希望给一个已有的类型添加新功能，但这个类型来自标准库或第三方库，你无法修改其源码。**扩展**语法允许你在不修改原始类型的前提下，为其添加新的方法。

类比现实：扩展就像给一辆已有的汽车加装一个 GPS 导航系统——汽车本身没有变，但具备了新的功能。你不需要重新设计整辆车（修改源码），只需要"外挂"一个设备（`extend`）即可。

在仓颉中，`extend String { ... }` 语法为 `String` 类型添加了新方法。扩展中的 `this` 关键字指代被扩展的当前字符串实例本身。这是一种非常安全的扩展方式：原始类型的代码完全不受影响，扩展只在导入后可用。

<!-- check:run -->
```cangjie
extend String {
    func withTime(): String {
        return "[2024-01-01 12:00:00] " + this
    }
}

main() {
    let log = "系统异常重启"
    println(log.withTime())
}
```

<!-- expected_output:
[2024-01-01 12:00:00] 系统异常重启
-->

**代码解析**：
- `extend String { func withTime(): String { ... } }`：为 `String` 类型添加了一个新方法 `withTime()`，返回带时间戳前缀的新字符串。
- `"[2024-01-01 12:00:00] " + this`：`this` 在扩展方法中指代调用该方法的字符串实例本身（即 `log`）。
- `log.withTime()`：调用扩展方法的语法与调用普通方法完全一致，仿佛 `withTime()` 本来就是 `String` 的方法一样。

**💡 核心要点**

*   **扩展（extend）** 允许你为任何已有类型（包括标准库类型）添加新方法，无需修改原始代码。
*   扩展中可以访问 `this`（当前实例）和已有的公开方法，但不能添加新的存储字段。
*   扩展是仓颉中实现"开闭原则"的另一种方式：在不破坏现有代码的前提下增加功能。

## 工程化提示

*   协议定义要稳定清晰，避免频繁变更影响所有设备实现。
*   适配层可以隔离厂商差异，保持核心业务逻辑统一。
*   时间戳示例为占位，真实系统应调用统一时间服务。

## 小试身手

1. 为 `Switchable` 增加 `restart()` 方法，并在实现中补齐。
2. 扩展 `String` 增加 `withLevel(level: String)`，输出日志级别。
