# issue.md — 已知问题与潜在隐患

## 1. tree-sitter-cangjie 插件需手动安装

**问题**：`check:ast` 指令依赖 `tree-sitter-cangjie` Python 包，该包未发布到 PyPI，需从 GitHub Releases 手动下载安装 `.whl` 文件。

**影响**：在 CI/CD 环境中需额外配置安装步骤。

**缓解**：当 tree-sitter 不可用时，`check:ast` 自动退化为 PASS（不报错），不影响其他测试。可通过 `--skip-ast` 选项显式跳过。

## 2. tree-sitter 末尾换行符敏感

**状态**：已解决。

tree-sitter-cangjie 插件 v1.0.5.3 已修复末尾换行符敏感问题，代码不以换行符结尾也不再产生误报。`check_ast()` 中的换行符补充逻辑已移除。

## 3. check:skip 仍有少量使用

**问题**：当前仍有 6 个代码块使用 `check:skip`（均在 `language/source_zh_cn/package/` 目录），原因是这些代码块包含多文件合并的伪代码片段（如同一代码块中包含 `// file1.cj` 和 `// file2.cj`），tree-sitter 无法将其作为单一源文件解析。

**影响**：这些代码块缺少语法层面的验证。

**建议**：后续可考虑将伪代码多文件示例拆分为独立的标注代码块（使用 `project` + `file` 参数），从而完全消除 `check:skip`。

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

## 7 ~ 13. tree-sitter-cangjie 语法解析错误详情

以下 7 个问题均在 tree-sitter-cangjie v0.0.2（Python 包）中复现，使用 tree-sitter 0.25.2。这些问题导致对应代码块无法使用 `check:ast` 标注，只能退化为 `check:skip`。

测试环境：
- `pip install tree-sitter==0.25.2`
- `pip install git+https://github.com/jstzwj/tree-sitter-cangjie.git`（v0.0.2）

---

### 7. VArray 字面量语法 `$N` 不被识别

**现象**：`VArray<Int64, $3>` 中的 `$3` 被解析为 `ERROR` 节点。该问题在顶层和函数体内均会出现。

**复现代码**：

```cangjie
var a: VArray<Int64, $3> = [1, 2, 3]
```

**错误输出**：

```
line 1:19 - line 1:23 ERROR  （对应 ", $3"）
```

在函数体内也同样失败：

```cangjie
func f() {
    var a: VArray<Int64, $3> = [1, 2, 3]
}
```

```
line 2:23 - line 2:27 ERROR  （对应 ", $3"）
```

**分析**：tree-sitter-cangjie 语法规则中未定义 `$` 前缀的编译时整数字面量（`$N`），这是仓颉 VArray 类型的特有语法。

**影响范围**：`basic_data_type/array.md` 中全部 VArray 相关代码块（block 13~16），共 4 个。

---

### 8. 顶层赋值语句（无 var/let）不被识别

**现象**：在顶层作用域（非函数/类/方法体内），不带 `var`/`let` 关键字的赋值语句被解析为 `ERROR` 节点。包括简单赋值 `a = 20`、复合赋值 `a += 2`/`a **= 2`/`a <<= 2` 等、以及下标赋值 `arr[0] = 3`。

在函数体内同样的语句可以正常解析，不会报错。

**复现代码 1（简单赋值）**：

```cangjie
a = 20
```

```
line 1:0 - line 1:6 ERROR
```

**复现代码 2（复合赋值）**：

```cangjie
a += 2
```

```
line 1:0 - line 1:6 ERROR
```

```cangjie
a **= 2
```

```
line 1:0 - line 1:7 ERROR
```

**复现代码 3（下标赋值）**：

```cangjie
arr[0] = 3
```

```
line 1:0 - line 1:10 ERROR
```

**函数体内正常**：

```cangjie
func f() { a = 20 }     // OK
func g() { a += 2 }     // OK
func h() { arr[0] = 3 } // OK
```

**分析**：tree-sitter-cangjie 的顶层语法规则只允许声明（var/let/func/class 等），不允许表达式语句（赋值语句属于表达式语句）。但仓颉语言的代码片段在文档中经常以顶层片段形式出现，不一定包在函数体内。

**影响范围**：此问题影响面最大，涉及多个目录的多个文件：
- `basic_data_type/array.md` — block 11（数组下标赋值 `arr2[0] = 3`）
- `basic_data_type/basic_operators.md` — block 6（复合赋值 `a += 2` 等）、block 14（位运算 `a = 10 << 1` 等）
- `basic_data_type/characters.md` — 间接影响（同一 block 中有赋值）
- `basic_data_type/integer.md` — block 3（`c = b'\u{90}' - b'\u{66}' + c`）
- `basic_data_type/basic_operators.md` — block 12（逻辑操作符 `a = true || true` 等）

---

### 9. `import as` 重命名语法不被识别

**现象**：`import pkg as newName` 和 `import pkg.item as newName` 语法中，`as` 关键字及其后的新名称被解析为 `ERROR` 节点。

**复现代码 1（包重命名）**：

```cangjie
import p1 as A
```

```
line 1:7 - line 1:12 ERROR  （对应 "p1 as"）
```

**复现代码 2（成员重命名）**：

```cangjie
import p2.f3 as f
```

```
line 1:10 - line 1:15 ERROR  （对应 "f3 as"）
```

**分析**：tree-sitter-cangjie 的 import 语法规则不包含 `as` 重命名子句。

**影响范围**：`package/import.md` — block 11（`import as` 示例，5 行均失败）。

---

### 10. `import {}` 分组导入语法不被识别

**现象**：`import {pkg1.item, pkg2.item}` 和 `import pkg.{item1, item2}` 两种花括号分组导入语法中，`{` 和 `}` 被解析为 `ERROR` 节点。

**复现代码 1（跨包分组）**：

```cangjie
import {package1.foo, package2.bar}
```

```
line 1:7 - line 1:8 ERROR   （对应 "{"）
line 1:34 - line 1:35 ERROR  （对应 "}"）
```

**复现代码 2（同包分组）**：

```cangjie
import package1.{foo, bar, fuzz}
```

```
line 1:16 - line 1:17 ERROR  （对应 "{"）
line 1:31 - line 1:32 ERROR  （对应 "}"）
```

**分析**：tree-sitter-cangjie 的 import 语法规则不支持花括号分组语法。

**影响范围**：`package/import.md` — block 1（`import {}`）、block 2（`import pkg.{}`）、block 5（`import {*.}`）。

---

### 11. Rune 双引号字面量 `r"x"` 不被识别

**现象**：仓颉语言支持 `r'x'`（单引号）和 `r"x"`（双引号）两种 Rune 字面量，但 tree-sitter-cangjie 只支持单引号形式。双引号形式中 `r` 被解析为标识符而非 Rune 字面量前缀，导致后续的 `"b"` 被解析为字符串而非 Rune。

**复现代码**：

```cangjie
let a: Rune = r'a'    // OK，正常解析
let b: Rune = r"b"    // ERROR
```

```
line 2:14 - line 2:15 ERROR  （对应 r 和 "b" 之间的断裂）
```

**分析**：tree-sitter-cangjie 的 Rune 字面量规则只匹配 `r'...'`，不匹配 `r"..."`。

**影响范围**：`basic_data_type/characters.md` — block 1。

---

### 12. 三单引号多行字符串 `'''...'''` 不被识别

**现象**：仓颉语言支持 `"""..."""`（三双引号）和 `'''...'''`（三单引号）两种多行字符串字面量，但 tree-sitter-cangjie 只支持三双引号形式。三单引号被整体解析为 `ERROR` 节点。

**复现代码**：

```cangjie
let s1: String = """
    """                  // OK，正常解析
let s2 = '''
    Hello,
    Cangjie Lang'''      // ERROR
```

```
line 3:10 - line 5:18 ERROR  （整个 '''...''' 块）
```

**分析**：tree-sitter-cangjie 的多行字符串规则只定义了 `"""..."""`，未定义 `'''...'''`。

**影响范围**：`basic_data_type/strings.md` — block 2。

---

### 13. 泛型扩展 `extend<T>` 语法不被识别

**现象**：带泛型参数的扩展声明 `extend<T> Type<T> <: Interface { ... }` 中，`<T>` 部分被解析为 `ERROR` 节点。不带泛型参数的 `extend Type <: Interface { ... }` 可以正常解析。

**复现代码**：

```cangjie
extend<T> Array<T> <: PrintSizeable {
    public func printSize() {
        println("The size is ${this.size}")
    }
}
```

```
line 1:6 - line 1:9 ERROR  （对应 "<T>"）
```

不带泛型参数的扩展正常解析：

```cangjie
extend Array<Int64> <: Foo {}    // OK
```

**分析**：tree-sitter-cangjie 的 `extend` 语法规则不支持泛型参数列表 `<T>`。

**影响范围**：`extension/interface_extension.md` — block 1。以及 `collections/` 目录中多个使用泛型扩展的代码块。
