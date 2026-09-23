#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
JIS 键盘物理按键实时检测测试 (Live Keypress Test)
检测用户在日式键盘上按下【英数 (Eisuu)】与【かな (Kana)】键时的实时响应与输入法切换结果。
"""

import sys
import time
import json
import subprocess

GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
BOLD = "\033[1m"
RESET = "\033[0m"

ENGLISH_ID = "com.apple.keylayout.ABC"
CHINESE_ID = "com.apple.inputmethod.SCIM.ITABC"

def run_hs_cmd(cmd):
    try:
        res = subprocess.run(
            ["hs", "-c", cmd],
            capture_output=True,
            text=True,
            timeout=5
        )
        return res.stdout.strip()
    except Exception as e:
        return ""

def get_last_key_event():
    out = run_hs_cmd("return hs.json.encode(_G.JisLastKeyEvent or {})")
    try:
        # 去掉可能的 loading 提示行
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("{") or line.startswith("["):
                data = json.loads(line)
                if isinstance(data, dict):
                    return data
        return {}
    except:
        return {}

def get_current_source():
    return run_hs_cmd("return hs.keycodes.currentSourceID()")

def wait_for_key(target_code, target_name, expected_source, timeout=12):
    # 先清空上一次事件
    run_hs_cmd("_G.JisLastKeyEvent = nil")
    start_time = time.time()
    
    print(f"\n👉 {BOLD}[物理按键测试]{RESET} 请在键盘上按下【{CYAN}{target_name}{RESET}】键（限时 {timeout} 秒）...")
    sys.stdout.flush()
    
    while time.time() - start_time < timeout:
        event = get_last_key_event()
        if event.get("keyCode") == target_code:
            time.sleep(0.15) # 等待输入法切换生效
            current_src = get_current_source()
            print(f"   {GREEN}✔ 捕获到物理按键事件！{RESET}")
            print(f"     - 物理按键代码: KeyCode {event.get('keyCode')} ({target_name})")
            print(f"     - 切换后输入法: {current_src}")
            if current_src == expected_source:
                print(f"     {GREEN}{BOLD}[PASS] 成功切换为预期输入法: {expected_source}{RESET}")
                return True
            else:
                print(f"     {RED}{BOLD}[FAIL] 切换后输入法与预期不符 (期望: {expected_source}, 实际: {current_src}){RESET}")
                return False
        time.sleep(0.08)
    
    print(f"   {YELLOW}⌛ 超时未检测到按键按下，已自动跳过此项测试。{RESET}")
    return None

def main():
    print(f"\n{BOLD}======================================================================{RESET}")
    print(f"{BOLD}       JIS 键盘物理按键实时响应测试 (Live Hardware Test){RESET}")
    print(f"{BOLD}======================================================================{RESET}")
    print("本测试将实时监听您的物理按键操作，验证日式键盘两个核心切换键的硬件响应。\n")
    
    # 测试 1: 英数键 (102) -> 英文 ABC
    # 先临时切到中文，以便观察英数键的切换效果
    run_hs_cmd(f'hs.keycodes.currentSourceID("{CHINESE_ID}")')
    time.sleep(0.1)
    res_eisuu = wait_for_key(102, "英数 (Eisuu)", ENGLISH_ID, timeout=10)
    
    # 测试 2: かな键 (104) -> 简体拼音
    time.sleep(0.5)
    res_kana = wait_for_key(104, "かな (Kana)", CHINESE_ID, timeout=10)
    
    print(f"\n{BOLD}======================================================================{RESET}")
    print(f"{BOLD}测试总结：{RESET}")
    if res_eisuu is True and res_kana is True:
        print(f"  {GREEN}{BOLD}🎉 物理按键与输入法切换全部验证通过！[PERFECT]{RESET}")
    elif res_eisuu is False or res_kana is False:
        print(f"  {RED}{BOLD}❌ 部分按键切换未达到预期结果，请检查系统输入法设置。{RESET}")
    else:
        print(f"  {CYAN}ℹ️ 未在限时内完成全部物理按键测试，您随时可重新运行此测试。{RESET}")
    print(f"{BOLD}======================================================================{RESET}\n")

if __name__ == "__main__":
    main()
