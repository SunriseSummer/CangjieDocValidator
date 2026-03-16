# 第八章：系统容错 (错误处理)

> 物理世界是不稳定的：网络会断，传感器会坏。一个健壮的系统必须能处理这些"意外"，并提供可观测的降级路径，而不是直接崩溃。

## 本章目标

*   学会用 `Option` 处理可预期的空结果。
*   掌握异常捕获在关键路径中的作用。
*   理解模式匹配在指令解析中的优势。

## 1. 设备状态检查 (Option)

获取一个设备的状态时，设备可能已经离线（不存在状态）。

**什么是 `Option` 类型？**

在许多编程语言中，"空值"用 `null` 表示，但 `null` 是历史上最著名的设计失误之一——忘记检查 `null` 会导致程序在运行时突然崩溃（NullPointerException）。仓颉用 `Option<T>` 类型优雅地解决了这个问题。

`Option<T>` 有两种可能的值：
- `Some(v)`：表示"有值，值为 `v`"。
- `None`：表示"没有值（空）"。

类比现实：`Option` 就像一个快递盒——`Some(包裹)` 表示盒子里有东西，`None` 表示空盒子。关键在于：你**必须先打开盒子确认一下**（用 `match` 或 `if-let` 进行模式匹配），才能使用里面的内容。这个"强制检查"的设计杜绝了忘记判空的可能性——编译器会督促你处理"盒子是空的"这种情况。

**何时使用 `Option`？**

- 查询可能不存在的数据（如查找设备、读取配置项）。
- 操作可能失败且失败是**预期内正常情况**（如设备离线）时，优先用 `Option` 而非抛出异常。抛出异常更适合"不该发生却发生了"的意外情况。

<!-- check:run -->
```cangjie
func getDeviceStatus(id: String): Option<String> {
    if (id == "OFFLINE_DEV") {
        return None // 获取失败，但这是一种预期内的"空"状态
    }
    return Some("Active")
}

main() {
    let status = getDeviceStatus("OFFLINE_DEV")

    // 优雅处理离线
    match (status) {
        case Some(s) => println("设备状态: ${s}")
        case None => println("⚠️ 警告: 设备无响应")
    }
}
```

<!-- expected_output:
⚠️ 警告: 设备无响应
-->

**代码解析**：
- `func getDeviceStatus(id: String): Option<String>`：函数返回类型是 `Option<String>`，明确告知调用者"结果可能为空"。这比返回 `null` 更安全，因为调用者看到 `Option` 类型时就知道必须处理空值情况。
- `return None`：返回"无值"——表示设备离线，没有状态可返回。
- `return Some("Active")`：将实际值包装在 `Some(...)` 中返回。
- `match (status) { case Some(s) => ... case None => ... }`：模式匹配强制你处理所有可能情况。`case Some(s)` 同时解构并绑定了内部值到变量 `s`，非常简洁。

## 2. 关键操作异常 (Try-Catch)

对于不可恢复的错误（如配置文件损坏、I/O 错误），我们抛出异常并在上层捕获。

**`Option` vs. 异常：如何选择？**

这是错误处理中最重要的设计决策之一：
- **`Option`（可预期的"无结果"）**：设备离线、用户不存在、配置项缺失——这些都是"正常情况的一部分"，调用者应该优雅地处理它们。
- **异常（Exception）**：网络连接超时、文件损坏、内存耗尽——这些是"不应该发生但确实发生了"的异常情况，需要中断当前操作并上报。

**`try-catch-finally` 结构**：
- `try { ... }`：尝试执行可能出错的代码。
- `catch (e: 异常类型) { ... }`：捕获指定类型的异常，`e` 是异常对象，`e.message` 是错误描述。
- `finally { ... }`：无论是否发生异常，都会执行的代码（常用于清理资源）。

类比现实：`try-catch` 就像核电站的应急预案——正常情况下按流程操作（`try`），一旦出现事故（异常），立即启动应急响应（`catch`），最终无论如何都要做收尾工作（`finally`）。

<!-- check:run -->
```cangjie
func connectToCloud() {
    let networkAvailable = false
    if (!networkAvailable) {
        throw Exception("云端连接超时")
    }
    println("云端同步成功")
}

main() {
    println("正在初始化云服务...")

    try {
        connectToCloud()
    } catch (e: Exception) {
        println("❌ 严重错误: " + e.message)
        println("🔄 正在切换至离线本地模式...")
    } finally {
        println("初始化流程结束")
    }
}
```

<!-- expected_output:
正在初始化云服务...
❌ 严重错误: 云端连接超时
🔄 正在切换至离线本地模式...
初始化流程结束
-->

**代码解析**：
- `throw Exception("云端连接超时")`：创建并抛出一个异常对象，携带错误描述信息。异常会中断当前函数的执行，沿调用栈向上传播，直到被某个 `catch` 块捕获。
- `try { connectToCloud() }`：将可能抛出异常的调用包在 `try` 块中。
- `catch (e: Exception)`：捕获 `Exception` 类型的异常。`e.message` 获取异常携带的错误信息字符串。
- `finally { println("初始化流程结束") }`：不管 `connectToCloud()` 是否抛出异常，`finally` 块总会执行。这里用于输出"初始化流程结束"，确保日志完整性。
- 降级逻辑 `"🔄 正在切换至离线本地模式..."` 在 `catch` 中执行，体现了"有损服务降级"的工程思维：连接失败不等于系统崩溃，可以切换到备用模式继续工作。

## 3. 指令解析 (Pattern Matching)

用户通过语音控制发送指令，系统需要解析意图。

**枚举（Enum）与模式匹配**

第八章的另一个主角是**枚举类型（enum）**和**模式匹配（match）**的组合。枚举定义了一组有限的、互斥的状态或选项。仓颉的枚举非常强大——每个枚举构造器（case）可以携带不同类型和数量的关联数据。

`VoiceCommand` 枚举表示所有可能的语音指令类型：
- `TurnOn(String)`：携带一个字符串（目标设备名）的"开启"指令。
- `SetTemp(Int64)`：携带一个整数（目标温度）的"设温"指令。
- `QueryStatus`：不携带任何数据的"查询状态"指令。

**模式匹配（match）** 是处理枚举的最佳工具。它强制你为每种可能的枚举值提供处理逻辑（穷举性检查），不会遗漏任何分支。与一长串 `if-else if` 相比，`match` 结构更清晰，编译器也能验证你没有遗漏情况。

类比现实：`match` 就像快递分拣系统——每个包裹（`VoiceCommand` 值）都会被识别类型（`TurnOn`/`SetTemp`/`QueryStatus`），然后送往对应的处理流水线（`case` 分支），绝不会出现包裹没人处理的情况。

<!-- check:run -->
```cangjie
enum VoiceCommand {
    | TurnOn(String)       // "打开 X"
    | SetTemp(Int64)       // "设置温度为 X"
    | QueryStatus          // "查询状态"
}

func execute(cmd: VoiceCommand) {
    match (cmd) {
        case TurnOn(dev) => println("执行: 开启设备 -> ${dev}")
        case SetTemp(t) => println("执行: 设定温控 -> ${t}°C")
        case QueryStatus => println("执行: 播报全屋状态")
    }
}

main() {
    let cmd = SetTemp(26)
    execute(cmd)
}
```

<!-- expected_output:
执行: 设定温控 -> 26°C
-->

**代码解析**：
- `enum VoiceCommand { | TurnOn(String) | SetTemp(Int64) | QueryStatus }`：定义携带关联数据的枚举。`|` 分隔每个构造器，类似数学中"或"的含义。
- `match (cmd) { case TurnOn(dev) => ... case SetTemp(t) => ... case QueryStatus => ... }`：对 `cmd` 进行模式匹配。`case SetTemp(t)` 不仅匹配了类型，还将携带的整数值绑定到变量 `t`，一步完成类型检查和数据解构。
- `let cmd = SetTemp(26)`：创建一个 `SetTemp` 类型的枚举值，携带整数 26。
- 由于 `cmd` 是 `SetTemp(26)`，运行时进入第二个 `case` 分支，`t` 被绑定为 26，输出"设定温控 -> 26°C"。

**💡 核心要点**

*   **`Option<T>`**：`Some(值)` 或 `None`，用于表达"可能为空"的结果，强制调用者处理空值情况，从根源上消灭空指针异常。
*   **`try-catch-finally`**：异常捕获机制，`try` 包裹危险操作，`catch` 处理异常，`finally` 确保清理逻辑总是执行。
*   **枚举（enum）+ 模式匹配（match）**：枚举描述有限状态集合，模式匹配进行穷举处理，编译器验证覆盖完整性，是处理多状态逻辑的最佳组合。
*   错误处理的黄金原则：可预期的"无结果"用 `Option`，异常情况用 `throw`/`catch`，不要用异常来控制正常业务流程。

## 4. 未捕获异常的危害

如果关键操作没有 `try-catch` 保护，未捕获的异常会导致系统直接崩溃，影响所有设备。下面的代码展示了这种危险情况：

<!-- check:runtime_error -->
```cangjie
func initSensor(name: String) {
    if (name == "") {
        throw Exception("传感器名称不能为空")
    }
    println("传感器 ${name} 已就绪")
}

main() {
    initSensor("温度计")
    initSensor("")  // 未捕获异常 → 系统崩溃！
}
```

这就是为什么每个关键路径都需要容错保护。

## 工程化提示

*   设备离线属于可预期错误，优先使用返回值而非抛异常。
*   `try-catch` 中至少记录关键上下文，避免问题难以排查。
*   语音指令要设置兜底分支，处理无法识别的输入。

## 小试身手

1. 为 `VoiceCommand` 增加 `TurnOff` 分支，并在 `execute` 中处理。
2. 当设备离线时返回默认状态信息，避免上层崩溃。
