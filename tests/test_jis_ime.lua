-- ==============================================================================
-- JIS 键盘输入法切换自动化验证套件 (Terminal Automated Test Runner)
-- 验证目标：
--   1. 自动化触发【音速/英数按钮】(KeyCode 102)，验证当前输入法切换为英文 (ABC)
--   2. 自动化触发【日式键盘另一按钮/かな】(KeyCode 104)，验证当前输入法切换为中文 (简体拼音)
--   3. 验证 KeyDown / KeyUp 成对拦截与消费状态机
--   4. 验证中文模式下重复按【かな】的穿透自愈放行逻辑
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
print(string.format("%s       JIS 键盘中英切换自动化验证测试 (Terminal Automated Runner)%s", BOLD, RESET))
print(string.format("%s======================================================================%s\n", BOLD, RESET))

local initialSource = hs.keycodes.currentSourceID()
info(string.format("测试开始前当前系统输入法: %s", initialSource or "unknown"))

-- -----------------------------------------------------------------------------
-- 阶段 1: 系统环境与输入源就绪性检查
-- -----------------------------------------------------------------------------
print(string.format("\n%s[阶段 1] 系统输入源与 EventTap 就绪性检查%s", BOLD, RESET))

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
    pass(string.format("系统英文输入法已就绪: %s", englishSource))
else
    fail(string.format("系统未启用英文输入法: %s", englishSource))
end

if sourceIsEnabled(chineseSource) then
    pass(string.format("系统中文输入法已就绪: %s", chineseSource))
else
    fail(string.format("系统未启用简体拼音输入法: %s", chineseSource))
end

if jisInputEventTap and jisInputEventTap:isEnabled() then
    pass("Hammerspoon JIS 拦截器 (jisInputEventTap) 处于活跃监听状态")
else
    fail("Hammerspoon JIS 拦截器未启动")
end

if type(_G.handleJisInputEvent) == "function" then
    pass("核心按键调度句柄 (_G.handleJisInputEvent) 已就绪")
else
    fail("未找到 _G.handleJisInputEvent 句柄")
end

-- -----------------------------------------------------------------------------
-- 阶段 2: 自动化执行【音速/英数按钮 (102)】并判断输入法是否调整为英文
-- -----------------------------------------------------------------------------
print(string.format("\n%s[阶段 2] 自动化测试：执行【音速/英数 (Eisuu 102)】-> 切换为英文%s", BOLD, RESET))

-- 准备前置环境：先确保当前为中文状态
hs.keycodes.currentSourceID(chineseSource)
hs.timer.usleep(150000)
info(string.format("前置状态已设为: %s", hs.keycodes.currentSourceID()))

-- 自动化触发 KeyDown 102 与 KeyUp 102
local evDown102 = hs.eventtap.event.newKeyEvent({}, jisEisuu, true)
local evUp102 = hs.eventtap.event.newKeyEvent({}, jisEisuu, false)

local consumedDown102 = _G.handleJisInputEvent(evDown102)
local consumedUp102 = _G.handleJisInputEvent(evUp102)
hs.timer.usleep(150000)

local sourceAfter102 = hs.keycodes.currentSourceID()
info(string.format("按下英数键后，系统当前输入法为: %s", sourceAfter102))

if sourceAfter102 == englishSource then
    pass("【输入法断言】当前输入法成功调整为 ABC 英文 (com.apple.keylayout.ABC)")
else
    fail("【输入法断言】未能调整为英文", string.format("期望: %s, 实际: %s", englishSource, sourceAfter102))
end

if consumedDown102 == true and consumedUp102 == true then
    pass("【事件流断言】KeyDown 与 KeyUp 均被精准拦截消费，0 孤立按键泄露")
else
    fail("【事件流断言】成对消费状态不符合预期")
end

-- -----------------------------------------------------------------------------
-- 阶段 3: 自动化执行【日式键盘另外一个按钮 / かな (104)】并判断输入法是否调整为中文
-- -----------------------------------------------------------------------------
print(string.format("\n%s[阶段 3] 自动化测试：执行【日式键盘另一键 (かな 104)】-> 切换为中文%s", BOLD, RESET))

-- 前置状态：此时输入法已经是英文
info(string.format("前置状态已设为: %s", hs.keycodes.currentSourceID()))

-- 自动化触发 KeyDown 104 与 KeyUp 104
local evDown104 = hs.eventtap.event.newKeyEvent({}, jisKana, true)
local evUp104 = hs.eventtap.event.newKeyEvent({}, jisKana, false)

local consumedDown104 = _G.handleJisInputEvent(evDown104)
local consumedUp104 = _G.handleJisInputEvent(evUp104)
hs.timer.usleep(150000)

local sourceAfter104 = hs.keycodes.currentSourceID()
info(string.format("按下かな键后，系统当前输入法为: %s", sourceAfter104))

if sourceAfter104 == chineseSource then
    pass("【输入法断言】当前输入法成功调整为简体拼音 (com.apple.inputmethod.SCIM.ITABC)")
else
    fail("【输入法断言】未能调整为简体拼音", string.format("期望: %s, 实际: %s", chineseSource, sourceAfter104))
end

if consumedDown104 == true and consumedUp104 == true then
    pass("【事件流断言】KeyDown 与 KeyUp 均被精准拦截消费，0 孤立按键泄露")
else
    fail("【事件流断言】成对消费状态不符合预期")
end

-- -----------------------------------------------------------------------------
-- 阶段 4: 自动化执行【中文模式下再次按かな】的穿透自愈测试
-- -----------------------------------------------------------------------------
print(string.format("\n%s[阶段 4] 自动化测试：已处于中文时再次按【かな】的穿透自愈验证%s", BOLD, RESET))

-- 当前已经是中文，再次触发 104 按键
local evDown104_again = hs.eventtap.event.newKeyEvent({}, jisKana, true)
local evUp104_again = hs.eventtap.event.newKeyEvent({}, jisKana, false)

local consumedDown104_2 = _G.handleJisInputEvent(evDown104_again)
local consumedUp104_2 = _G.handleJisInputEvent(evUp104_again)
hs.timer.usleep(100000)

if consumedDown104_2 == false and consumedUp104_2 == false then
    pass("【自愈断言】检测到当前已是中文，事件未被消费，成功对称放行给系统原生驱动以重置内部英文子模式")
else
    fail("【自愈断言】按键未按预期穿透放行")
end

if hs.keycodes.currentSourceID() == chineseSource then
    pass("【输入法断言】系统当前输入法稳定保持在简体拼音")
else
    fail("【输入法断言】输入法状态异常变更")
end

-- -----------------------------------------------------------------------------
-- 阶段 5: 自动化中英往返交替压测 (Eisuu -> Kana -> Eisuu -> Kana)
-- -----------------------------------------------------------------------------
print(string.format("\n%s[阶段 5] 自动化高频交替切换压测 (3 轮往返)%s", BOLD, RESET))

local allCyclesPassed = true
for round = 1, 3 do
    -- 切英文
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisEisuu, true))
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisEisuu, false))
    hs.timer.usleep(40000)
    local s1 = hs.keycodes.currentSourceID()

    -- 切中文
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisKana, true))
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisKana, false))
    hs.timer.usleep(40000)
    local s2 = hs.keycodes.currentSourceID()

    if s1 ~= englishSource or s2 ~= chineseSource then
        allCyclesPassed = false
        fail(string.format("第 %d 轮交替切换失败 (英: %s, 中: %s)", round, s1, s2))
        break
    end
end

if allCyclesPassed then
    pass("高频连续交替切换 100% 成功，系统输入法响应无时序竞态")
end

-- 恢复测试前的初始输入法
hs.keycodes.currentSourceID(initialSource)
info(string.format("已恢复初始输入法: %s", initialSource))

-- -----------------------------------------------------------------------------
-- 汇总报告
-- -----------------------------------------------------------------------------
print(string.format("\n%s======================================================================%s", BOLD, RESET))
if failCount == 0 then
    print(string.format("  %s%s全部自动化验证通过！[ALL %d CHECKS PASSED]%s", BOLD, GREEN, passCount, RESET))
    print(string.format("  ✔ 【音速/英数按钮 (102)】 -> 自动化调整为英文 (ABC): %s通过%s", GREEN, RESET))
    print(string.format("  ✔ 【日式键盘另一按钮/かな (104)】 -> 自动化调整为中文 (简体拼音): %s通过%s", GREEN, RESET))
    print(string.format("  ✔ KeyDown + KeyUp 成对消费与穿透自愈: %s通过%s", GREEN, RESET))
else
    print(string.format("  %s%s测试存在未通过项！(通过: %d, 失败: %d)%s", BOLD, RED, passCount, failCount, RESET))
end
print(string.format("%s======================================================================%s\n", BOLD, RESET))
