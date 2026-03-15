# record.md — 本次改造记录

## 一、改造背景

根据任务要求，对 `check.py` 文档示例代码测试框架进行增强，并对以下目录中的文档进行测试和修复：

- `libs/standard/std/ast/ast_samples`
- `language/source_zh_cn/package`
- `language/source_zh_cn/` 下所有子目录（本次新增）

## 二、check.py 框架增强

### 2.1 新增宏包项目支持 (`type=macro`)

**问题**：原框架只支持单模块 cjpm 项目，无法处理文档中"宏定义包 + 宏调用包"的多模块示例（如 `context.md`、`report.md`）。

**方案**：新增 `type=macro` 标注参数。标记为 `type=macro` 的代码块会被识别为宏定义代码，框架自动创建多模块 cjpm 项目结构：

```
project_dir/
├── cjpm.toml                 # 主项目，path 依赖宏模块
├── src/
│   └── main.cj               # 宏调用代码
└── macro_definition/          # 宏子模块（名称从 macro package 声明提取）
    ├── cjpm.toml              # compile-option = "--compile-macro"
    └── src/
        └── macros.cj          # 宏定义代码
```

**改动点**：
- `CodeBlock` 数据类新增 `lang` 和 `block_type` 字段
- `TestCase` 数据类新增 `has_macro_def` 和 `c_files` 字段
- `blocks_to_testcases()` 中自动分离宏定义块和主代码块
- `create_cjpm_project()` 中新增宏项目多模块生成逻辑
- 新增 `_extract_macro_package_name()` 辅助函数

### 2.2 新增 C 代码/FFI 支持 (`lang=c`)

**问题**：文档中可能包含 C 语言互操作（FFI）示例，需要先编译 C 代码再构建仓颉项目。

**方案**：
- 支持 `` ```c `` 代码围栏的自动识别
- C 代码块通过 `project` 参数与仓颉代码关联
- 编译优先使用 `clang`，不可用时回退到 `gcc`
- C 代码编译为静态库（`.a`），在 `cjpm build` 前完成

**改动点**：
- 代码块检测逻辑扩展为支持 `cangjie` 和 `c` 两种语言
- 新增 `_find_c_compiler()` 函数（优先 clang）
- 新增 `_compile_c_files()` 函数处理 C 编译流程
- `run_testcase()` 在 cjpm build 前执行 C 编译

### 2.3 新增 `check:ast` 指令（tree-sitter 语法检查）

**问题**：许多代码片段无法编译（如仅含 import 语句的片段、依赖外部文件的示例），原来只能标记为 `check:skip`，缺乏语法层面的验证。

**方案**：新增 `check:ast` 指令，使用 tree-sitter 仓颉插件对代码做语法解析检查：
- 不需要编译器环境（不依赖 cjpm/cjc），始终执行
- 能检测语法错误并报告具体行号和列号
- 适合代码片段、不可编译但语法正确的示例
- 替代 `check:skip`，提供更好的代码看护

**改动点**：
- 新增 `_get_ts_parser()` 延迟初始化 tree-sitter 解析器
- 新增 `_find_ts_errors()` 递归查找语法树中的错误节点
- 新增 `check_ast()` 公共函数执行语法检查
- 代码末尾自动补充换行符，避免 tree-sitter 误报
- 主流程中 `ast` 块独立处理，不生成 cjpm 项目

### 2.4 自动检测 output-type

**问题**：原框架固定使用 `output-type = "executable"`，导致无 `main()` 函数的代码块编译失败。

**方案**：自动检测代码中是否包含 `main()` 函数：
- 有 `main()` → `output-type = "executable"`
- `build_only` 或 `compile_error` 指令且无 `main()` → `output-type = "static"`

### 2.5 自动匹配 package 名称

**问题**：文档示例中常有显式的 `package xxx` 声明，但框架自动生成的 cjpm 项目名与之不匹配。

**方案**：从源代码中提取 `package` 声明的根包名，作为 `cjpm.toml` 的项目名。

## 三、文档标注修复

### 3.1 ast_samples 目录（6 个文件）

| 文件 | 修改内容 |
|------|----------|
| `dump.md` | `<!-- verify -->` → `<!-- check:run -->` |
| `operate.md` | `<!-- verify -->` → `<!-- check:run -->`，新增 `<!-- expected_output -->` |
| `parse.md` | 第一个块 `<!-- verify -->` → `<!-- check:run -->`；第二个块 `<!-- compile -->` → `<!-- check:ast -->`（依赖外部文件，但语法正确） |
| `traverse.md` | `<!-- verify -->` → `<!-- check:run -->`，新增 `<!-- expected_output -->` |
| `context.md` | 重写标注：示例 1 使用 `compile_error project=ctx1 type=macro`；示例 2 使用 `run project=ctx2 type=macro`；新增 `expected_output` |
| `report.md` | 重写标注：示例 1 使用 `compile_error project=rpt1 type=macro`；示例 2 使用 `check:run` |

### 3.2 package 目录（5 个文件）

| 文件 | 修改内容 |
|------|----------|
| `entry.md` | `<!-- run -->` → `<!-- check:run -->`；`<!-- compile.error -->` → `<!-- check:compile_error -->`；第二个代码块新增 `<!-- expected_output -->` |
| `import.md` | 多文件伪代码片段保留 `<!-- check:skip -->`；重导出示例 3 个块改为 `build_only project=reexport` 多文件项目；最后的块保持 `<!-- check:compile_error -->` |
| `package_name.md` | 语法正确的独立片段改为 `<!-- check:ast -->`（6 个）；多文件/多包声明片段保留 `<!-- check:skip -->`（3 个） |
| `toplevel_access.md` | `<!-- compile -->` → `<!-- check:build_only -->`；`<!-- compile.error -->` → `<!-- check:compile_error -->`；最后两个跨文件示例使用 `compile_error project=priv_a file=...` 合并为一个项目 |
| `package_overview.md` | 无代码块，无需修改 |

### 3.3 language/source_zh_cn 目录全量标注（本次新增）

共处理约 90 个含代码块的 Markdown 文件，为约 730 个代码块添加了 `<!-- check:XXX -->` 标注。使用 Cangjie SDK 1.0.5 和 tree-sitter-cangjie v1.0.5.3 进行编译运行和语法检查。最终统计：

| 标注类型 | 数量 | 说明 |
|---------|------|------|
| `check:run` | 234 | 编译并运行验证 |
| `check:build_only` | 210 | 仅编译验证 |
| `check:compile_error` | 133 | 预期编译失败 |
| `check:ast` | 93 | tree-sitter 语法解析检查（跨包引用等无法独立编译的代码块） |
| `check:skip` | 51 | 跳过（多包伪代码/特殊环境/死锁示例等） |
| `check:runtime_error` | 5 | 预期运行时错误 |

主要优化措施：
- 简单接口/构造函数演示代码使用 `check:ast` 而非添加 import 后 `check:build_only`，保持文档简洁
- 将可扩展的 `check:skip` 代码块（如下标访问、contains 演示）扩展为带 `main()` 的可运行示例
- 将包含 `...` 伪代码的代码块替换为具体的可编译代码（如 `HashMap<K,V> = ...` → `HashMap<K,V>()`）
- 将顶层赋值/表达式语句代码块包装在 `main()` 或函数中，从 `check:skip` 提升为 `check:run`/`check:build_only`
- 将含有预期编译错误注释的代码块从 `check:build_only` 修正为 `check:compile_error`
- 将标准库 API 声明代码块（TypeInfo、Future、Atomic 等）从 `check:build_only` 修正为 `check:ast`
- 将误标为 ````cangjie` 的测试输出文本改为 ````text`（Appendix/compile_options.md）
- 添加 stdx 自动下载支持（`project.py`），使 Net 章节 HTTP/WebSocket 示例可实际编译运行
- stdx 下载地址：`https://github.com/SunriseSummer/CangjieSDK/releases/download/1.0.5/cangjie-stdx-linux-x64-1.0.5.1.zip`

各目录处理详情：

| 目录 | 文件数 | 代码块数 | 主要处理 |
|------|--------|---------|---------|
| first_understanding/ | 1 | 1 | `<!-- verify -->` → `<!-- check:run -->` |
| basic_programming_concepts/ | 3 | 35 | const G 和 Planet 合并为 project=const_gravity |
| basic_data_type/ | 10 | 46 | 顶层赋值包装为 main()；三引号/原始字符串示例包装为 build_only |
| function/ | 10 | 89 | 操作符重载 Point 类与 main 合并为 project=overloadOperator |
| collections/ | 4 | 11 | 伪代码 `...` 替换为具体代码，提升为 build_only/run |
| class_and_interface/ | 5 | 71 | 跨包访问修饰符示例标注；接口继承合并为 project=myInt |
| struct/ | 3 | 24 | 跨包访问修饰符示例标注 |
| enum_and_pattern_match/ | 5 | 45 | 类型模式 4 块合并为 project=mergeCase |
| generic/ | 9 | 26 | composition 函数与调用合并为 project=composition |
| error_handle/ | 3 | 16 | try-catch 包装为 main()；异常示例改为 runtime_error |
| concurrency/ | 5 | 21 | API 文档改为 ast；伪代码替换为具体代码；死锁正确标注 |
| extension/ | 4 | 24 | 直接扩展/接口扩展合并为项目；跨包示例标注 |
| Basic_IO/ | 3 | 7 | 伪代码替换为 ByteArrayStream 等；文件操作改为 build_only |
| FFI/ | 1 | 13 | @C struct 改为 build_only；顶层 unsafe/spawn 包装为函数 |
| Macro/ | 8 | 10 | 语法可解析的标注 ast；宏特殊语法改为 skip |
| Net/ | 3 | 2 | stdx 示例改为 check:run（自动下载 stdx 支持） |
| Appendix/ | 3 | 1 | 误标输出改为 text；unsafe 示例改为 build_only |
| reflect_and_annotation/ | 2 | 18 | 溢出异常和反射异常改为 runtime_error |
| compile_and_build/ | 2 | 10 | 语法可解析的标注 |

## 四、模块化拆分

原 `check.py`（1196 行）拆分为 `check/` 目录下 8 个模块文件，每个文件不超过 250 行：

| 文件 | 行数 | 职责 |
|------|------|------|
| `__init__.py` | 1 | 包初始化 |
| `__main__.py` | 4 | `python3 -m check` 入口 |
| `models.py` | 79 | 数据模型（CodeBlock、TestCase）和正则常量 |
| `parser.py` | 144 | Markdown 解析，代码块提取 |
| `assembler.py` | 124 | 测试用例组装（代码块→TestCase） |
| `project.py` | 248 | cjpm 项目生成（含宏项目、标准项目） |
| `runner.py` | 224 | 测试执行、tree-sitter AST 检查 |
| `report.py` | 141 | 测试报告生成 |
| `cli.py` | 164 | 命令行参数解析和摘要输出 |
| `main.py` | 222 | 主流程调度 |

新增选项：
- `--skip-ast`：跳过 `check:ast` 语法解析检查

原 `check.md` 移至 `check/readme.md`，内容中的命令引用更新为 `python3 -m check`。

## 五、check/readme.md 文档更新

- 命令行用法从 `check.py` 改为 `python3 -m check`
- 新增 `--skip-ast` 参数说明
- 文档结构保持不变

## 六、测试结果

### 全量编译运行测试（Cangjie SDK 1.0.5 + tree-sitter-cangjie 1.0.5.3）

使用仓颉 SDK 实际编译运行全部代码块：

- 测试用例：657 个（含编译运行、编译检查、预期错误、语法检查）
- 通过：653 个
- 失败：4 个（均为 tree-sitter 已知解析限制）
- 跳过：51 个

| 标注类型 | 数量 | 说明 |
|---------|------|------|
| `check:run` | 234 | 编译并运行验证 |
| `check:build_only` | 210 | 仅编译验证 |
| `check:compile_error` | 133 | 预期编译失败 |
| `check:ast` | 93 | tree-sitter 语法解析检查 |
| `check:skip` | 51 | 跳过（多包伪代码/特殊环境/死锁示例等） |
| `check:runtime_error` | 5 | 预期运行时错误 |

4 个 AST 失败均为 tree-sitter-cangjie v1.0.5.3 已知限制（详见 issue.md #8/#15）。

### ast_samples 目录
- 测试用例：9 个（2 宏项目 + 6 独立项目 + 1 语法检查）
- 未标注代码块：0 个

### story 目录
- 测试用例：86 个
- 跳过：7 个
- 未标注代码块：0 个

## 七、安全扫描

- CodeQL 扫描结果：0 个告警，无安全问题
