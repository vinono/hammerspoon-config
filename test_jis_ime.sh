#!/usr/bin/env bash
# ==============================================================================
# JIS 键盘中英切换自动化验证脚本
# 在 VS Code Terminal 中直接运行：
#   ./test_jis_ime.sh
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUA_TEST="$DIR/tests/test_jis_ime.lua"

hs -c "dofile('$LUA_TEST')"
