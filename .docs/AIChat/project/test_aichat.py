#!/usr/bin/env python3
"""
AIChatPro 自动化测试脚本

启动模拟服务器，然后运行 AIChatPro 发送测试消息，验证：
1. 程序能正常启动并显示横幅
2. /help 命令正常工作（包含新增的 /switch、/status 命令）
3. 发送消息能获得模拟 AI 的流式回复
4. /clear 命令正常工作
5. /exit 命令能正常退出
6. /switch 命令能切换模型
7. /status 命令能显示当前状态
8. 多轮对话正常工作
9. config.json 配置文件自动生成
10. 多模型对话（切换到 glm 后继续对话）

使用方式：
    # 先确保已执行 source envsetup.sh 并 cjpm build
    python3 test_aichat.py

依赖：仅使用 Python 标准库，无需安装额外包。
"""

import subprocess
import time
import sys
import os
import json
import signal


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
    env["GLM_API_KEY"] = "test-glm-key"
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
        ("包含 /switch 命令", "/switch" in stdout),
        ("包含 /status 命令", "/status" in stdout),
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
        ("中文内容正确（无乱码）", "模拟" in stdout or "助手" in stdout or "服务" in stdout),
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


def test_switch_command():
    """测试 /switch 命令切换模型"""
    print("\n" + "=" * 50)
    print("[测试 6] /switch 命令切换模型")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/switch glm", "/status", "/exit"], timeout=20)

    passed = True
    checks = [
        ("切换成功提示", "已切换到模型" in stdout and "glm" in stdout),
        ("状态显示 glm", "glm" in stdout),
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


def test_status_command():
    """测试 /status 命令"""
    print("\n" + "=" * 50)
    print("[测试 7] /status 命令")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/status", "/exit"], timeout=20)

    passed = True
    checks = [
        ("显示当前模型", "当前模型" in stdout),
        ("显示对话历史", "对话历史" in stdout),
        ("显示 API Key 状态", "API Key" in stdout),
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


def test_switch_invalid_model():
    """测试切换到不存在的模型"""
    print("\n" + "=" * 50)
    print("[测试 8] 切换到不存在的模型")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/switch fake_model", "/exit"], timeout=20)

    passed = True
    checks = [
        ("提示未知模型", "未知模型" in stdout),
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


def test_config_json():
    """测试 config.json 配置文件自动生成"""
    print("\n" + "=" * 50)
    print("[测试 9] config.json 配置文件")
    print("=" * 50)

    # 查找可能生成的 config.json
    # 由于 getExecutablePath 可能返回 cjpm 的路径或项目路径
    # 我们检查是否有 config.json 被生成
    stdout, stderr, rc = run_aichat_test(["/exit"], timeout=20)

    passed = True

    # 查找 config.json 文件
    possible_paths = [
        os.path.join(PROJECT_DIR, "config.json"),
        os.path.join(PROJECT_DIR, "target", "release", "bin", "config.json"),
    ]
    
    config_found = False
    config_path = None
    for p in possible_paths:
        if os.path.exists(p):
            config_found = True
            config_path = p
            break

    # 也search recursively for config.json
    if not config_found:
        for root, dirs, files in os.walk(PROJECT_DIR):
            if "config.json" in files:
                config_path = os.path.join(root, "config.json")
                config_found = True
                break

    checks = [
        ("config.json 已生成", config_found),
    ]

    if config_found and config_path:
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                config_data = json.load(f)
            checks.append(("包含 default_model 字段", "default_model" in config_data))
            checks.append(("包含 models 字段", "models" in config_data))
            checks.append(("包含 kimi 模型", "kimi" in config_data.get("models", {})))
            checks.append(("包含 glm 模型", "glm" in config_data.get("models", {})))
            checks.append(("包含 minimax 模型", "minimax" in config_data.get("models", {})))
            checks.append(("包含 stream_settings", "stream_settings" in config_data))
            print(f"  [配置文件路径]: {config_path}")
        except Exception as e:
            checks.append(("配置文件可解析", False))
            print(f"  [解析错误]: {e}")

    for name, result in checks:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {status}: {name}")
        if not result:
            passed = False

    return passed


def test_glm_chat():
    """测试切换到 GLM 后进行对话"""
    print("\n" + "=" * 50)
    print("[测试 10] GLM 模型对话")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["/switch glm", "你好", "/exit"], timeout=30)

    passed = True
    checks = [
        ("切换到 glm", "已切换到模型" in stdout),
        ("显示 AI 回复", "AI>" in stdout),
        ("中文内容正确（无乱码）", "模拟" in stdout or "助手" in stdout or "服务" in stdout),
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
            print(f"  [stderr]: {stderr[:300]}")

    return passed


def test_chinese_long_response():
    """测试长中文回复（关键词：仓颉）是否正确显示"""
    print("\n" + "=" * 50)
    print("[测试 11] 长中文回复（无乱码验证）")
    print("=" * 50)

    stdout, stderr, rc = run_aichat_test(["仓颉", "/exit"], timeout=30)

    passed = True
    # 仓颉关键词应触发包含"华为"、"编程语言"等中文的回复
    checks = [
        ("显示 AI 回复", "AI>" in stdout),
        ("包含'华为'", "华为" in stdout),
        ("包含'编程语言'", "编程语言" in stdout),
        ("中文无乱码", "高性能" in stdout or "安全" in stdout or "静态类型" in stdout),
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


def main():
    print("=" * 60)
    print("  AIChatPro 自动化测试")
    print("=" * 60)

    # 清理可能存在的旧 config.json
    for root, dirs, files in os.walk(PROJECT_DIR):
        if "config.json" in files:
            os.remove(os.path.join(root, "config.json"))

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
        results.append(("switch 命令", test_switch_command()))
        results.append(("status 命令", test_status_command()))
        results.append(("无效模型切换", test_switch_invalid_model()))
        results.append(("config.json", test_config_json()))
        results.append(("GLM 模型对话", test_glm_chat()))
        results.append(("长中文回复", test_chinese_long_response()))
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

