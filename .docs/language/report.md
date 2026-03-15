# 文档标注分析报告

- **扫描目录**: `.docs/language/source_zh_cn/`
- **生成时间**: 2026-03-15 06:05:05 UTC
- **文档文件数**: 106
- **模式**: 仅提取（未执行编译运行，需 cjpm 环境）

## 总览

| 指标 | 数量 |
|------|------|
| 📝 标注代码块总数 | 721 |
| ▶️ 编译运行 (`run`) | 231 |
| 🔨 仅编译 (`build_only`) | 223 |
| 🚫 预期编译错误 (`compile_error`) | 130 |
| 🌳 语法检查 (`ast`) | 86 |
| ⏭️ 跳过 (`skip`) | 45 |
| 💥 预期运行时错误 (`runtime_error`) | 6 |
| ⚠️ 未标注 | 0 |

## 文件标注分布

| 文件 | run | build_only | compile_error | ast | skip | runtime_error | 总计 |
|------|-----|------------|---------------|-----|------|---------------|------|
| `Appendix/compile_options.md` | 1 | 0 | 0 | 12 | 1 | 0 | 14 |
| `Appendix/runtime_env.md` | 0 | 3 | 0 | 0 | 0 | 0 | 3 |
| `Appendix/tokenkind_type.md` | 0 | 0 | 0 | 1 | 0 | 0 | 1 |
| `Basic_IO/basic_IO_overview.md` | 2 | 2 | 0 | 0 | 0 | 0 | 4 |
| `Basic_IO/basic_IO_process_stream.md` | 4 | 2 | 0 | 0 | 0 | 0 | 6 |
| `Basic_IO/basic_IO_source_stream.md` | 3 | 6 | 0 | 1 | 1 | 0 | 11 |
| `FFI/cangjie-c.md` | 11 | 4 | 2 | 9 | 0 | 0 | 26 |
| `Macro/Tokens_types_and_quote_expressions.md` | 2 | 1 | 1 | 0 | 2 | 0 | 6 |
| `Macro/builtin_compilation_flags.md` | 1 | 1 | 1 | 4 | 1 | 0 | 8 |
| `Macro/compiling_error_reporting_and_debugging.md` | 0 | 0 | 1 | 7 | 4 | 0 | 12 |
| `Macro/defining_and_importing_macro_package.md` | 0 | 0 | 0 | 5 | 1 | 0 | 6 |
| `Macro/implementation_of_macros.md` | 0 | 0 | 0 | 16 | 15 | 0 | 31 |
| `Macro/macro_introduction.md` | 0 | 0 | 1 | 2 | 1 | 0 | 4 |
| `Macro/practical_case.md` | 0 | 0 | 0 | 8 | 5 | 0 | 13 |
| `Macro/syntax_node.md` | 0 | 0 | 0 | 1 | 6 | 0 | 7 |
| `Net/net_http.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `Net/net_socket.md` | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| `Net/net_websocket.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `basic_data_type/array.md` | 5 | 8 | 3 | 0 | 0 | 0 | 16 |
| `basic_data_type/basic_operators.md` | 8 | 4 | 3 | 0 | 0 | 0 | 15 |
| `basic_data_type/bool.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `basic_data_type/characters.md` | 1 | 2 | 0 | 0 | 0 | 0 | 3 |
| `basic_data_type/float.md` | 0 | 2 | 0 | 0 | 0 | 0 | 2 |
| `basic_data_type/integer.md` | 1 | 1 | 1 | 0 | 0 | 0 | 3 |
| `basic_data_type/nothing.md` | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| `basic_data_type/range.md` | 0 | 2 | 1 | 0 | 0 | 0 | 3 |
| `basic_data_type/strings.md` | 4 | 3 | 0 | 0 | 0 | 0 | 7 |
| `basic_data_type/tuple.md` | 2 | 1 | 2 | 0 | 0 | 0 | 5 |
| `basic_programming_concepts/expression.md` | 13 | 0 | 6 | 0 | 0 | 0 | 19 |
| `basic_programming_concepts/function.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `basic_programming_concepts/program_structure.md` | 9 | 0 | 7 | 0 | 0 | 0 | 16 |
| `class_and_interface/class.md` | 8 | 15 | 11 | 1 | 0 | 0 | 35 |
| `class_and_interface/interface.md` | 7 | 9 | 5 | 1 | 0 | 0 | 22 |
| `class_and_interface/prop.md` | 4 | 6 | 1 | 0 | 0 | 0 | 11 |
| `class_and_interface/subtype.md` | 0 | 5 | 0 | 0 | 0 | 0 | 5 |
| `class_and_interface/typecast.md` | 3 | 1 | 0 | 0 | 0 | 0 | 4 |
| `collections/collection_arraylist.md` | 8 | 4 | 1 | 0 | 0 | 0 | 13 |
| `collections/collection_hashmap.md` | 7 | 5 | 1 | 0 | 0 | 0 | 13 |
| `collections/collection_hashset.md` | 5 | 4 | 1 | 0 | 0 | 0 | 10 |
| `collections/collection_iterable_collections.md` | 3 | 2 | 0 | 0 | 0 | 0 | 5 |
| `compile_and_build/cjc_usage.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `compile_and_build/conditional_compilation.md` | 7 | 0 | 2 | 1 | 0 | 0 | 10 |
| `concurrency/concurrency_overview.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `concurrency/create_thread.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `concurrency/sleep.md` | 1 | 1 | 0 | 0 | 0 | 0 | 2 |
| `concurrency/sync.md` | 10 | 4 | 0 | 3 | 1 | 3 | 21 |
| `concurrency/terminal_thread.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `concurrency/use_thread.md` | 5 | 1 | 0 | 1 | 0 | 0 | 7 |
| `enum_and_pattern_match/enum.md` | 1 | 6 | 1 | 0 | 0 | 0 | 8 |
| `enum_and_pattern_match/match.md` | 3 | 3 | 1 | 0 | 0 | 0 | 7 |
| `enum_and_pattern_match/option_type.md` | 0 | 4 | 0 | 0 | 0 | 0 | 4 |
| `enum_and_pattern_match/other.md` | 4 | 0 | 0 | 0 | 0 | 0 | 4 |
| `enum_and_pattern_match/pattern_overview.md` | 13 | 0 | 6 | 0 | 0 | 0 | 19 |
| `enum_and_pattern_match/pattern_refutability.md` | 0 | 6 | 0 | 0 | 0 | 0 | 6 |
| `error_handle/exception_overview.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `error_handle/handle.md` | 7 | 1 | 2 | 0 | 0 | 1 | 11 |
| `error_handle/use_option.md` | 4 | 2 | 0 | 0 | 0 | 0 | 6 |
| `extension/access_rules.md` | 1 | 4 | 8 | 5 | 1 | 0 | 19 |
| `extension/direct_extension.md` | 3 | 0 | 2 | 0 | 0 | 0 | 5 |
| `extension/extend_overview.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `extension/interface_extension.md` | 6 | 1 | 2 | 0 | 0 | 0 | 9 |
| `first_understanding/hello_world.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `function/call_functions.md` | 5 | 0 | 0 | 0 | 0 | 0 | 5 |
| `function/closure.md` | 2 | 3 | 3 | 0 | 0 | 0 | 8 |
| `function/const_func_and_eval.md` | 2 | 0 | 4 | 0 | 0 | 0 | 6 |
| `function/define_functions.md` | 0 | 9 | 5 | 0 | 0 | 0 | 14 |
| `function/first_class_citizen.md` | 2 | 6 | 2 | 0 | 0 | 0 | 10 |
| `function/function_call_desugar.md` | 3 | 9 | 4 | 0 | 0 | 0 | 16 |
| `function/function_overloading.md` | 0 | 8 | 4 | 0 | 0 | 0 | 12 |
| `function/lambda.md` | 2 | 8 | 0 | 0 | 0 | 0 | 10 |
| `function/nested_functions.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `function/operator_overloading.md` | 3 | 3 | 3 | 0 | 0 | 0 | 9 |
| `generic/generic_class.md` | 0 | 1 | 1 | 0 | 0 | 0 | 2 |
| `generic/generic_constraint.md` | 2 | 2 | 1 | 0 | 0 | 0 | 5 |
| `generic/generic_enum.md` | 0 | 2 | 0 | 0 | 0 | 0 | 2 |
| `generic/generic_function.md` | 6 | 1 | 0 | 0 | 0 | 0 | 7 |
| `generic/generic_interface.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `generic/generic_overview.md` | 0 | 1 | 0 | 0 | 0 | 0 | 1 |
| `generic/generic_struct.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `generic/generic_subtype.md` | 0 | 2 | 0 | 0 | 0 | 0 | 2 |
| `generic/typealias.md` | 1 | 5 | 3 | 0 | 0 | 0 | 9 |
| `package/entry.md` | 2 | 0 | 3 | 0 | 0 | 0 | 5 |
| `package/import.md` | 0 | 7 | 1 | 5 | 3 | 0 | 16 |
| `package/package_name.md` | 1 | 4 | 0 | 2 | 2 | 0 | 9 |
| `package/toplevel_access.md` | 0 | 4 | 6 | 0 | 0 | 0 | 10 |
| `reflect_and_annotation/anno.md` | 6 | 3 | 3 | 0 | 1 | 1 | 14 |
| `reflect_and_annotation/dynamic_feature.md` | 4 | 2 | 1 | 0 | 0 | 1 | 8 |
| `struct/create_instance.md` | 2 | 1 | 0 | 0 | 0 | 0 | 3 |
| `struct/define_struct.md` | 0 | 9 | 4 | 1 | 0 | 0 | 14 |
| `struct/mut.md` | 1 | 1 | 7 | 0 | 0 | 0 | 9 |

## 跳过的代码块 (`check:skip`)

以下代码块被标注为 `skip`，不参与编译测试：

| # | 文件 | 章节 | 代码预览 |
|---|------|------|----------|
| 1 | `Appendix/compile_options.md` | `--enable-eh` <sup>[frontend]</sup> | `import stdx.effect.Command` |
| 2 | `Basic_IO/basic_IO_source_stream.md` | 标准流 | `import std.env.getStdIn` |
| 3 | `Macro/Tokens_types_and_quote_expressions.md` | Token 类型 | `Token(k: TokenKind)` |
| 4 | `Macro/Tokens_types_and_quote_expressions.md` | Tokens 类型 | `Tokens()   // 构造空列表` |
| 5 | `Macro/builtin_compilation_flags.md` | @Attribute | `@Component(` |
| 6 | `Macro/compiling_error_reporting_and_debugging.md` | 宏的编译和使用 | `// src/demo.cj` |
| 7 | `Macro/compiling_error_reporting_and_debugging.md` | 使用 --debug-macro 输出宏展开结果 | `macro package define` |
| 8 | `Macro/compiling_error_reporting_and_debugging.md` | 使用 --debug-macro 输出宏展开结果 | `import define.*` |
| 9 | `Macro/compiling_error_reporting_and_debugging.md` | 使用 --debug-macro 输出宏展开结果 | `  // before expansion` |
| 10 | `Macro/defining_and_importing_macro_package.md` | 宏包定义和导入 | `  import C.*` |
| 11 | `Macro/implementation_of_macros.md` | 非属性宏 | `import std.ast.*` |
| 12 | `Macro/implementation_of_macros.md` | 非属性宏 | `@MacroName(...)` |
| 13 | `Macro/implementation_of_macros.md` | 非属性宏 | `@MacroName func name() {}        // Before a FuncDecl` |
| 14 | `Macro/implementation_of_macros.md` | 非属性宏 | `// Illegal input Tokens` |
| 15 | `Macro/implementation_of_macros.md` | 属性宏 | `macro package define` |
| 16 | `Macro/implementation_of_macros.md` | 属性宏 | `import define.Foo` |
| 17 | `Macro/implementation_of_macros.md` | 属性宏 | `    // Illegal attribute Tokens` |
| 18 | `Macro/implementation_of_macros.md` | 宏定义中嵌套宏调用 | `macro package pkg1` |
| 19 | `Macro/implementation_of_macros.md` | 宏定义中嵌套宏调用 | `macro package pkg2` |
| 20 | `Macro/implementation_of_macros.md` | 宏定义中嵌套宏调用 | `public macro Prop(input:Tokens):Tokens {` |
| 21 | `Macro/implementation_of_macros.md` | 宏定义中嵌套宏调用 | `public macro Prop(input: Tokens): Tokens {` |
| 22 | `Macro/implementation_of_macros.md` | 宏调用中嵌套宏调用 | `var a = @foo(@foo1(2 * 3)+@foo2(1 + 3))  // foo1, foo2 have ` |
| 23 | `Macro/implementation_of_macros.md` | 嵌套宏之间的消息传递 | `@Outer var a = 0` |
| 24 | `Macro/implementation_of_macros.md` | 嵌套宏之间的消息传递 | `macro package define` |
| 25 | `Macro/implementation_of_macros.md` | 嵌套宏之间的消息传递 | `import define.*` |
| 26 | `Macro/macro_introduction.md` | 宏的简介 | `  print("x + y" + " = ")` |
| 27 | `Macro/practical_case.md` | 快速幂的计算 | `macro package define` |
| 28 | `Macro/practical_case.md` | Memoize 宏 | `macro package define` |
| 29 | `Macro/practical_case.md` | 一个 dprint 宏的扩展 | `macro package define` |
| 30 | `Macro/practical_case.md` | 一个简单的 DSL | `macro package define` |
| 31 | `Macro/practical_case.md` | 一个简单的 DSL | `import define.*` |
| 32 | `Macro/syntax_node.md` | 使用解析函数来解析 Tokens | `let tks1 = quote(a + b)` |
| 33 | `Macro/syntax_node.md` | BinaryExpr 案例 | `let binExpr = BinaryExpr(quote(x * y))` |
| 34 | `Macro/syntax_node.md` | FuncDecl 案例 | `let funcDecl = FuncDecl(quote(func f1(x: Int64) { x + 1 }))` |
| 35 | `Macro/syntax_node.md` | 使用 quote 插值语法节点 | `var binExpr = BinaryExpr(quote(1 + 2))` |
| 36 | `Macro/syntax_node.md` | 使用 quote 插值语法节点 | `var incrs = ArrayList<Node>()` |
| 37 | `Macro/syntax_node.md` | 使用 quote 插值语法节点 | `var binExpr1 = BinaryExpr(quote(x + y))` |
| 38 | `concurrency/sync.md` | 可重入互斥锁 Mutex | `import std.sync.Mutex` |
| 39 | `extension/access_rules.md` | 扩展的导入导出 | `// package a.b` |
| 40 | `package/import.md` | 使用 `import` 语句导入其他包中的声明或定义 | `// pkga/a.cj` |
| 41 | `package/import.md` | 使用 `import` 语句导入其他包中的声明或定义 | `// pkga/a.cj` |
| 42 | `package/import.md` | 使用 `import as` 对导入的名字重命名 | `    // a.cj` |
| 43 | `package/package_name.md` | 包的声明 | `// file 1` |
| 44 | `package/package_name.md` | 包的声明 | `// b.cj` |
| 45 | `reflect_and_annotation/anno.md` | 测试框架内置编译标记 | `package test` |
