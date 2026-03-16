# 第六章：状态管理 (枚举与模式匹配)

> Web 应用通常需要管理复杂的状态（如订单状态、用户登录态）。枚举和模式匹配是处理状态机的最佳利器，能让流转逻辑可读且可控。

## 本章目标

*   学会用枚举表达有限状态集合。
*   理解模式匹配在状态流转校验中的作用。
*   建立"合法流转 + 明确兜底"的状态机思维。

在现实的业务系统中，状态管理是引发 Bug 的重灾区。例如，一个订单可能处于"已创建"、"已支付"、"已发货"、"已完成"或"已取消"等状态，每种状态只允许特定的后续操作：你不能在未支付的情况下直接发货，也不能对已完成的订单再次支付。这种"特定状态下只允许特定操作"的规则，就是**有限状态机（Finite State Machine，FSM）**的本质。

如果用零散的 `if-else` 或字符串常量管理这些状态，代码极易出现遗漏某个状态的 Bug，且随着状态增多，分支组合会呈指数级增长，变得无法维护。仓颉的**枚举 + 模式匹配**组合提供了编译期穷举保证：你必须处理所有枚举分支，编译器会拒绝不完整的 `match` 表达式。这将"遗漏状态"从运行时 Bug 提前变为编译错误。

## 1. 状态定义 (Enum)

一个订单的生命周期。

仓颉枚举支持**关联数据（Associated Values）**，这是它比普通枚举更强大的地方。`Paid(Float64)` 表示"已支付"状态同时携带支付金额，`Shipped(String)` 携带快递单号，`Cancelled(String)` 携带取消原因。这样，状态和与之相关的数据被绑定在一起，形成一个自描述的数据单元，避免了用额外字段（如 `payAmount`、`trackingNo`）管理状态相关数据的混乱。

<!-- check:run project=state_management -->
```cangjie
enum OrderState {
    | Created
    | Paid(Float64) // 携带支付金额
    | Shipped(String) // 携带快递单号
    | Completed
    | Cancelled(String) // 携带取消原因
}
```

## 2. 状态流转 (Pattern Matching)

根据当前状态决定下一步操作，防止非法流转（例如从 Created 直接变 Completed）。

`next` 方法使用了**元组模式匹配** `match ((current, action))`，将当前状态和动作字符串组合成一个二元组，然后一次性匹配所有合法的"状态+动作"组合。这种写法极具表达力：每一行 `case` 对应一条合法的状态流转规则，就像一张状态转移表，逻辑一目了然。`Paid(_)` 中的通配符 `_` 表示"匹配任意支付金额"——我们关心的是当前处于"已支付"状态，具体金额无关紧要。最后的 `case _` 捕获所有非法流转组合，这是**兜底策略**：永远确保有明确的"默认处理"，不留遗漏。

<!-- check:run project=state_management -->
```cangjie
class OrderManager {
    public func process(state: OrderState) {
        match (state) {
            case Created =>
                println("订单已创建，等待支付...")

            case Paid(amount) =>
                println("订单已支付 ${amount}，准备发货...")

            case Shipped(trackingNo) =>
                println("订单已发货，单号: ${trackingNo}")

            case Completed =>
                println("订单完成。")

            case Cancelled(reason) =>
                println("订单取消，原因: ${reason}")
        }
    }

    // 状态机转换检查
    public func next(current: OrderState, action: String): OrderState {
        match ((current, action)) {
            // (当前状态, 动作) => 新状态
            case (Created, "pay") => Paid(100.0)
            case (Paid(_), "ship") => Shipped("SF123456")
            case (Shipped(_), "receive") => Completed
            case (_, "cancel") => Cancelled("用户主动取消")
            case _ =>
                println("非法状态流转！")
                current // 保持原状
        }
    }
}

main() {
    let manager = OrderManager()

    var state = Created
    manager.process(state)

    // 支付
    state = manager.next(state, "pay")
    manager.process(state)

    // 尝试非法操作：未发货直接收货
    state = manager.next(state, "receive")
}
```

<!-- expected_output:
订单已创建，等待支付...
订单已支付 100.000000，准备发货...
非法状态流转！
-->

**代码解析：**

- `var state = Created`：用 `var` 声明可变变量，初始状态为 `Created`。后续通过重新赋值来模拟状态流转——注意 `OrderState` 是值类型（枚举），赋值操作创建新值而非修改原有对象。
- `manager.process(state)`：`process` 函数对当前状态进行分支处理，`case Paid(amount)` 同时解构出关联数据 `amount`（支付金额），并在输出中使用——`100.000000` 是浮点数的默认格式化输出。
- `manager.next(state, "receive")`：此时 `state` 为 `Paid(100.0)`，动作为 `"receive"`，没有任何 `case` 能匹配 `(Paid(_), "receive")` 这个组合，因此命中兜底 `case _`，打印"非法状态流转！"并返回原状态。
- 整个流程验证了状态机的核心价值：**非法流转被编码层面拦截**，业务逻辑不会进入"不一致状态"。

**💡 核心要点**

- **带关联数据的枚举**：每个枚举分支可携带不同类型的数据，状态与其上下文数据绑定在一起，消除"额外字段"的混乱。
- **元组模式匹配**：`match ((state, action))` 同时匹配多个维度，将状态转移表以代码形式直观表达。
- **通配符 `_`**：在模式匹配中忽略不关心的部分（如 `Paid(_)` 忽略具体金额），使 `match` 分支更简洁。
- **兜底 `case _`**：确保所有情况都有处理，是防御性编程的重要实践，将"遗漏状态"变为可控输出。

## 工程化提示

*   状态机应集中管理流转规则，避免散落在多处业务逻辑。
*   对外暴露的动作建议使用枚举而不是字符串，减少拼写错误。
*   状态变更需要记录操作日志，便于审计与回溯。

## 小试身手

1. 增加 `Refunded` 状态，并补充对应流转逻辑。
2. 将 `action` 改为枚举类型，减少非法输入。
