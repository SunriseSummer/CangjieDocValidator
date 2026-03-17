#!/usr/bin/env python3
"""
AIChatPro 自动化测试脚本

启动模拟服务器，然后运行 AIChatPro 发送测试消息，验证：
1. 程序能正常启动并显示横幅
2. /help 命令正常工作
3. 发送消息能获得模拟 AI 的流式回复
4. /clear 命令正常工作
5. /exit 命令能正常退出

使用方式：
    # 先确保已执行 source envsetup.sh 并 cjpm build
    python3 test_aichat.py

依赖：仅使用 Python 标准库，无需安装额外包。
"""

import subprocess
import time
import sys
import os
import signal
import threading


# 测试配置
MOCK_SERVER_PORT = 18765
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
MOCK_SERVER_SCRIPT = os.path.join(PROJECT_DIR, "mock_server.py")


def start_mock_server():
    """启动模拟 AI 服务器"""
    print("[测试] 启动模拟服务器...")
    proc = subprocess.Popen(
        [sys.executable, MOCK_SERVER_SCRIPT, "--port", str(MOCK_SERVER_PORT)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    # 等待服务器启动
    time.sleep(1)
    if proc.poll() is not None:
        stderr = proc.stderr.read().decode("utf-8", errors="replace")
        print(f"[测试] 模拟服务器启动失败: {stderr}")
        sys.exit(1)
    print(f"[测试] 模拟服务器已启动 (PID: {proc.pid}, 端口: {MOCK_SERVER_PORT})")
    return proc


def run_aichat_test(commands, timeout=30):
    """
    运行 AIChatPro 并发送一系列命令

    Args:
        commands: 要发送的命令列表
        timeout: 超时时间（秒）

    Returns:
        (stdout, stderr, returncode) 元组
    """
    env = os.environ.copy()
    env["KIMI_API_KEY"] = "test-mock-key"
    env["MOCK_API_URL"] = f"http://127.0.0.1:{MOCK_SERVER_PORT}/v1"

    # 构建输入字符串
    input_text = "\n".join(commands) + "\n"

    print(f"[测试] 运行 AIChatPro，输入: {commands}")

    try:
        proc = subprocess.Popen(
            ["cjpm", "run"],
            cwd=PROJECT_DIR,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
        stdout, stderr = proc.communicate(input=input_text.encode("utf-8"), timeout=timeout)
        return (
            stdout.decode("utf-8", errors="replace"),
            stderr.decode("utf-8", errors="replace"),
            proc.returncode,
        )
    except subprocess.TimeoutExpired:
        proc.kill()
        stdout, stderr = proc.communicate()
        return (
            stdout.decode("utf-8", errors="replace"),
            stderr.decode("utf-8", errors="replace"),
            -1,
        )


def test_help_command():
    """测试 /help 命令"""
    print("\n" + "=" * 50)
    print("[测试 1] /help 命令")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/help", "/exit"])

    passed = True
    checks = [
        ("显示横幅", "AIChatPro" in stdout),
        ("显示帮助信息", "/help" in stdout and "/exit" in stdout),
        ("正常退出", "再见" in stdout),
    ]

    for name, result in checks:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")
        if not result:
            passed = False

    if not passed:
        print(f"  [输出]: {stdout[:500]}")
        if stderr:
            print(f"  [错误]: {stderr[:300]}")

    return passed


def test_clear_command():
    """测试 /clear 命令"""
    print("\n" + "=" * 50)
    print("[测试 2] /clear 命令")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/clear", "/exit"])

    passed = True
    checks = [
        ("清空历史提示", "对话历史已清空" in stdout),
        ("正常退出", "再见" in stdout),
    ]

    for name, result in checks:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")
        if not result:
            passed = False

    if not passed:
        print(f"  [输出]: {stdout[:500]}")

    return passed


def test_unknown_command():
    """测试未知命令"""
    print("\n" + "=" * 50)
    print("[测试 3] 未知命令处理")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/unknown", "/exit"])

    passed = True
    checks = [
        ("提示未知命令", "未知命令" in stdout),
        ("正常退出", "再见" in stdout),
    ]

    for name, result in checks:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")
        if not result:
            passed = False

    if not passed:
        print(f"  [输出]: {stdout[:500]}")

    return passed


def test_chat_with_mock():
    """测试与模拟服务器的对话"""
    print("\n" + "=" * 50)
    print("[测试 4] 模拟 AI 对话（SSE 流式）")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["你好", "/exit"], timeout=30)

    passed = True
    checks = [
        ("使用自定义 URL", "自定义 API URL" in stdout),
        ("显示 AI 回复", "AI>" in stdout),
        ("回复包含内容", len(stdout) > 100),
        ("正常退出", "再见" in stdout),
    ]

    for name, result in checks:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")
        if not result:
            passed = False

    if not passed:
        print(f"  [输出预览]: {stdout[:600]}")
        if stderr:
            print(f"  [stderr]: {stderr[:300]}")

    return passed


def test_multi_turn():
    """测试多轮对话"""
    print("\n" + "=" * 50)
    print("[测试 5] 多轮对话")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["你好", "介绍一下仓颉", "/exit"], timeout=40)

    passed = True
    # 检查 AI> 出现至少两次（两轮对话）
    ai_count = stdout.count("AI>")
    checks = [
        ("两轮对话回复", ai_count >= 2),
        ("正常退出", "再见" in stdout),
    ]

    for name, result in checks:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")
        if not result:
            passed = False

    if not passed:
        print(f"  [AI> 出现次数]: {ai_count}")
        print(f"  [输出预览]: {stdout[:600]}")

    return passed


def main():
    print("=" * 60)
    print("  AIChatPro 自动化测试")
    print("=" * 60)

    # 启动模拟服务器
    mock_proc = start_mock_server()

    results = []
    try:
        # 运行测试
        results.append(("help 命令", test_help_command()))
        results.append(("clear 命令", test_clear_command()))
        results.append(("未知命令", test_unknown_command()))
        results.append(("模拟对话", test_chat_with_mock()))
        results.append(("多轮对话", test_multi_turn()))
    finally:
        # 停止模拟服务器
        print("\n[测试] 停止模拟服务器...")
        mock_proc.terminate()
        try:
            mock_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            mock_proc.kill()

    # 汇总结果
    print("\n" + "=" * 60)
    print("  测试结果汇总")
    print("=" * 60)

    total = len(results)
    passed = sum(1 for _, r in results if r)
    failed = total - passed

    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")

    print(f"\n  总计: {total} | 通过: {passed} | 失败: {failed}")

    if failed > 0:
        print("\n  ⚠️ 部分测试失败！")
        sys.exit(1)
    else:
        print("\n  🎉 所有测试通过！")
        sys.exit(0)


if __name__ == "__main__":
    main()
