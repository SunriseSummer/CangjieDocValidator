# 测试报告

- **扫描目录**: `.docs/language/source_zh_cn/`
- **生成时间**: 2026-03-15 16:17:04 UTC
- **文档文件数**: 106

## 总览

| 指标 | 数量 |
|------|------|
| ❌ 测试总数 | 657 |
| ✅ 通过 | 656 |
| ❌ 失败 | 1 |
| ⏭️ 跳过 | 51 |
| ⚠️ 未标注 | 0 |

## 文件详情

### ✅ `.docs/language/source_zh_cn/Appendix/compile_options.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| `--package`, `-p` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--package`, `-p` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--module-name <value>` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--module-name <value>` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--library-path <value>`, `-L <value>`, `-L<value>` | `ast` | ✅ PASS |
| `--import-path <value>` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--scan-dependency` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--test` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--test` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--test` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--test-only` <sup>[frontend]</sup> | `ast` | ✅ PASS |
| `--obf-config <file>` | `ast` | ✅ PASS |
| `--test-only` <sup>[frontend]</sup> | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Basic_IO/basic_IO_overview.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 输入流 | `ast` | ✅ PASS |
| 输出流 | `ast` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Basic_IO/basic_IO_process_stream.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 缓冲流 | `build_only` | ✅ PASS |
| 缓冲流 | `run` | ✅ PASS |
| 缓冲流 | `run` | ✅ PASS |
| 字符串流 | `build_only` | ✅ PASS |
| 字符串流 | `run` | ✅ PASS |
| 字符串流 | `run` | ✅ PASS |

### ❌ `.docs/language/source_zh_cn/Basic_IO/basic_IO_source_stream.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 文件流操作 | `ast` | ✅ PASS |
| 文件流操作 | `ast` | ✅ PASS |
| 标准流 | `build_only` | ✅ PASS |
| 标准流 | `run` | ✅ PASS |
| 文件流 | `build_only` | ✅ PASS |
| 常规文件操作 | `run` | ✅ PASS |
| 常规文件操作 | `build_only` | ✅ PASS |
| 常规文件操作 | `build_only` | ✅ PASS |
| 文件流操作 | `run` | ❌ FAIL |
| 文件流操作 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/FFI/cangjie-c.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| CFunc | `ast` | ✅ PASS |
| CFunc | `ast` | ✅ PASS |
| 结构体 | `ast` | ✅ PASS |
| 指针 | `ast` | ✅ PASS |
| 数组 | `ast` | ✅ PASS |
| sizeOf/alignOf | `ast` | ✅ PASS |
| C 调用仓颉的函数 | `ast` | ✅ PASS |
| C 调用仓颉的函数 | `ast` | ✅ PASS |
| 示例 | `ast` | ✅ PASS |
| 仓颉调用 C 的函数 | `run` | ✅ PASS |
| 仓颉调用 C 的函数 | `compile_error` | ✅ PASS |
| CFunc | `run` | ✅ PASS |
| inout 参数 | `compile_error` | ✅ PASS |
| unsafe | `run` | ✅ PASS |
| unsafe | `run` | ✅ PASS |
| 调用约定 | `run` | ✅ PASS |
| 使用说明 | `build_only` | ✅ PASS |
| 结构体 | `build_only` | ✅ PASS |
| 指针 | `run` | ✅ PASS |
| 指针 | `run` | ✅ PASS |
| 指针 | `run` | ✅ PASS |
| 数组 | `build_only` | ✅ PASS |
| 数组 | `build_only` | ✅ PASS |
| 字符串 | `run` | ✅ PASS |
| sizeOf/alignOf | `run` | ✅ PASS |
| CType | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/Tokens_types_and_quote_expressions.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| Token 类型 | `ast` | ✅ PASS |
| Tokens 类型 | `run` | ✅ PASS |
| quote 表达式和插值 | `run` | ✅ PASS |
| quote 表达式和插值 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/builtin_compilation_flags.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 源码位置 | `ast` | ✅ PASS |
| @FastNative | `ast` | ✅ PASS |
| @Frozen | `ast` | ✅ PASS |
| @Attribute | `ast` | ✅ PASS |
| @Attribute | `build_only` | ✅ PASS |
| @Deprecated | `run` | ✅ PASS |
| @Deprecated 参数 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/compiling_error_reporting_and_debugging.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 宏的编译和使用 | `ast` | ✅ PASS |
| 并行宏展开 | `ast` | ✅ PASS |
| diagReport 报错机制 | `ast` | ✅ PASS |
| diagReport 报错机制 | `ast` | ✅ PASS |
| diagReport 报错机制 | `ast` | ✅ PASS |
| 使用 --debug-macro 输出宏展开结果 | `ast` | ✅ PASS |
| 使用 --debug-macro 输出宏展开结果 | `ast` | ✅ PASS |
| 使用 --debug-macro 输出宏展开结果 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/defining_and_importing_macro_package.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 宏包定义和导入 | `ast` | ✅ PASS |
| 宏包定义和导入 | `ast` | ✅ PASS |
| 宏包定义和导入 | `ast` | ✅ PASS |
| 宏包定义和导入 | `ast` | ✅ PASS |
| 宏包定义和导入 | `ast` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/implementation_of_macros.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 非属性宏 | `ast` | ✅ PASS |
| 属性宏 | `ast` | ✅ PASS |
| 属性宏 | `ast` | ✅ PASS |
| 宏定义中嵌套宏调用 | `ast` | ✅ PASS |
| 宏调用中嵌套宏调用 | `ast` | ✅ PASS |
| 宏调用中嵌套宏调用 | `ast` | ✅ PASS |
| 宏调用中嵌套宏调用 | `ast` | ✅ PASS |
| 嵌套宏之间的消息传递 | `ast` | ✅ PASS |
| 嵌套宏之间的消息传递 | `ast` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/macro_introduction.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 宏的简介 | `ast` | ✅ PASS |
| 宏的简介 | `ast` | ✅ PASS |
| 宏的简介 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/practical_case.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 快速幂的计算 | `ast` | ✅ PASS |
| 快速幂的计算 | `ast` | ✅ PASS |
| 快速幂的计算 | `ast` | ✅ PASS |
| 快速幂的计算 | `ast` | ✅ PASS |
| 快速幂的计算 | `ast` | ✅ PASS |
| 快速幂的计算 | `ast` | ✅ PASS |
| Memoize 宏 | `ast` | ✅ PASS |
| Memoize 宏 | `ast` | ✅ PASS |
| 一个 dprint 宏的扩展 | `ast` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Macro/syntax_node.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 使用语法节点的构造函数来解析 Tokens | `ast` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Net/net_http.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| HTTP 编程 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Net/net_socket.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| TCP 编程 | `run` | ✅ PASS |
| UDP 编程 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/Net/net_websocket.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| WebSocket 编程 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/array.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| Array | `build_only` | ✅ PASS |
| Array | `compile_error` | ✅ PASS |
| Array | `build_only` | ✅ PASS |
| Array | `build_only` | ✅ PASS |
| 访问 Array 成员 | `run` | ✅ PASS |
| 访问 Array 成员 | `run` | ✅ PASS |
| 访问 Array 成员 | `compile_error` | ✅ PASS |
| 访问 Array 成员 | `build_only` | ✅ PASS |
| 访问 Array 成员 | `build_only` | ✅ PASS |
| 修改 Array | `run` | ✅ PASS |
| 修改 Array | `run` | ✅ PASS |
| VArray | `compile_error` | ✅ PASS |
| VArray | `build_only` | ✅ PASS |
| VArray | `build_only` | ✅ PASS |
| VArray | `run` | ✅ PASS |
| VArray | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/basic_operators.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 赋值操作符 | `compile_error` | ✅ PASS |
| 赋值操作符 | `run` | ✅ PASS |
| 算术操作符 | `build_only` | ✅ PASS |
| 算术操作符 | `build_only` | ✅ PASS |
| 算术操作符 | `build_only` | ✅ PASS |
| 复合赋值操作符 | `run` | ✅ PASS |
| 复合赋值操作符 | `run` | ✅ PASS |
| 关系操作符 | `run` | ✅ PASS |
| 关系操作符 | `compile_error` | ✅ PASS |
| coalescing 操作符 | `run` | ✅ PASS |
| 逻辑操作符 | `build_only` | ✅ PASS |
| 逻辑操作符 | `run` | ✅ PASS |
| 逻辑操作符 | `run` | ✅ PASS |
| 位运算操作符 | `run` | ✅ PASS |
| 自增自减操作符 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/bool.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 布尔类型字面量 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/characters.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 字符类型字面量 | `build_only` | ✅ PASS |
| 字符类型字面量 | `build_only` | ✅ PASS |
| 字符类型字面量 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/float.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 浮点类型字面量 | `build_only` | ✅ PASS |
| 浮点类型字面量 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/integer.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 整数类型字面量 | `compile_error` | ✅ PASS |
| 整数类型字面量 | `build_only` | ✅ PASS |
| 字符字节字面量 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/nothing.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| Nothing 类型 | `compile_error` | ✅ PASS |
| Nothing 类型 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/range.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 区间类型 | `build_only` | ✅ PASS |
| 区间类型字面量 | `build_only` | ✅ PASS |
| 区间类型字面量 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/strings.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 字符串字面量 | `build_only` | ✅ PASS |
| 字符串字面量 | `build_only` | ✅ PASS |
| 字符串字面量 | `build_only` | ✅ PASS |
| 字符串字面量 | `run` | ✅ PASS |
| 插值字符串 | `run` | ✅ PASS |
| 字符串类型支持的操作 | `run` | ✅ PASS |
| 字符串类型支持的操作 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_data_type/tuple.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 元组类型 | `compile_error` | ✅ PASS |
| 元组类型的字面量 | `build_only` | ✅ PASS |
| 元组类型的字面量 | `run` | ✅ PASS |
| 元组类型的类型参数 | `run` | ✅ PASS |
| 元组类型的类型参数 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_programming_concepts/expression.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| if 表达式 | `run` | ✅ PASS |
| if 表达式 | `compile_error` | ✅ PASS |
| if 表达式 | `run` | ✅ PASS |
| if 表达式 | `compile_error` | ✅ PASS |
| if 表达式 | `compile_error` | ✅ PASS |
| if 表达式 | `run` | ✅ PASS |
| 涉及 “let pattern” 的“条件”示例 | `run` | ✅ PASS |
| 涉及 “let pattern” 的“条件”示例 | `compile_error` | ✅ PASS |
| 错误的表达式示例 | `compile_error` | ✅ PASS |
| while 表达式 | `run` | ✅ PASS |
| do-while 表达式 | `run` | ✅ PASS |
| for-in 表达式 | `run` | ✅ PASS |
| 遍历区间 | `run` | ✅ PASS |
| 遍历元组构成的序列 | `run` | ✅ PASS |
| 迭代变量不可修改 | `compile_error` | ✅ PASS |
| 使用通配符 _ 代替迭代变量 | `run` | ✅ PASS |
| where 条件 | `run` | ✅ PASS |
| break 与 continue 表达式 | `run` | ✅ PASS |
| break 与 continue 表达式 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_programming_concepts/function.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 函数 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/basic_programming_concepts/program_structure.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 程序结构 | `run` | ✅ PASS |
| 程序结构 | `run` | ✅ PASS |
| 变量 | `run` | ✅ PASS |
| 变量 | `compile_error` | ✅ PASS |
| 变量 | `run` | ✅ PASS |
| 变量 | `run` | ✅ PASS |
| 变量 | `compile_error` | ✅ PASS |
| 变量 | `compile_error` | ✅ PASS |
| 变量 | `compile_error` | ✅ PASS |
| 变量 | `compile_error` | ✅ PASS |
| `const` 变量 | `compile_error` | ✅ PASS |
| 值类型和引用类型变量 | `run` | ✅ PASS |
| 值类型和引用类型变量 | `compile_error` | ✅ PASS |
| 作用域 | `run` | ✅ PASS |
| `const` 变量 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/class_and_interface/class.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| class 成员的访问修饰符 | `ast` | ✅ PASS |
| class 定义 | `build_only` | ✅ PASS |
| class 定义 | `build_only` | ✅ PASS |
| class 成员变量 | `build_only` | ✅ PASS |
| class 成员变量 | `build_only` | ✅ PASS |
| class 静态初始化器 | `build_only` | ✅ PASS |
| class 静态初始化器 | `compile_error` | ✅ PASS |
| class 构造函数 | `compile_error` | ✅ PASS |
| class 构造函数 | `compile_error` | ✅ PASS |
| class 构造函数 | `build_only` | ✅ PASS |
| class 构造函数 | `build_only` | ✅ PASS |
| class 构造函数 | `run` | ✅ PASS |
| class 构造函数 | `build_only` | ✅ PASS |
| class 终结器 | `build_only` | ✅ PASS |
| class 终结器 | `run` | ✅ PASS |
| class 成员函数 | `build_only` | ✅ PASS |
| class 成员函数 | `build_only` | ✅ PASS |
| class 成员的访问修饰符 | `compile_error` | ✅ PASS |
| This 类型 | `run` | ✅ PASS |
| 创建对象 | `run` | ✅ PASS |
| 创建对象 | `run` | ✅ PASS |
| 创建对象 | `run` | ✅ PASS |
| class 的继承 | `compile_error` | ✅ PASS |
| class 的继承 | `compile_error` | ✅ PASS |
| class 的继承 | `build_only` | ✅ PASS |
| class 的继承 | `compile_error` | ✅ PASS |
| class 的继承 | `compile_error` | ✅ PASS |
| class 的继承 | `build_only` | ✅ PASS |
| class 的继承 | `compile_error` | ✅ PASS |
| 父类构造函数调用 | `build_only` | ✅ PASS |
| 父类构造函数调用 | `compile_error` | ✅ PASS |
| 覆盖和重定义 | `run` | ✅ PASS |
| 覆盖和重定义 | `run` | ✅ PASS |
| 覆盖和重定义 | `compile_error` | ✅ PASS |
| 覆盖和重定义 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/class_and_interface/interface.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 接口定义 | `ast` | ✅ PASS |
| 接口定义 | `build_only` | ✅ PASS |
| 接口定义 | `compile_error` | ✅ PASS |
| 接口定义 | `build_only` | ✅ PASS |
| 接口定义 | `run` | ✅ PASS |
| 接口定义 | `run` | ✅ PASS |
| 接口定义 | `compile_error` | ✅ PASS |
| 接口定义 | `run` | ✅ PASS |
| 接口定义 | `compile_error` | ✅ PASS |
| 接口定义 | `build_only` | ✅ PASS |
| 接口定义 | `compile_error` | ✅ PASS |
| 接口继承与接口实现 | `build_only` | ✅ PASS |
| 接口继承与接口实现 | `compile_error` | ✅ PASS |
| 接口实现的要求 | `build_only` | ✅ PASS |
| 接口实现的要求 | `build_only` | ✅ PASS |
| 接口实现的要求 | `build_only` | ✅ PASS |
| 接口实现的要求 | `build_only` | ✅ PASS |
| Any 类型 | `build_only` | ✅ PASS |
| Any 类型 | `run` | ✅ PASS |
| 接口继承与接口实现 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/class_and_interface/prop.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 属性 | `run` | ✅ PASS |
| 属性定义 | `build_only` | ✅ PASS |
| 属性定义 | `build_only` | ✅ PASS |
| 修饰符 | `build_only` | ✅ PASS |
| 修饰符 | `build_only` | ✅ PASS |
| 抽象属性 | `build_only` | ✅ PASS |
| 抽象属性 | `build_only` | ✅ PASS |
| 抽象属性 | `run` | ✅ PASS |
| 属性使用 | `run` | ✅ PASS |
| 属性使用 | `compile_error` | ✅ PASS |
| 属性使用 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/class_and_interface/subtype.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 继承 class 带来的子类型关系 | `build_only` | ✅ PASS |
| 实现接口带来的子类型关系 | `build_only` | ✅ PASS |
| 元组类型的子类型关系 | `build_only` | ✅ PASS |
| 函数类型的子类型关系 | `build_only` | ✅ PASS |
| 传递性带来的子类型关系 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/class_and_interface/typecast.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 数值类型之间的转换 | `run` | ✅ PASS |
| `Rune` 到 `UInt32` 和整数类型到 `Rune` 的转换 | `run` | ✅ PASS |
| `is` 和 `as` 操作符 | `run` | ✅ PASS |
| `is` 和 `as` 操作符 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/collections/collection_arraylist.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| ArrayList | `ast` | ✅ PASS |
| ArrayList | `ast` | ✅ PASS |
| ArrayList | `ast` | ✅ PASS |
| ArrayList | `compile_error` | ✅ PASS |
| 访问 ArrayList 成员 | `run` | ✅ PASS |
| 访问 ArrayList 成员 | `run` | ✅ PASS |
| 访问 ArrayList 成员 | `run` | ✅ PASS |
| 修改 ArrayList | `run` | ✅ PASS |
| 修改 ArrayList | `run` | ✅ PASS |
| 修改 ArrayList | `run` | ✅ PASS |
| 修改 ArrayList | `run` | ✅ PASS |
| 修改 ArrayList | `run` | ✅ PASS |
| 增加 ArrayList 的大小 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/collections/collection_hashmap.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| HashMap | `ast` | ✅ PASS |
| HashMap | `ast` | ✅ PASS |
| HashMap | `ast` | ✅ PASS |
| HashMap | `compile_error` | ✅ PASS |
| 访问 HashMap 成员 | `run` | ✅ PASS |
| 访问 HashMap 成员 | `run` | ✅ PASS |
| 访问 HashMap 成员 | `run` | ✅ PASS |
| 访问 HashMap 成员 | `run` | ✅ PASS |
| 修改 HashMap | `run` | ✅ PASS |
| 修改 HashMap | `run` | ✅ PASS |
| 修改 HashMap | `run` | ✅ PASS |
| 修改 HashMap | `run` | ✅ PASS |
| 修改 HashMap | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/collections/collection_hashset.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| HashSet | `ast` | ✅ PASS |
| HashSet | `ast` | ✅ PASS |
| HashSet | `ast` | ✅ PASS |
| HashSet | `compile_error` | ✅ PASS |
| 访问 HashSet 成员 | `run` | ✅ PASS |
| 访问 HashSet 成员 | `run` | ✅ PASS |
| 访问 HashSet 成员 | `run` | ✅ PASS |
| 修改 HashSet | `run` | ✅ PASS |
| 修改 HashSet | `run` | ✅ PASS |
| 修改 HashSet | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/collections/collection_iterable_collections.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| Iterable 和 Collections | `ast` | ✅ PASS |
| Iterable 和 Collections | `ast` | ✅ PASS |
| Iterable 和 Collections | `run` | ✅ PASS |
| Iterable 和 Collections | `run` | ✅ PASS |
| Iterable 和 Collections | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/compile_and_build/cjc_usage.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| `cjc` 基本使用方法 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/compile_and_build/conditional_compilation.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 多条件编译 | `ast` | ✅ PASS |
| 使用方法 | `run` | ✅ PASS |
| 使用方法 | `compile_error` | ✅ PASS |
| 使用方法 | `compile_error` | ✅ PASS |
| os | `run` | ✅ PASS |
| backend | `run` | ✅ PASS |
| arch | `run` | ✅ PASS |
| cjc_version | `run` | ✅ PASS |
| debug | `run` | ✅ PASS |
| test | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/concurrency/concurrency_overview.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 并发概述 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/concurrency/create_thread.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 创建线程 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/concurrency/sleep.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 线程睡眠指定时长 sleep | `ast` | ✅ PASS |
| 线程睡眠指定时长 sleep | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/concurrency/sync.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 原子操作 Atomic | `ast` | ✅ PASS |
| 原子操作 Atomic | `ast` | ✅ PASS |
| Condition | `ast` | ✅ PASS |
| 原子操作 Atomic | `run` | ✅ PASS |
| 原子操作 Atomic | `run` | ✅ PASS |
| 原子操作 Atomic | `run` | ✅ PASS |
| 可重入互斥锁 Mutex | `run` | ✅ PASS |
| 可重入互斥锁 Mutex | `run` | ✅ PASS |
| 可重入互斥锁 Mutex | `build_only` | ✅ PASS |
| 可重入互斥锁 Mutex | `runtime_error` | ✅ PASS |
| 可重入互斥锁 Mutex | `build_only` | ✅ PASS |
| 可重入互斥锁 Mutex | `run` | ✅ PASS |
| Condition | `build_only` | ✅ PASS |
| Condition | `run` | ✅ PASS |
| Condition | `runtime_error` | ✅ PASS |
| Condition | `build_only` | ✅ PASS |
| synchronized 关键字 | `run` | ✅ PASS |
| synchronized 关键字 | `run` | ✅ PASS |
| 线程局部变量 ThreadLocal | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/concurrency/terminal_thread.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 终止线程 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/concurrency/use_thread.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 使用 `Future<T>` 等待线程结束并获取返回值 | `ast` | ✅ PASS |
| 使用 `Future<T>` 等待线程结束并获取返回值 | `run` | ✅ PASS |
| 使用 `Future<T>` 等待线程结束并获取返回值 | `run` | ✅ PASS |
| 使用 `Future<T>` 等待线程结束并获取返回值 | `run` | ✅ PASS |
| 使用 `Future<T>` 等待线程结束并获取返回值 | `run` | ✅ PASS |
| 访问线程属性 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/enum_and_pattern_match/enum.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| enum 的定义 | `build_only` | ✅ PASS |
| enum 的定义 | `build_only` | ✅ PASS |
| enum 的定义 | `build_only` | ✅ PASS |
| enum 的定义 | `build_only` | ✅ PASS |
| enum 的定义 | `build_only` | ✅ PASS |
| enum 的使用 | `run` | ✅ PASS |
| enum 的使用 | `build_only` | ✅ PASS |
| enum 的使用 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/enum_and_pattern_match/match.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| match 表达式的定义 | `run` | ✅ PASS |
| match 表达式的定义 | `compile_error` | ✅ PASS |
| match 表达式的定义 | `build_only` | ✅ PASS |
| match 表达式的定义 | `run` | ✅ PASS |
| match 表达式的定义 | `run` | ✅ PASS |
| match 表达式的类型 | `build_only` | ✅ PASS |
| match 表达式的类型 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/enum_and_pattern_match/option_type.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| Option 类型 | `build_only` | ✅ PASS |
| Option 类型 | `build_only` | ✅ PASS |
| Option 类型 | `build_only` | ✅ PASS |
| Option 类型 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/enum_and_pattern_match/other.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 其他使用模式的地方 | `run` | ✅ PASS |
| 其他使用模式的地方 | `run` | ✅ PASS |
| 其他使用模式的地方 | `run` | ✅ PASS |
| 其他使用模式的地方 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/enum_and_pattern_match/pattern_overview.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 常量模式 | `run` | ✅ PASS |
| 常量模式 | `run` | ✅ PASS |
| 常量模式 | `run` | ✅ PASS |
| 绑定模式 | `run` | ✅ PASS |
| 绑定模式 | `compile_error` | ✅ PASS |
| 绑定模式 | `compile_error` | ✅ PASS |
| 绑定模式 | `compile_error` | ✅ PASS |
| 绑定模式 | `run` | ✅ PASS |
| Tuple 模式 | `run` | ✅ PASS |
| Tuple 模式 | `compile_error` | ✅ PASS |
| enum 模式 | `run` | ✅ PASS |
| enum 模式 | `compile_error` | ✅ PASS |
| enum 模式 | `compile_error` | ✅ PASS |
| enum 模式 | `run` | ✅ PASS |
| 模式的嵌套组合 | `run` | ✅ PASS |
| 类型模式 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/enum_and_pattern_match/pattern_refutability.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 模式的 Refutability | `build_only` | ✅ PASS |
| 模式的 Refutability | `build_only` | ✅ PASS |
| 模式的 Refutability | `build_only` | ✅ PASS |
| 模式的 Refutability | `build_only` | ✅ PASS |
| 模式的 Refutability | `build_only` | ✅ PASS |
| 模式的 Refutability | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/error_handle/exception_overview.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 定义异常 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/error_handle/handle.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 普通 try 表达式 | `run` | ✅ PASS |
| 普通 try 表达式 | `compile_error` | ✅ PASS |
| 普通 try 表达式 | `run` | ✅ PASS |
| 普通 try 表达式 | `run` | ✅ PASS |
| try-with-resources 表达式 | `runtime_error` | ✅ PASS |
| try-with-resources 表达式 | `compile_error` | ✅ PASS |
| try-with-resources 表达式 | `build_only` | ✅ PASS |
| try-with-resources 表达式 | `run` | ✅ PASS |
| CatchPattern 进阶介绍 | `run` | ✅ PASS |
| CatchPattern 进阶介绍 | `run` | ✅ PASS |
| CatchPattern 进阶介绍 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/error_handle/use_option.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 使用 Option | `build_only` | ✅ PASS |
| 使用 Option | `run` | ✅ PASS |
| 使用 Option | `run` | ✅ PASS |
| 使用 Option | `build_only` | ✅ PASS |
| 使用 Option | `run` | ✅ PASS |
| 使用 Option | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/extension/access_rules.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 扩展的导入导出 | `ast` | ✅ PASS |
| 扩展的导入导出 | `ast` | ✅ PASS |
| 扩展的导入导出 | `ast` | ✅ PASS |
| 扩展的导入导出 | `ast` | ✅ PASS |
| 扩展的导入导出 | `ast` | ✅ PASS |
| 扩展的修饰符 | `compile_error` | ✅ PASS |
| 扩展的修饰符 | `run` | ✅ PASS |
| 扩展的修饰符 | `compile_error` | ✅ PASS |
| 扩展的孤儿规则 | `compile_error` | ✅ PASS |
| 扩展的访问和遮盖 | `build_only` | ✅ PASS |
| 扩展的访问和遮盖 | `compile_error` | ✅ PASS |
| 扩展的访问和遮盖 | `compile_error` | ✅ PASS |
| 扩展的访问和遮盖 | `compile_error` | ✅ PASS |
| 扩展的访问和遮盖 | `compile_error` | ✅ PASS |
| 扩展的访问和遮盖 | `compile_error` | ✅ PASS |
| 扩展的导入导出 | `build_only` | ✅ PASS |
| 扩展的导入导出 | `build_only` | ✅ PASS |
| 扩展的导入导出 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/extension/direct_extension.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 直接扩展 | `compile_error` | ✅ PASS |
| 直接扩展 | `compile_error` | ✅ PASS |
| 直接扩展 | `run` | ✅ PASS |
| 直接扩展 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/extension/extend_overview.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 扩展概述 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/extension/interface_extension.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 接口扩展 | `build_only` | ✅ PASS |
| 接口扩展 | `run` | ✅ PASS |
| 接口扩展 | `run` | ✅ PASS |
| 接口扩展 | `run` | ✅ PASS |
| 接口扩展 | `compile_error` | ✅ PASS |
| 接口扩展 | `compile_error` | ✅ PASS |
| 接口扩展 | `run` | ✅ PASS |
| 接口扩展 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/first_understanding/hello_world.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 运行第一个仓颉程序 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/call_functions.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 调用函数 | `run` | ✅ PASS |
| 调用函数 | `run` | ✅ PASS |
| 调用函数 | `run` | ✅ PASS |
| 调用函数 | `run` | ✅ PASS |
| 调用函数 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/closure.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 闭包 | `run` | ✅ PASS |
| 闭包 | `compile_error` | ✅ PASS |
| 闭包 | `compile_error` | ✅ PASS |
| 闭包 | `run` | ✅ PASS |
| 闭包 | `compile_error` | ✅ PASS |
| 闭包 | `compile_error` | ✅ PASS |
| 闭包 | `build_only` | ✅ PASS |
| 闭包 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/const_func_and_eval.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| `const` 函数 | `run` | ✅ PASS |
| `const` 函数 | `run` | ✅ PASS |
| `const init` | `compile_error` | ✅ PASS |
| `const init` | `compile_error` | ✅ PASS |
| `const init` | `compile_error` | ✅ PASS |
| `const init` | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/define_functions.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 定义函数 | `build_only` | ✅ PASS |
| 参数列表 | `build_only` | ✅ PASS |
| 参数列表 | `build_only` | ✅ PASS |
| 参数列表 | `compile_error` | ✅ PASS |
| 参数列表 | `compile_error` | ✅ PASS |
| 参数列表 | `compile_error` | ✅ PASS |
| 函数返回值类型 | `compile_error` | ✅ PASS |
| 函数返回值类型 | `build_only` | ✅ PASS |
| 函数体 | `build_only` | ✅ PASS |
| 函数体 | `compile_error` | ✅ PASS |
| 函数体 | `build_only` | ✅ PASS |
| 函数体 | `build_only` | ✅ PASS |
| 函数体 | `build_only` | ✅ PASS |
| 函数体 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/first_class_citizen.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 函数类型 | `build_only` | ✅ PASS |
| 函数类型 | `build_only` | ✅ PASS |
| 函数类型 | `build_only` | ✅ PASS |
| 函数类型 | `build_only` | ✅ PASS |
| 函数类型的类型参数 | `run` | ✅ PASS |
| 函数类型的类型参数 | `compile_error` | ✅ PASS |
| 函数类型作为参数类型 | `build_only` | ✅ PASS |
| 函数类型作为返回类型 | `run` | ✅ PASS |
| 函数类型作为变量类型 | `build_only` | ✅ PASS |
| 函数类型作为变量类型 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/function_call_desugar.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 尾随 lambda | `build_only` | ✅ PASS |
| 尾随 lambda | `build_only` | ✅ PASS |
| Pipeline 表达式 | `build_only` | ✅ PASS |
| Composition 表达式 | `build_only` | ✅ PASS |
| Composition 表达式 | `build_only` | ✅ PASS |
| Composition 表达式 | `build_only` | ✅ PASS |
| Composition 表达式 | `compile_error` | ✅ PASS |
| Composition 表达式 | `build_only` | ✅ PASS |
| Composition 表达式 | `compile_error` | ✅ PASS |
| Composition 表达式 | `build_only` | ✅ PASS |
| Composition 表达式 | `build_only` | ✅ PASS |
| 变长参数 | `run` | ✅ PASS |
| 变长参数 | `compile_error` | ✅ PASS |
| 变长参数 | `run` | ✅ PASS |
| 变长参数 | `run` | ✅ PASS |
| 变长参数 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/function_overloading.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 函数重载定义 | `build_only` | ✅ PASS |
| 函数重载定义 | `compile_error` | ✅ PASS |
| 函数重载定义 | `build_only` | ✅ PASS |
| 函数重载定义 | `build_only` | ✅ PASS |
| 函数重载定义 | `build_only` | ✅ PASS |
| 函数重载定义 | `build_only` | ✅ PASS |
| 函数重载定义 | `compile_error` | ✅ PASS |
| 函数重载定义 | `compile_error` | ✅ PASS |
| 函数重载定义 | `compile_error` | ✅ PASS |
| 函数重载决议 | `build_only` | ✅ PASS |
| 函数重载决议 | `build_only` | ✅ PASS |
| 函数重载决议 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/lambda.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| Lambda 表达式定义 | `build_only` | ✅ PASS |
| Lambda 表达式定义 | `build_only` | ✅ PASS |
| Lambda 表达式定义 | `run` | ✅ PASS |
| Lambda 表达式定义 | `build_only` | ✅ PASS |
| Lambda 表达式定义 | `run` | ✅ PASS |
| Lambda 表达式定义 | `build_only` | ✅ PASS |
| Lambda 表达式定义 | `build_only` | ✅ PASS |
| Lambda 表达式定义 | `build_only` | ✅ PASS |
| Lambda 表达式调用 | `build_only` | ✅ PASS |
| Lambda 表达式调用 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/nested_functions.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 嵌套函数 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/function/operator_overloading.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 操作符重载函数定义和使用 | `build_only` | ✅ PASS |
| 操作符重载函数定义和使用 | `build_only` | ✅ PASS |
| 操作符重载函数定义和使用 | `build_only` | ✅ PASS |
| 操作符重载函数定义和使用 | `compile_error` | ✅ PASS |
| 操作符重载函数定义和使用 | `run` | ✅ PASS |
| 可以被重载的操作符 | `compile_error` | ✅ PASS |
| 可以被重载的操作符 | `compile_error` | ✅ PASS |
| 操作符重载函数定义和使用 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_class.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型类 | `build_only` | ✅ PASS |
| 泛型类 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_constraint.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型约束 | `ast` | ✅ PASS |
| 泛型约束 | `build_only` | ✅ PASS |
| 泛型约束 | `run` | ✅ PASS |
| 泛型约束 | `compile_error` | ✅ PASS |
| 泛型约束 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_enum.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型枚举 | `ast` | ✅ PASS |
| 泛型枚举 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_function.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 全局泛型函数 | `build_only` | ✅ PASS |
| 局部泛型函数 | `run` | ✅ PASS |
| 泛型成员函数 | `run` | ✅ PASS |
| 泛型成员函数 | `run` | ✅ PASS |
| 静态泛型函数 | `run` | ✅ PASS |
| 全局泛型函数 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_interface.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型接口 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_overview.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型概述 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_struct.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型结构体 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/generic_subtype.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 泛型类型的子类型关系 | `build_only` | ✅ PASS |
| 泛型类型的子类型关系 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/generic/typealias.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 类型别名 | `build_only` | ✅ PASS |
| 类型别名 | `compile_error` | ✅ PASS |
| 类型别名 | `compile_error` | ✅ PASS |
| 类型别名 | `build_only` | ✅ PASS |
| 类型别名 | `build_only` | ✅ PASS |
| 类型别名 | `build_only` | ✅ PASS |
| 类型别名 | `build_only` | ✅ PASS |
| 类型别名 | `compile_error` | ✅ PASS |
| 泛型别名 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/package/entry.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 程序入口 | `run` | ✅ PASS |
| 程序入口 | `run` | ✅ PASS |
| 程序入口 | `compile_error` | ✅ PASS |
| 程序入口 | `compile_error` | ✅ PASS |
| 程序入口 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/package/import.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 使用 `import` 语句导入其他包中的声明或定义 | `ast` | ✅ PASS |
| 使用 `import` 语句导入其他包中的声明或定义 | `ast` | ✅ PASS |
| 使用 `import` 语句导入其他包中的声明或定义 | `ast` | ✅ PASS |
| 使用 `import` 语句导入其他包中的声明或定义 | `ast` | ✅ PASS |
| 使用 `import as` 对导入的名字重命名 | `ast` | ✅ PASS |
| 使用 `import as` 对导入的名字重命名 | `build_only` | ✅ PASS |
| 使用 `import as` 对导入的名字重命名 | `build_only` | ✅ PASS |
| 使用 `import as` 对导入的名字重命名 | `build_only` | ✅ PASS |
| 使用 `import as` 对导入的名字重命名 | `build_only` | ✅ PASS |
| 重导出一个导入的名字 | `compile_error` | ✅ PASS |
| 重导出一个导入的名字 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/package/package_name.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 包的声明 | `ast` | ✅ PASS |
| 包的声明 | `ast` | ✅ PASS |
| 包的声明 | `ast` | ✅ PASS |
| 包的声明 | `ast` | ✅ PASS |
| 包的声明 | `ast` | ✅ PASS |
| 包的声明 | `run` | ✅ PASS |
| 包的声明 | `build_only` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/package/toplevel_access.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 顶层声明的可见性 | `build_only` | ✅ PASS |
| 顶层声明的可见性 | `compile_error` | ✅ PASS |
| 顶层声明的可见性 | `compile_error` | ✅ PASS |
| 顶层声明的可见性 | `compile_error` | ✅ PASS |
| 顶层声明的可见性 | `compile_error` | ✅ PASS |
| 顶层声明的可见性 | `build_only` | ✅ PASS |
| 顶层声明的可见性 | `build_only` | ✅ PASS |
| 顶层声明的可见性 | `build_only` | ✅ PASS |
| 顶层声明的可见性 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/reflect_and_annotation/anno.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 测试框架内置编译标记 | `ast` | ✅ PASS |
| 确保正确使用整数运算溢出策略的内置编译标记 | `runtime_error` | ✅ PASS |
| 确保正确使用整数运算溢出策略的内置编译标记 | `compile_error` | ✅ PASS |
| 确保正确使用整数运算溢出策略的内置编译标记 | `run` | ✅ PASS |
| 确保正确使用整数运算溢出策略的内置编译标记 | `run` | ✅ PASS |
| 确保正确使用整数运算溢出策略的内置编译标记 | `build_only` | ✅ PASS |
| 确保正确使用整数运算溢出策略的内置编译标记 | `run` | ✅ PASS |
| 测试框架内置编译标记 | `build_only` | ✅ PASS |
| 自定义注解 | `run` | ✅ PASS |
| 自定义注解 | `run` | ✅ PASS |
| 自定义注解 | `compile_error` | ✅ PASS |
| 自定义注解 | `run` | ✅ PASS |
| 自定义注解 | `build_only` | ✅ PASS |
| 自定义注解 | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/reflect_and_annotation/dynamic_feature.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 如何获得 TypeInfo | `ast` | ✅ PASS |
| 如何获得 TypeInfo | `ast` | ✅ PASS |
| 如何获得 TypeInfo | `run` | ✅ PASS |
| 如何获得 TypeInfo | `compile_error` | ✅ PASS |
| 如何获得 TypeInfo | `runtime_error` | ✅ PASS |
| 如何使用反射访问成员 | `run` | ✅ PASS |
| 如何使用反射访问成员 | `run` | ✅ PASS |
| 如何使用反射访问成员 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/struct/create_instance.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| 创建 struct 实例 | `build_only` | ✅ PASS |
| 创建 struct 实例 | `run` | ✅ PASS |
| 创建 struct 实例 | `run` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/struct/define_struct.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| struct 成员的访问修饰符 | `ast` | ✅ PASS |
| 定义 struct 类型 | `build_only` | ✅ PASS |
| struct 成员变量 | `build_only` | ✅ PASS |
| struct 静态初始化器 | `build_only` | ✅ PASS |
| struct 静态初始化器 | `compile_error` | ✅ PASS |
| struct 构造函数 | `compile_error` | ✅ PASS |
| struct 构造函数 | `compile_error` | ✅ PASS |
| struct 构造函数 | `build_only` | ✅ PASS |
| struct 构造函数 | `build_only` | ✅ PASS |
| struct 构造函数 | `build_only` | ✅ PASS |
| struct 成员函数 | `build_only` | ✅ PASS |
| struct 成员函数 | `build_only` | ✅ PASS |
| struct 成员的访问修饰符 | `compile_error` | ✅ PASS |
| 禁止递归 struct | `compile_error` | ✅ PASS |

### ✅ `.docs/language/source_zh_cn/struct/mut.md`

| 测试用例 | 类型 | 结果 |
|----------|------|------|
| mut 函数 | `compile_error` | ✅ PASS |
| mut 函数定义 | `build_only` | ✅ PASS |
| mut 函数定义 | `compile_error` | ✅ PASS |
| mut 函数定义 | `compile_error` | ✅ PASS |
| 接口中的 mut 函数 | `compile_error` | ✅ PASS |
| 接口中的 mut 函数 | `run` | ✅ PASS |
| mut 函数的使用限制 | `compile_error` | ✅ PASS |
| mut 函数的使用限制 | `compile_error` | ✅ PASS |
| mut 函数的使用限制 | `compile_error` | ✅ PASS |

## 失败详情

### ❌ basic_IO_source_stream__文件流操作__block9

- **来源**: `.docs/language/source_zh_cn/Basic_IO/basic_IO_source_stream.md` > 文件流操作
- **类型**: `run`
- **错误**: Build failed unexpectedly

编译输出:

```
[31merror[0m: 'exists' is not a member of class 'File'
 [36m==>[0m /home/runner/work/CangjieDocValidator/CangjieDocValidator/check_output/Basic_IO/basic_IO_source_stream__文件流操作__block9/src/main.cj:8:14:
  [36m| [0m
[36m8[0m [36m| [0m    if (File.exists("./tempFile.txt")) {[0m
  [36m| [0m             [31m^^^^^^ [0m
  [36m| [0m

[31merror[0m: 'delete' is not a member of class 'File'
 [36m==>[0m /home/runner/work/CangjieDocValidator/CangjieDocValidator/check_output/Basic_IO/basic_IO_source_stream__文件流操作__block9/src/main.cj:9:14:
  [36m| [0m
[36m9[0m [36m| [0m        File.delete("./tempFile.txt")[0m
  [36m| [0m             [31m^^^^^^ [0m
  [36m| [0m

[31merror[0m: 'delete' is not a member of class 'File'
  [36m==>[0m /home/runner/work/CangjieDocValidator/CangjieDocValidator/check_output/Basic_IO/basic_IO_source_stream__文件流操作__block9/src/main.cj:18:10:
   [36m| [0m
[36m18[0m [36m| [0m    File.delete("./tempFile.txt")[0m
   [36m| [0m         [31m^^^^^^ [0m
   [36m| [0m

3 errors generated, 3 errors printed.
Error: failed to compile package `basic_io_source_stream_________block9`, return code is 1
Error: cjpm build failed
```
