# issue.md — 已知问题与潜在隐患

## 1. tree-sitter-cangjie 插件需手动安装

**问题**：`check:ast` 指令依赖 `tree-sitter-cangjie` Python 包，该包未发布到 PyPI，需从 GitHub Releases 手动下载安装 `.whl` 文件。

**影响**：在 CI/CD 环境中需额外配置安装步骤。

**缓解**：当 tree-sitter 不可用时，`check:ast` 自动退化为 PASS（不报错），不影响其他测试。可通过 `--skip-ast` 选项显式跳过。

## 2. tree-sitter 末尾换行符敏感

**状态**：已解决。

tree-sitter-cangjie 插件 v1.0.5.3 已修复末尾换行符敏感问题，代码不以换行符结尾也不再产生误报。`check_ast()` 中的换行符补充逻辑已移除。

## 3. check:skip 仍有使用

**问题**：当前仍有 48 个代码块使用 `check:skip`，主要原因包括：
- 代码块包含多文件多包合并的伪代码片段（如同一代码块中包含多个 `package` 声明）
- 需要特殊编译环境（宏包编译、外部 C 库链接、`--test` 等编译选项）
- 需要交互式运行时环境（stdin 读取）
- 死锁/阻塞代码示例不可实际运行

**影响**：这些代码块缺少语法层面的验证。

**已采取的优化措施**：
- 将包含 `...` 省略号伪代码的代码块替换为具体的可编译代码（如 `HashMap<K,V> = ...` → `HashMap<K,V>()`）
- 将 API 签名展示的伪代码块（如 `class Thread { ... }`）改为 `check:ast` 或 `check:build_only`
- 将顶层赋值/表达式语句的代码块包装在 `main()` 或函数中，从 `check:skip` 提升为 `check:run`/`check:build_only`
- 将误标为 ````cangjie` 的测试输出文本改为 ````text`
- 添加 stdx 自动下载支持，使 Net 章节的 HTTP/WebSocket 示例可实际编译运行
- 将自包含的声明代码块从 `check:ast` 提升为 `check:build_only`（实际编译验证）

**建议**：后续可考虑将多包伪代码示例拆分为独立的标注代码块（使用 `project` + `file` 参数），从而进一步减少 `check:skip` 使用。

## 4. cjpm run 退出码不反映运行时异常

**问题**：`cjpm run` 在程序抛出未捕获异常时仍返回退出码 0，异常信息输出到 stderr。

**影响**：不能简单通过退出码判断运行是否成功。

**解决**：`runner.py` 中通过检查 stderr 是否包含 `An exception has occurred` 来检测运行时错误。

## 5. 并发代码输出不确定性

**问题**：包含 `spawn` 的并发示例，输出顺序可能不固定。

**影响**：设置 `expected_output` 后可能因顺序不同导致测试失败。

**建议**：并发示例不设置 `expected_output`，仅验证编译运行成功。

## 6. 示例代码 if-else 表达式语法错误

**状态**：已解决。

`story/begin/03_control_flow.md` 中无大括号的 if-else 表达式（`if (cond) "Win" else "Try Again"`）为语法错误，已修正为 `if (cond) { "Win" } else { "Try Again" }`，标注从 `check:skip` 改回 `check:ast`。

---

## 7 ~ 13. tree-sitter-cangjie 语法解析问题

测试环境：
- `pip install tree-sitter==0.25.2`
- tree-sitter-cangjie v1.0.5.3（[下载地址](https://github.com/SunriseSummer/CangjieTreeSitter/releases/download/1.0.5.3/tree_sitter_cangjie-1.0.5-cp310-abi3-linux_x86_64.whl)）

> 注：#7、#9、#10、#11、#13 在早期使用的 v0.0.2（jstzwj/tree-sitter-cangjie）中存在，已在 v1.0.5.3 中修复。

---

### 7. VArray 字面量语法 `$N`

**状态**：已解决（v1.0.5.3 已修复）。

v0.0.2 中 `VArray<Int64, $3>` 的 `$3` 被解析为 `ERROR` 节点，v1.0.5.3 中已正常解析。相关代码块已改回 `check:ast`。

---

### 8. 顶层赋值/表达式语句不被识别（仓颉语言规则）

**状态**：非 tree-sitter 问题。仓颉语言规则要求赋值和表达式语句必须在函数体内。

在顶层作用域中，不带 `var`/`let` 关键字的赋值语句和表达式语句不被 tree-sitter 识别为合法的顶层声明，这符合仓颉语言的语法规则。文档中的此类代码片段已调整为包装在 `main()` 函数中，使其可编译运行。

**处理方式**：所有受影响的代码块已包装在 `main()` 或函数体中，从 `check:skip` 提升为 `check:run` 或 `check:build_only`。

---

### 9. `import as` 重命名语法

**状态**：已解决（v1.0.5.3 已修复）。

v0.0.2 中 `import pkg as newName` 语法中 `as` 被解析为 `ERROR`，v1.0.5.3 中已正常解析。相关代码块已改回 `check:ast`。

---

### 10. `import {}` 分组导入语法

**状态**：已解决（v1.0.5.3 已修复）。

v0.0.2 中 `import {pkg1.foo, pkg2.bar}` 和 `import pkg.{foo, bar}` 的花括号被解析为 `ERROR`，v1.0.5.3 中已正常解析。相关代码块已改回 `check:ast`。

---

### 11. Rune 双引号字面量 `r"x"`

**状态**：已解决（v1.0.5.3 已修复）。

v0.0.2 中 `r"b"` 的双引号形式被解析为 `ERROR`（单引号 `r'a'` 正常），v1.0.5.3 中已正常解析。相关代码块已改回 `check:ast`。

---

### 12. 三单引号多行字符串 `'''...'''` 不被识别

**状态**：已解决（v1.0.5.4 已修复）。

v1.0.5.3 中 `'''...'''` 被整体解析为 `ERROR` 节点，v1.0.5.4 中已正常解析。相关代码块已改回 `check:ast` 或提升为 `check:build_only`。

**影响范围**：`basic_data_type/strings.md` — block 2。

---

### 13. 泛型扩展 `extend<T>` 语法

**状态**：已解决（v1.0.5.3 已修复）。

v0.0.2 中 `extend<T> Array<T> <: Foo {}` 的 `<T>` 被解析为 `ERROR`（非泛型 `extend Array<Int64>` 正常），v1.0.5.3 中已正常解析。相关代码块已改回 `check:ast`。

---

## 14 ~ 17. tree-sitter-cangjie v1.0.5.3 中发现的其他解析问题

以下问题中部分已在 v1.0.5.4 中修复。

---

### 14. 字节字面量 `b'x'` 不被识别

**状态**：已解决（v1.0.5.4 已修复）。

v1.0.5.3 中 `b'x'` 不被识别（`b` 被视为标识符），v1.0.5.4 中已正常解析。相关代码块已改回 `check:ast` 或提升为 `check:build_only`。

---

### 15. 顶层表达式语句（for/while/spawn/unsafe 块等）

**状态**：非 tree-sitter 问题。仓颉语言规则要求表达式语句必须在函数体内。

这是 #8 的延伸。顶层的控制流语句和方法调用不被识别为合法的顶层声明，这是仓颉语言的语法规则。文档中的此类代码片段已包装在 `main()` 函数中，使其可编译运行。

---

### 16. 多井号原始字符串 `##'...'##` 不被识别

**状态**：已解决（v1.0.5.4 已修复）。

v1.0.5.3 中 `##'#'\n'##` 不被识别，v1.0.5.4 中已正常解析。相关代码块已改回 `check:ast` 或提升为 `check:build_only`。

---

### 17. 部分宏相关语法不被识别

**状态**：部分已解决（v1.0.5.4 修复了 `@Attribute[State]` 方括号参数）。

仍存在的问题：
- `@MacroName(...)` 中的 `...` 省略号
- 部分 `quote()` 表达式中的 `$()` 插值语法
- `BinaryExpr()` / `FuncDecl()` 解析表达式

**处理方式**：受影响的代码块保持为 `check:skip`。

---

## 18. runtime_env.md 示例代码 API 调用错误

**状态**：已解决。

`Appendix/runtime_env.md` 中 GWP-ASan 堆内存越界检测示例存在两处 API 调用错误：

1. `Array<UInt8>(4, item: 0)` — `item:` 不是合法的具名参数，应为 `repeat: 0`。
2. `releaseArrayRawData(array)` — 应传入 `acquireArrayRawData()` 的返回值（`CPointerHandle`），而非原始 `Array`，应改为 `releaseArrayRawData(cp)`。

**影响**：三处代码块无法通过编译，错误标注为 `check:skip`。

**修复**：已更正上述调用，将标注从 `check:skip` 升级为 `check:build_only`（代码可编译，但因涉及内存越界和 GC 检测，不执行运行测试）。
