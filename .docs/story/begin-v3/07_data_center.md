# 第七章：数据中心 (集合与泛型)

> 智能家居系统连接了上百个设备，分布在不同房间。我们需要高效的数据结构来管理这些设备列表和配置信息，并为后续的状态汇总提供支撑。

## 本章目标

*   掌握哈希表与列表的典型应用场景。
*   学会用泛型配置结构承载不同类型的参数。
*   理解缓存数据在可视化与分析中的作用。

## 1. 房间设备管理 (HashMap)

我们需要根据房间名快速查找该房间内的所有设备 ID。

**什么是 HashMap？**

`HashMap`（哈希表）是一种"键值对"数据结构，就像一本字典：你用一个"词条"（键，Key）来快速查找对应的"解释"（值，Value）。无论字典有多厚，查一个词的速度都是一样快的——这是哈希表的核心优势：**O(1) 时间复杂度的查找性能**。

类比现实：把 `HashMap<String, ArrayList<String>>` 想象成一个"楼层索引板"——索引板上每一行写着房间名（Key），旁边挂着该房间设备清单（Value，一个列表）。保安要找"客厅有哪些设备"，只需要在索引板上一眼就能找到对应清单，而不需要挨个房间搜查。

**`ArrayList` 是什么？**

`ArrayList`（动态数组）是可以按需增长的列表。与固定大小的数组不同，你可以随时用 `.add()` 向末尾追加元素，它会自动扩容。`HashMap` 中存储 `ArrayList` 是一种"一对多"映射关系的常见模式：一个房间对应多个设备。

使用 `import std.collection.*` 可以导入标准库中所有集合相关的类型，包括 `HashMap` 和 `ArrayList`。

<!-- check:run -->
```cangjie
import std.collection.*

main() {
    // Key: 房间名, Value: 设备ID列表
    let roomDevices = HashMap<String, ArrayList<String>>()

    // 初始化客厅
    let livingList = ArrayList<String>()
    livingList.add("L-001 (Main Light)")
    livingList.add("AC-001 (Air Conditioner)")
    roomDevices["Living Room"] = livingList

    // 初始化卧室
    let bedList = ArrayList<String>()
    bedList.add("L-002 (Bed Light)")
    roomDevices["Bedroom"] = bedList

    // 查询客厅有哪些设备
    if (roomDevices.contains("Living Room")) {
        println("客厅设备清单:")
        for (dev in roomDevices["Living Room"]) {
            println("- " + dev)
        }
    }
}
```

<!-- expected_output:
客厅设备清单:
- L-001 (Main Light)
- AC-001 (Air Conditioner)
-->

**代码解析**：
- `HashMap<String, ArrayList<String>>()`：创建一个空 `HashMap`，键类型为 `String`，值类型为 `ArrayList<String>`。尖括号内的类型参数告诉编译器"这个 Map 里存什么类型"。
- `roomDevices["Living Room"] = livingList`：用下标语法 `[key] = value` 向 Map 中插入或更新键值对，语法直观。
- `roomDevices.contains("Living Room")`：在查询前先检查键是否存在，避免访问不存在的键导致错误。这是使用 `HashMap` 的标准安全模式。
- `for (dev in roomDevices["Living Room"])`：直接遍历某个键对应的 `ArrayList`，配合 `for-in` 可以非常简洁地处理集合中的每个元素。

**💡 核心要点**

*   `HashMap<K, V>` 提供 O(1) 平均时间复杂度的查找、插入和删除，非常适合"按名称/ID 快速查找"的场景。
*   访问 Map 中不存在的键会导致运行时错误，因此在访问前应先用 `.contains(key)` 检查（或使用返回 `Option` 的安全 API）。
*   集合类型参数（如 `<String, ArrayList<String>>`）是仓颉泛型的实例化，下一节将详细介绍泛型的概念。

## 2. 通用配置加载器 (Generics)

系统配置项有多种类型：有的配置是数字（超时时间），有的是字符串（WiFi密码）。我们定义一个泛型配置类。

**什么是泛型（Generics）？**

假设你要编写一个"配置项"结构：有时值是整数，有时是字符串，有时是布尔值。如果为每种类型写一个配置结构（`IntConfigItem`、`StringConfigItem`……），代码会大量重复。**泛型**解决了这个问题：用一个**类型参数**（通常写作 `T`）作为占位符，在实际使用时再指定具体类型。

类比现实：泛型就像一个万用收纳盒的产品模板——模板上说"这个盒子可以装任何东西（`T`）"，你在购买时决定要装积木（`Int64`）还是装首饰（`String`）。盒子的结构（字段和方法）是完全相同的，只是里面装的东西类型不同。

`where T <: ToString` 是泛型约束（Constraint）：它要求类型参数 `T` 必须实现 `ToString` 接口（即能被转换成字符串）。这样在 `printConfig()` 方法中才能安全地将 `value` 插入字符串，编译器也能验证这一点。

<!-- check:run -->
```cangjie
struct ConfigItem<T> where T <: ToString {
    let key: String
    let value: T

    public init(key: String, value: T) {
        this.key = key
        this.value = value
    }

    public func printConfig() {
        println("配置项 [${key}] = ${value}")
    }
}

main() {
    // 整数类型的配置
    let timeout = ConfigItem<Int64>("TimeoutMS", 5000)
    timeout.printConfig()

    // 字符串类型的配置
    let wifi = ConfigItem<String>("SSID", "MySmartHome_5G")
    wifi.printConfig()
}
```

<!-- expected_output:
配置项 [TimeoutMS] = 5000
配置项 [SSID] = MySmartHome_5G
-->

**代码解析**：
- `struct ConfigItem<T> where T <: ToString`：声明一个带类型参数 `T` 的泛型结构体。`where` 子句增加了约束：`T` 必须实现 `ToString` 接口。
- `let value: T`：字段类型使用类型参数 `T`，将在实例化时确定具体类型。
- `ConfigItem<Int64>("TimeoutMS", 5000)`：用具体类型 `Int64` 实例化泛型结构体，此时编译器知道 `value` 的类型是 `Int64`。
- `"${value}"`：由于 `T` 被约束为 `ToString`，编译器知道 `value` 一定可以转换成字符串，这里的字符串插值是类型安全的。

## 3. 历史数据缓存 (ArrayList)

我们需要缓存最近 10 条温度记录用于绘图。

**`ArrayList` 的典型使用场景**

`ArrayList` 是有序的可变列表，最适合需要按顺序存储、遍历、动态增减的数据集合。与 `HashMap` 的"按键随机访问"不同，`ArrayList` 更擅长"按顺序处理所有元素"。

在时序数据场景（如传感器历史记录、操作日志）中，`ArrayList` 是最自然的选择：数据按时间顺序追加，遍历时也按同样顺序读取。

`Float64(history.size)` 是显式类型转换，将 `Int64` 类型的 `size` 转换为 `Float64`，以便进行浮点数除法（若不转换，整数除法会丢弃小数部分）。

<!-- check:run -->
```cangjie
import std.collection.*

main() {
    let history = ArrayList<Float64>()

    // 模拟存入数据
    history.add(23.5)
    history.add(23.6)
    history.add(23.8)

    println("缓存记录数: ${history.size}")

    // 计算平均温
    var sum = 0.0
    for (val in history) { sum = sum + val }
    println("平均温度: ${sum / Float64(history.size)}")
}
```

<!-- expected_output:
缓存记录数: 3
平均温度: 23.633333
-->

**代码解析**：
- `let history = ArrayList<Float64>()`：创建一个空的浮点数动态列表，类型参数 `<Float64>` 指定列表中只能存放 `Float64` 类型的值。
- `history.add(23.5)`：向列表末尾追加一个元素，`ArrayList` 会自动管理内存扩容。
- `history.size`：只读属性，返回当前列表中的元素个数（`Int64` 类型）。
- `for (val in history) { sum = sum + val }`：遍历 `ArrayList` 中的每个元素，仓颉的 `for-in` 循环可以直接用于任何实现了 `Iterable` 接口的集合。
- `sum / Float64(history.size)`：计算平均值时，需要将元素个数转换为 `Float64` 以进行浮点除法，否则会执行整数除法导致精度损失。

**💡 核心要点**

*   **泛型**允许编写一次代码适用于多种类型，通过类型参数 `<T>` 实现。泛型约束 `where T <: 接口名` 确保类型参数满足必要的能力要求。
*   **`ArrayList<T>`**：有序、可动态增长的列表，适合顺序存储和遍历；`.add()` 追加、`.size` 获取长度。
*   **`HashMap<K, V>`**：键值对映射，适合按键快速查找；下标语法 `[key]` 读写，`.contains()` 检查键存在性。
*   数值类型间的运算通常需要显式类型转换（如 `Float64(整数值)`），仓颉不会自动进行隐式类型提升，以避免潜在的精度问题。

## 工程化提示

*   房间设备映射应考虑同步更新机制，避免配置漂移。
*   泛型配置建议配合校验规则，确保值合法。
*   历史数据缓存要控制容量，避免内存持续增长。

## 小试身手

1. 为 `roomDevices` 增加"删除设备"逻辑，并在输出中验证。
2. 将温度缓存改为固定容量（超过 10 条时移除最旧记录）。
