# issue.md — 已知问题与潜在隐患

## 1. tree-sitter-cangjie 插件需手动安装

**问题**：`check:ast` 指令依赖 `tree-sitter-cangjie` Python 包，该包未发布到 PyPI，需从 GitHub Releases 手动下载安装 `.whl` 文件。

**影响**：在 CI/CD 环境中需额外配置安装步骤。

**缓解**：当 tree-sitter 不可用时，`check:ast` 自动退化为 PASS（不报错），不影响其他测试。可通过 `--skip-ast` 选项显式跳过。

## 2. tree-sitter 末尾换行符敏感

**状态**：已解决。

tree-sitter-cangjie 插件 v1.0.5.3 已修复末尾换行符敏感问题，代码不以换行符结尾也不再产生误报。`check_ast()` 中的换行符补充逻辑已移除。

## 3. check:skip 仍有使用

**问题**：当前仍有 94 个代码块使用 `check:skip`，主要原因包括：
- 代码块包含多文件合并的伪代码片段（如同一代码块中包含多个 `package` 声明）
- 包含 `...` 省略号伪代码占位符
- 顶层赋值语句（无 `var`/`let`）不被 tree-sitter 识别（详见 #8）
- 需要特殊编译环境（宏包编译、外部 C 库链接、stdx 依赖等）
- 需要运行时环境（stdin、文件 I/O、网络等）

**影响**：这些代码块缺少语法层面的验证。

**建议**：后续可考虑将伪代码多文件示例拆分为独立的标注代码块（使用 `project` + `file` 参数），从而减少 `check:skip` 使用。

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

### 8. 顶层赋值语句（无 var/let）不被识别

**现象**：在顶层作用域（非函数/类/方法体内），不带 `var`/`let` 关键字的赋值语句被解析为 `ERROR` 节点。包括简单赋值 `a = 20`、复合赋值 `a += 2`/`a **= 2`/`a <<= 2` 等、以及下标赋值 `arr[0] = 3`。

在函数体内同样的语句可以正常解析，不会报错。

**复现代码**：

```cangjie
a = 20
```

```
line 1:0 - line 1:6 ERROR
```

**函数体内正常**：

```cangjie
func f() { a = 20 }     // OK
func g() { a += 2 }     // OK
func h() { arr[0] = 3 } // OK
```

**分析**：tree-sitter-cangjie 的顶层语法规则只允许声明（var/let/func/class 等），不允许表达式语句（赋值语句属于表达式语句）。但仓颉语言的代码片段在文档中经常以顶层片段形式出现，不一定包在函数体内。

**影响范围**：此问题影响面最大，涉及多个目录的多个文件：
- `basic_data_type/array.md` — 数组下标赋值 `arr2[0] = 3`
- `basic_data_type/basic_operators.md` — 复合赋值 `a += 2`、位运算 `a = 10 << 1`、逻辑操作符 `a = true || true`
- `basic_data_type/integer.md` — `c = b'\u{90}' - b'\u{66}' + c`
- `collections/` — 集合操作 `list[0] = 3`、`map["a"] = 3`、`mySet.add(0)` 等方法调用
- `concurrency/sync.md` — AtomicInt32 方法调用 `x = obj.swap(2)` 等
- 以及顶层 for/while/unsafe/spawn 等控制流语句

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

**现象**：仓颉语言支持 `"""..."""`（三双引号）和 `'''...'''`（三单引号）两种多行字符串字面量，但 tree-sitter-cangjie 只支持三双引号形式。三单引号被整体解析为 `ERROR` 节点。

**复现代码**：

```cangjie
let s2 = '''
    Hello,
    Cangjie Lang'''
```

```
line 1:9 - line 3:18 ERROR  （整个 '''...''' 块）
```

**分析**：tree-sitter-cangjie 的多行字符串规则只定义了 `"""..."""`，未定义 `'''...'''`。

**影响范围**：`basic_data_type/strings.md` — block 2。

---

### 13. 泛型扩展 `extend<T>` 语法

**状态**：已解决（v1.0.5.3 已修复）。

v0.0.2 中 `extend<T> Array<T> <: Foo {}` 的 `<T>` 被解析为 `ERROR`（非泛型 `extend Array<Int64>` 正常），v1.0.5.3 中已正常解析。相关代码块已改回 `check:ast`。

---

## 14 ~ 17. tree-sitter-cangjie v1.0.5.3 中仍存在的其他解析问题

以下问题在 v1.0.5.3 中仍然存在。

---

### 14. 字节字面量 `b'x'` 不被识别

**现象**：仓颉语言的字节字面量 `b'x'`（UInt8 类型）不被 tree-sitter-cangjie 识别，`b` 被视为标识符，`'x'` 被视为独立的字符字面量，两者之间产生 ERROR。

**复现代码**：

```cangjie
let a = b'x'
```

```
line 1:8 - line 1:9 ERROR  （对应 b 和 'x' 之间的断裂）
```

**影响范围**：`basic_data_type/integer.md` — block 3。

---

### 15. 顶层表达式语句（for/while/spawn/unsafe 块等）

这是 #8 的延伸。除了赋值语句外，顶层的控制流语句（`for`、`while`、`spawn`、`unsafe` 块）以及方法调用（`list.add(0)`、`mySet.remove(1)` 等）也不被 tree-sitter 识别为合法的顶层声明。

**影响范围**：`collections/` 全部集合操作代码块、`concurrency/` 部分代码块、`FFI/cangjie-c.md` 中 `unsafe {}` 块。

---

### 16. 多井号原始字符串 `##'...'##` 不被识别

**现象**：仓颉语言支持多井号原始字符串（如 `##'#'\n'##`），但 tree-sitter-cangjie 无法解析。

**复现代码**：

```cangjie
let s2 = ##'#'\n'##
```

```
line 1:9 - line 1:16 ERROR
```

**影响范围**：`basic_data_type/strings.md` — block 3（原始多行字符串字面量示例）。

---

### 17. 部分宏相关语法不被识别

**现象**：一些宏定义和宏调用中的特殊语法不被 tree-sitter 正确解析，包括：
- `@MacroName(...)` 中的 `...` 省略号
- `@MacroName(#)` / `@MacroName(\`)` 中的非法 Token 示例
- `@Attribute[State]` 中的方括号参数
- 部分 `quote()` 表达式和 `BinaryExpr()` / `FuncDecl()` 解析表达式

**影响范围**：`Macro/` 目录下多个文件中的代码块。
