"""
测试报告生成模块

在输出目录下生成人类友好的 report.md 测试报告。
支持完整测试模式和仅提取模式两种报告格式。
"""

from datetime import datetime, timezone
from pathlib import Path


def _relative_path(filepath: str, base_dir: str) -> str:
    """计算文件相对于基准目录的路径，失败时返回文件名。"""
    try:
        return str(Path(filepath).relative_to(base_dir))
    except ValueError:
        return Path(filepath).name


def generate_report(
    output_dir: Path,
    scan_dir: str,
    all_results: list,
    unannotated_warnings: list,
    skipped: int,
    md_files: list,
    report_dir: Path = None,
) -> Path:
    """在输出目录下生成测试报告 report.md。

    参数:
        output_dir: 输出目录
        scan_dir: 扫描的文档目录路径
        all_results: run_testcase() 返回的结果列表
        unannotated_warnings: [(file, line, heading, preview), ...]
        skipped: 跳过的代码块数量
        md_files: 处理的文档文件列表
        report_dir: 报告额外输出目录（可选，会在此目录也放一份）

    返回:
        生成的 report.md 路径
    """
    total = len(all_results)
    passed = sum(1 for r in all_results if r['status'] == 'PASS')
    failed = sum(1 for r in all_results if r['status'] == 'FAIL')
    unannotated_total = len(unannotated_warnings)

    # 按来源文件分组
    file_results = {}
    for r in all_results:
        src = r['source_file']
        file_results.setdefault(src, []).append(r)

    lines = []

    # 标题
    lines.append('# 测试报告\n')

    # 元信息
    now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
    lines.append(f'- **扫描目录**: `{scan_dir}`')
    lines.append(f'- **生成时间**: {now}')
    lines.append(f'- **文档文件数**: {len(md_files)}')
    lines.append('')

    # 总览
    lines.append('## 总览\n')
    if total == 0 and unannotated_total == 0:
        lines.append('未发现可测试的代码块。\n')
    else:
        if failed == 0 and unannotated_total == 0:
            status_emoji = '✅'
        else:
            status_emoji = '❌'

        lines.append('| 指标 | 数量 |')
        lines.append('|------|------|')
        lines.append(f'| {status_emoji} 测试总数 | {total} |')
        lines.append(f'| ✅ 通过 | {passed} |')
        lines.append(f'| ❌ 失败 | {failed} |')
        lines.append(f'| ⏭️ 跳过 | {skipped} |')
        lines.append(f'| ⚠️ 未标注 | {unannotated_total} |')
        lines.append('')

    # 按文件分列的详情
    if file_results:
        lines.append('## 文件详情\n')
        for src_file in sorted(file_results.keys()):
            results = file_results[src_file]
            file_fail = sum(1 for r in results if r['status'] == 'FAIL')
            file_icon = '✅' if file_fail == 0 else '❌'
            rel = _relative_path(src_file, scan_dir)
            lines.append(f'### {file_icon} `{rel}`\n')
            lines.append('| 测试用例 | 类型 | 结果 |')
            lines.append('|----------|------|------|')
            for r in results:
                icon = '✅' if r['status'] == 'PASS' else '❌'
                directive = r['directive']
                name_display = (
                    r['heading'] if r['heading'] != 'unknown'
                    else r['name']
                )
                lines.append(
                    f'| {name_display} | `{directive}` '
                    f'| {icon} {r["status"]} |'
                )
            lines.append('')

    # 失败详情
    failed_results = [r for r in all_results if r['status'] == 'FAIL']
    if failed_results:
        lines.append('## 失败详情\n')
        for r in failed_results:
            lines.append(f'### ❌ {r["name"]}\n')
            rel_src = _relative_path(r["source_file"], scan_dir)
            lines.append(
                f'- **来源**: `{rel_src}` > {r["heading"]}'
            )
            lines.append(f'- **类型**: `{r["directive"]}`')
            lines.append(f'- **错误**: {r["error"]}')
            if r.get('build_output') and not r.get('build_ok'):
                lines.append('')
                lines.append('编译输出:')
                lines.append('')
                lines.append('```')
                lines.append(r['build_output'])
                lines.append('```')
            lines.append('')

    # 未标注代码块
    if unannotated_warnings:
        lines.append('## 未标注的代码块\n')
        lines.append(
            '以下代码块缺少 `<!-- check:xxx -->` 标注，请补全：\n'
        )
        lines.append('| 文件 | 行号 | 章节 | 代码预览 |')
        lines.append('|------|------|------|----------|')
        for filepath, line_no, heading, preview in unannotated_warnings:
            rel_fp = _relative_path(filepath, scan_dir)
            safe_preview = (
                (preview or '')
                .replace('|', '\\|')
                .replace('\n', ' ')
                .replace('`', "'")[:60]
            )
            lines.append(
                f'| `{rel_fp}` | {line_no} | {heading} '
                f'| `{safe_preview}` |'
            )
        lines.append('')

    report_content = '\n'.join(lines)

    report_path = output_dir / 'report.md'
    report_path.write_text(report_content, encoding='utf-8')

    # 额外输出到指定目录
    if report_dir:
        report_dir = Path(report_dir)
        report_dir.mkdir(parents=True, exist_ok=True)
        extra_path = report_dir / 'report.md'
        extra_path.write_text(report_content, encoding='utf-8')

    return report_path


def generate_extract_report(
    output_dir: Path,
    scan_dir: str,
    all_blocks: list,
    unannotated_warnings: list,
    skipped: int,
    md_files: list,
    report_dir: Path = None,
) -> Path:
    """在仅提取模式下生成标注分析报告 report.md。

    参数:
        output_dir: 输出目录
        scan_dir: 扫描的文档目录路径
        all_blocks: 所有提取到的 CodeBlock 列表
        unannotated_warnings: [(file, line, heading, preview), ...]
        skipped: 跳过的代码块数量
        md_files: 处理的文档文件列表
        report_dir: 报告额外输出目录（可选）

    返回:
        生成的 report.md 路径
    """
    unannotated_total = len(unannotated_warnings)

    # 按标注类型统计
    directive_counts = {}
    for b in all_blocks:
        directive_counts[b.directive] = (
            directive_counts.get(b.directive, 0) + 1
        )

    # 按来源文件分组
    file_blocks = {}
    for b in all_blocks:
        file_blocks.setdefault(b.source_file, []).append(b)

    total_blocks = len(all_blocks)

    lines = []

    # 标题
    lines.append('# 文档标注分析报告\n')

    # 元信息
    now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
    lines.append(f'- **扫描目录**: `{scan_dir}`')
    lines.append(f'- **生成时间**: {now}')
    lines.append(f'- **文档文件数**: {len(md_files)}')
    lines.append(
        f'- **模式**: 仅提取（未执行编译运行，需 cjpm 环境）'
    )
    lines.append('')

    # 总览
    lines.append('## 总览\n')
    lines.append('| 指标 | 数量 |')
    lines.append('|------|------|')
    lines.append(f'| 📝 标注代码块总数 | {total_blocks} |')

    # 按指令类型输出统计
    directive_order = [
        'run', 'build_only', 'compile_error',
        'ast', 'skip', 'runtime_error',
    ]
    directive_labels = {
        'run': '▶️ 编译运行 (`run`)',
        'build_only': '🔨 仅编译 (`build_only`)',
        'compile_error': '🚫 预期编译错误 (`compile_error`)',
        'ast': '🌳 语法检查 (`ast`)',
        'skip': '⏭️ 跳过 (`skip`)',
        'runtime_error': '💥 预期运行时错误 (`runtime_error`)',
    }
    for d in directive_order:
        if d in directive_counts:
            label = directive_labels.get(d, f'`{d}`')
            lines.append(f'| {label} | {directive_counts[d]} |')
    # 输出未在预定义列表中的指令
    for d, cnt in sorted(directive_counts.items()):
        if d not in directive_order:
            lines.append(f'| `{d}` | {cnt} |')

    lines.append(f'| ⚠️ 未标注 | {unannotated_total} |')
    lines.append('')

    # 按文件分列的标注分布
    lines.append('## 文件标注分布\n')
    lines.append(
        '| 文件 | run | build_only | compile_error '
        '| ast | skip | runtime_error | 总计 |'
    )
    lines.append(
        '|------|-----|------------|---------------'
        '|-----|------|---------------|------|'
    )
    for src_file in sorted(file_blocks.keys()):
        blocks = file_blocks[src_file]
        counts = {}
        for b in blocks:
            counts[b.directive] = counts.get(b.directive, 0) + 1
        total_file = len(blocks)
        rel = _relative_path(src_file, scan_dir)
        lines.append(
            f'| `{rel}` '
            f'| {counts.get("run", 0)} '
            f'| {counts.get("build_only", 0)} '
            f'| {counts.get("compile_error", 0)} '
            f'| {counts.get("ast", 0)} '
            f'| {counts.get("skip", 0)} '
            f'| {counts.get("runtime_error", 0)} '
            f'| {total_file} |'
        )
    lines.append('')

    # 跳过的代码块详情
    skip_blocks = [b for b in all_blocks if b.directive == 'skip']
    if skip_blocks:
        lines.append('## 跳过的代码块 (`check:skip`)\n')
        lines.append(
            '以下代码块被标注为 `skip`，不参与编译测试：\n'
        )
        lines.append('| # | 文件 | 章节 | 代码预览 |')
        lines.append('|---|------|------|----------|')
        for i, b in enumerate(skip_blocks, 1):
            rel = _relative_path(b.source_file, scan_dir)
            preview = (
                b.code.split('\n')[0][:60]
                .replace('|', '\\|')
                .replace('`', "'")
            )
            lines.append(
                f'| {i} | `{rel}` | {b.heading} '
                f'| `{preview}` |'
            )
        lines.append('')

    # 未标注代码块
    if unannotated_warnings:
        lines.append('## 未标注的代码块\n')
        lines.append(
            '以下代码块缺少 `<!-- check:xxx -->` 标注，请补全：\n'
        )
        lines.append('| 文件 | 行号 | 章节 | 代码预览 |')
        lines.append('|------|------|------|----------|')
        for filepath, line_no, heading, preview in unannotated_warnings:
            safe_preview = (
                (preview or '')
                .replace('|', '\\|')
                .replace('\n', ' ')
                .replace('`', "'")[:60]
            )
            lines.append(
                f'| `{filepath}` | {line_no} | {heading} '
                f'| `{safe_preview}` |'
            )
        lines.append('')

    report_content = '\n'.join(lines)

    report_path = output_dir / 'report.md'
    report_path.write_text(report_content, encoding='utf-8')

    # 额外输出到指定目录
    if report_dir:
        report_dir = Path(report_dir)
        report_dir.mkdir(parents=True, exist_ok=True)
        extra_path = report_dir / 'report.md'
        extra_path.write_text(report_content, encoding='utf-8')

    return report_path
