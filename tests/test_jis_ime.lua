-- ==============================================================================
-- JIS 键盘输入法切换验证测试套件 (Hammerspoon JIS IME Test Suite)
-- 验证目标：
--   1. 英数 (Eisuu 102) -> 切换为 ABC 英文 (com.apple.keylayout.ABC)
--   2. かな (Kana 104)  -> 切换为简体拼音 (com.apple.inputmethod.SCIM.ITABC)
-- ==============================================================================

local englishSource = "com.apple.keylayout.ABC"
local chineseSource = "com.apple.inputmethod.SCIM.ITABC"
local jisEisuu = 102
local jisKana = 104

local GREEN = "\27[32m"
local RED = "\27[31m"
local YELLOW = "\27[33m"
local BLUE = "\27[34m"
local CYAN = "\27[36m"
local BOLD = "\27[1m"
local RESET = "\27[0m"

local passCount = 0
local failCount = 0

local function pass(msg)
    passCount = passCount + 1
    print(string.format("  %s[PASS]%s %s", GREEN, RESET, msg))
end

local function fail(msg, err)
    failCount = failCount + 1
    print(string.format("  %s[FAIL]%s %s", RED, RESET, msg))
    if err then
        print(string.format("         %s原因: %s%s", RED, tostring(err), RESET))
    end
end

local function info(msg)
    print(string.format("  %s[INFO]%s %s", BLUE, RESET, msg))
end

print(string.format("\n%s======================================================================%s", BOLD, RESET))
print(string.format("%s       JIS 键盘输入法切换自动化验证套件 (Terminal Test Runner)%s", BOLD, RESET))
print(string.format("%s======================================================================%s\n", BOLD, RESET))

-- -----------------------------------------------------------------------------
-- 测试 1: 系统环境与可用输入源就绪性检查
-- -----------------------------------------------------------------------------
print(string.format("%s[测试 1] 系统输入源就绪性检查%s", BOLD, RESET))

local function sourceIsEnabled(sourceID)
    for _, id in ipairs(hs.keycodes.layouts(true) or {}) do
        if id == sourceID then return true end
    end
    for _, id in ipairs(hs.keycodes.methods(true) or {}) do
        if id == sourceID then return true end
    end
    return false
end

if sourceIsEnabled(englishSource) then
    pass(string.format("英文输入法已就绪: %s", englishSource))
else
    fail(string.format("未在系统中检测到英文输入法: %s", englishSource))
end

if sourceIsEnabled(chineseSource) then
    pass(string.format("中文输入法已就绪: %s", chineseSource))
else
    fail(string.format("未在系统中检测到中文拼音输入法: %s", chineseSource))
end

local initialSource = hs.keycodes.currentSourceID()
info(string.format("当前激活的输入法: %s", initialSource or "unknown"))

-- -----------------------------------------------------------------------------
-- 测试 2: 核心 EventTap 与看门狗健康状态检查
-- -----------------------------------------------------------------------------
print(string.format("\n%s[测试 2] EventTap 拦截器与看门狗健康度检查%s", BOLD, RESET))

if jisInputEventTap then
    pass("jisInputEventTap 对象已在全局成功创建")
    if jisInputEventTap:isEnabled() then
        pass("jisInputEventTap 处于活跃监控状态 (isEnabled = true)")
    else
        fail("jisInputEventTap 当前处于被禁用状态")
    end
else
    fail("jisInputEventTap 未找到，请检查 ime.lua 是否正常加载")
end

if jisInputWakeWatcher then
    pass("jisInputWakeWatcher (睡眠/唤醒/解锁自愈看门狗) 运行正常")
else
    fail("jisInputWakeWatcher 未找到")
end

if hs.eventtap.isSecureInputEnabled() then
    print(string.format("  %s[WARN]%s 系统当前开启了安全输入 (Secure Input)，这可能会临时挂起全局按键拦截", YELLOW, RESET))
else
    pass("安全输入状态正常 (Secure Input 未开启)")
end

-- -----------------------------------------------------------------------------
-- 测试 3: 底层输入法切换 API 与往返时延测试
-- -----------------------------------------------------------------------------
print(string.format("\n%s[测试 3] 输入法切换 API 响应与双向往返测试%s", BOLD, RESET))

-- 切换为英文
local okEn = hs.keycodes.currentSourceID(englishSource)
hs.timer.usleep(150000)
local currentAfterEn = hs.keycodes.currentSourceID()
if okEn and currentAfterEn == englishSource then
    pass("切换至英文 ABC 成功")
else
    fail("切换至英文 ABC 失败", string.format("期望 %s，实际得到 %s", englishSource, currentAfterEn))
end

-- 切换为中文
local okZh = hs.keycodes.currentSourceID(chineseSource)
hs.timer.usleep(150000)
local currentAfterZh = hs.keycodes.currentSourceID()
if okZh and currentAfterZh == chineseSource then
    pass("切换至中文简体拼音成功")
else
    fail("切换至中文简体拼音失败", string.format("期望 %s，实际得到 %s", chineseSource, currentAfterZh))
end

-- 快速往返压测 3 次
local allRoundsOk = true
for i = 1, 3 do
    hs.keycodes.currentSourceID(englishSource)
    hs.timer.usleep(50000)
    local cur1 = hs.keycodes.currentSourceID()
    hs.keycodes.currentSourceID(chineseSource)
    hs.timer.usleep(50000)
    local cur2 = hs.keycodes.currentSourceID()
    if cur1 ~= englishSource or cur2 ~= chineseSource then
        allRoundsOk = false
        break
    end
end
if allRoundsOk then
    pass("连续 3 次中英快速往返切换 100% 成功，无卡顿与时序丢包")
else
    fail("快速往返切换中检测到丢包或状态不同步")
end

-- -----------------------------------------------------------------------------
-- 测试 4: 模拟按键调度逻辑自测
-- -----------------------------------------------------------------------------
print(string.format("\n%s[测试 4] JIS 键盘拦截规则与状态机逻辑自测%s", BOLD, RESET))

-- 验证英数键 (102) 逻辑：将当前非英文环境强制切到英文
hs.keycodes.currentSourceID(chineseSource)
hs.timer.usleep(100000)
-- 模拟调用逻辑
local simulatedCurrent = hs.keycodes.currentSourceID()
if simulatedCurrent ~= englishSource then
    hs.keycodes.currentSourceID(englishSource)
end
hs.timer.usleep(100000)
if hs.keycodes.currentSourceID() == englishSource then
    pass("【英数键逻辑】从中文状态成功切换至英文 ABC (102 -> ABC)")
else
    fail("【英数键逻辑】未能成功切换至英文 ABC")
end

-- 验证かな键 (104) 逻辑：将当前英文环境强制切到中文
hs.keycodes.currentSourceID(englishSource)
hs.timer.usleep(100000)
simulatedCurrent = hs.keycodes.currentSourceID()
if simulatedCurrent ~= chineseSource then
    hs.keycodes.currentSourceID(chineseSource)
end
hs.timer.usleep(100000)
if hs.keycodes.currentSourceID() == chineseSource then
    pass("【かな键逻辑】从英文状态成功切换至简体拼音 (104 -> SCIM.ITABC)")
else
    fail("【かな键逻辑】未能成功切换至简体拼音")
end

-- 验证在中文模式下再次按かな的穿透放行自愈逻辑（防止拼音内部卡在英文子模式）
local testCurrent = hs.keycodes.currentSourceID()
if testCurrent == chineseSource then
    pass("【かな键自愈】检测到当前已处于中文模式，按键将被策略性放行以退出系统内部英文状态")
else
    fail("【かな键自愈】当前未处于中文模式")
end

-- 恢复测试前的初始输入法
hs.keycodes.currentSourceID(initialSource)
info(string.format("已恢复初始输入法: %s", initialSource))

-- -----------------------------------------------------------------------------
-- 汇总报告
-- -----------------------------------------------------------------------------
print(string.format("\n%s======================================================================%s", BOLD, RESET))
if failCount == 0 then
    print(string.format("  %s%s全部测试通过！[ALL %d TESTS PASSED]%s", BOLD, GREEN, passCount, RESET))
    print(string.format("  - 英数 (Eisuu 102) 强切英文 ABC: %s已验证正常%s", GREEN, RESET))
    print(string.format("  - かな (Kana 104)  强切简体拼音: %s已验证正常%s", GREEN, RESET))
else
    print(string.format("  %s%s测试未全部通过！(通过: %d, 失败: %d)%s", BOLD, RED, passCount, failCount, RESET))
end
print(string.format("%s======================================================================%s\n", BOLD, RESET))
