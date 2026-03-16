# 第十章：智能中枢 (综合实战)

> 我们将整合所有模块，构建一个"智能家居控制中枢 CLI"，它能够注册设备、批量控制并输出状态报告。
> 功能：
> 1.  **设备注册**：支持不同类型设备。
> 2.  **并发控制**：一键开启"离家模式"（并行关闭所有设备）。
> 3.  **状态查询**：实时显示系统概览。

## 本章目标

*   综合运用接口、集合与并发机制实现完整流程。
*   理解设备注册、批量控制与状态汇总的关键步骤。
*   建立"模块拆分 + 统一调度"的工程思路。

## 1. 完整系统实现

本章将所有前九章的知识点融合到一个完整的系统中。在阅读代码之前，先理解整体架构：

**系统架构概览**

```
main()（入口）
  └─ SmartHomeHub（控制中枢，第5章：class）
       ├─ devices: ArrayList<SmartDevice>（第7章：集合）
       ├─ addDevice()（注册设备）
       ├─ activateAwayMode()（第9章：并发 spawn + Future）
       └─ reportStatus()（第3章：for-in 循环）
            └─ SmartDevice（第6章：interface，统一协议）
                 ├─ SmartLight（第5章：class，实现接口）
                 └─ SmartSpeaker（第5章：class，实现接口）
```

**关键设计决策说明**

1. **接口 `SmartDevice` 作为统一抽象**（第六章）：`SmartHomeHub` 只依赖接口，不依赖具体实现。未来新增 `SmartThermostat`、`SmartCamera` 等设备，只需实现接口，控制中枢代码无需任何改动。

2. **并发关闭设备**（第九章）：`activateAwayMode` 使用 `spawn` 并行发送关闭指令，大幅缩短总执行时间。10 个设备的关闭操作如果串行需要时间叠加，并行则取决于最慢的设备。

3. **`ArrayList` 管理设备列表**（第七章）：设备数量在运行时动态变化，`ArrayList` 支持动态增删，比固定数组更灵活。

4. **`sleep` 模拟网络延迟**（第九章）：真实环境中控制指令需要通过网络发送到设备，会有延迟。`sleep` 在示例中扮演了这个角色，让并发的效果更加真实可见。

<!-- check:run -->
```cangjie
import std.collection.*
import std.sync.*
import std.time.*

// === 1. 核心协议 ===
interface SmartDevice {
    func getName(): String
    func turnOff(): Unit
    func getStatus(): String
}

// === 2. 设备实现 ===
class SmartLight <: SmartDevice {
    let name: String
    var isOn: Bool = true

    public init(name: String) { this.name = name }

    public func getName(): String { return name }

    public func turnOff() {
        // 模拟网络延迟
        sleep(Duration.millisecond * 100)
        isOn = false
        println("💡 [${name}] 已熄灭")
    }

    public func getStatus(): String { return if (isOn) { "ON" } else { "OFF" } }
}

class SmartSpeaker <: SmartDevice {
    let name: String
    var isPlaying: Bool = true

    public init(name: String) { this.name = name }

    public func getName(): String { return name }

    public func turnOff() {
        sleep(Duration.millisecond * 200)
        isPlaying = false
        println("🔇 [${name}] 已停止播放")
    }

    public func getStatus(): String { return if (isPlaying) { "PLAYING" } else { "IDLE" } }
}

// === 3. 控制中枢 ===
class SmartHomeHub {
    var devices = ArrayList<SmartDevice>()

    public func addDevice(dev: SmartDevice) {
        devices.add(dev)
        println("系统: 接入新设备 -> ${dev.getName()}")
    }

    // 离家模式：并发关闭所有设备
    public func activateAwayMode() {
        println("\n>>> 正在激活 [离家模式] <<<")
        let futures = ArrayList<Future<Unit>>()
        let start = DateTime.now()

        for (dev in devices) {
            // 为每个设备启动一个关闭任务
            let f = spawn {
                dev.turnOff()
            }
            futures.add(f)
        }

        // 等待所有设备响应
        for (f in futures) { f.get() }

        let end = DateTime.now()
        println(">>> 离家模式激活完成！耗时: ${(end - start).toMilliseconds()} ms\n")
    }

    public func reportStatus() {
        println("=== 系统状态报告 ===")
        for (dev in devices) {
            println("Device: ${dev.getName()} | Status: ${dev.getStatus()}")
        }
        println("==================")
    }
}

// === 4. 主程序入口 ===
main() {
    let hub = SmartHomeHub()

    // 1. 系统初始化，接入设备
    hub.addDevice(SmartLight("客厅主灯"))
    hub.addDevice(SmartLight("卧室台灯"))
    hub.addDevice(SmartSpeaker("小米音箱"))
    hub.addDevice(SmartLight("走廊灯带"))

    // 2. 查看当前状态
    hub.reportStatus()

    // 3. 用户出门，触发离家模式
    hub.activateAwayMode()

    // 4. 再次确认状态
    hub.reportStatus()
}
```

```bash
# (离家模式中各设备关闭的输出顺序可能因并发而不同)
系统: 接入新设备 -> 客厅主灯
系统: 接入新设备 -> 卧室台灯
系统: 接入新设备 -> 小米音箱
系统: 接入新设备 -> 走廊灯带
=== 系统状态报告 ===
Device: 客厅主灯 | Status: ON
Device: 卧室台灯 | Status: ON
Device: 小米音箱 | Status: PLAYING
Device: 走廊灯带 | Status: ON
==================

>>> 正在激活 [离家模式] <<<
💡 [客厅主灯] 已熄灭
💡 [卧室台灯] 已熄灭
💡 [走廊灯带] 已熄灭
🔇 [小米音箱] 已停止播放
>>> 离家模式激活完成！耗时: 207 ms

=== 系统状态报告 ===
Device: 客厅主灯 | Status: OFF
Device: 卧室台灯 | Status: OFF
Device: 小米音箱 | Status: IDLE
Device: 走廊灯带 | Status: OFF
==================
```

## 终章：万物互联

恭喜！你已经亲手构建了一个微型智能家居系统。让我们回顾一下这段旅程中学到的每一块知识积木，以及它们是如何在最终系统中各司其职的：

**知识回顾：**
*   **变量与类型**（第二章）：定义传感器数据结构，`let`/`var` 区分不可变配置与动态状态，强类型保障数据安全。
*   **流程控制**（第三章）：实现自动化判断逻辑，`if-else` 响应阈值、`while` 持续监控、`for-in` 遍历设备列表。
*   **函数与类**（第四、五章）：封装设备驱动指令（函数），建模物理实体的状态与行为（struct/class）。
*   **接口与多态**（第六章）：统一不同品牌的控制协议，面向抽象编程使系统具有高度可扩展性。
*   **集合与泛型**（第七章）：`HashMap` 管理设备注册表，`ArrayList` 维护设备列表，泛型让数据结构复用成为可能。
*   **错误处理**（第八章）：`Option` 优雅处理设备离线等可预期问题，`try-catch` 保护关键操作不崩溃。
*   **并发编程**（第九章）：`spawn` + `Future` 实现设备批量并行控制，`AtomicInt64` 保障共享数据的线程安全。

智能家居只是物联网（IoT）的一个缩影。同样的逻辑可以应用在工业自动化、智慧城市等更广阔的领域。仓颉语言的高效与安全，将是你构建万物互联世界的坚实基石。

**下一步建议**：
- 尝试完成每章的"小试身手"练习，巩固所学知识。
- 尝试为系统添加 HTTP API 接口，让远程控制成为可能（参考仓颉 HTTP 相关文档）。
- 探索仓颉的更多特性：宏、反射、FFI（与 C 语言互操作），为你的项目解锁更多能力。

## 工程化提示

*   批量控制设备时建议设置超时与失败重试机制。
*   设备状态上报应独立于控制流程，避免阻塞。
*   真实系统要考虑权限与安全验证，防止非法控制。

## 小试身手

1. 为 `SmartHomeHub` 增加 `removeDevice` 方法并测试。
2. 增加一个 `SmartThermostat` 设备，并在状态报告中输出当前温度。
