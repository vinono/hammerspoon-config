#!/usr/bin/env bash
# ==============================================================================
# JIS 键盘中英切换验证测试入口脚本
# 用法:
#   ./test_jis_ime.sh                # 自动运行完整测试（含自动化逻辑验证与按键测试）
#   ./test_jis_ime.sh --auto-only    # 仅运行自动化验证测试，不等待物理按键
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUA_TEST="$DIR/tests/test_jis_ime.lua"
PY_TEST="$DIR/tests/live_keypress_test.py"

# 1. 运行自动化规则验证测试
hs -c "dofile('$LUA_TEST')"

# 2. 如果没有指定 --auto-only，进入物理按键测试
if [[ "$1" != "--auto-only" ]]; then
    python3 "$PY_TEST"
fi
