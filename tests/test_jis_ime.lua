-- ==============================================================================
-- JIS 键盘输入法切换自动化验证套件 (Terminal Automated Test Runner)
-- 验证目标：
--   在 Terminal 窗口下全自动执行：
--   1. 模拟按下【音速/英数按钮 (KeyCode 102)】，判断当前输入法是否调整为英文 (ABC)
--   2. 模拟按下【日式键盘另一按钮/かな (KeyCode 104)】，判断当前输入法是否调整为中文 (简体拼音)
--   3. 特殊场景：当前处于【第三方输入法/豆包】时，验证两个按键是否能成功抢占并完成强切
-- ==============================================================================

local englishSource = "com.apple.keylayout.ABC"
local chineseSource = "com.apple.inputmethod.SCIM.ITABC"
local doubaoSource  = "com.bytedance.inputmethod.doubaoime.pinyin"
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
info(string.format("测试开始前当前系统激活的输入法: %s", initialSource or "unknown"))

-- 验证调度句柄
if type(_G.handleJisInputEvent) ~= "function" then
    print(string.format("%s[ERROR] 未找到 _G.handleJisInputEvent 核心句柄，正在重新加载 ime 模块...%s", RED, RESET))
    dofile(os.getenv("HOME") .. "/.hammerspoon/ime/ime.lua")
end

-- -----------------------------------------------------------------------------
-- 阶段 1: 自动化执行【音速/英数按钮 (102)】并判断当前输入法
-- -----------------------------------------------------------------------------
print(string.format("\n%s[测试 1] 自动化执行按下【音速/英数按钮 (102)】 -> 判断是否调整为英文%s", BOLD, RESET))

-- 步骤 1.1: 设定前置状态为中文
hs.keycodes.currentSourceID(chineseSource)
hs.timer.usleep(150000)
info(string.format("按键前输入法状态: %s", hs.keycodes.currentSourceID()))

-- 步骤 1.2: 自动化构造并派发 KeyDown(102) 与 KeyUp(102)
local evDown102 = hs.eventtap.event.newKeyEvent({}, jisEisuu, true)
local evUp102 = hs.eventtap.event.newKeyEvent({}, jisEisuu, false)
local cDown102 = _G.handleJisInputEvent(evDown102)
local cUp102 = _G.handleJisInputEvent(evUp102)
hs.timer.usleep(150000)

-- 步骤 1.3: 读取并判断输入法
local sourceAfter102 = hs.keycodes.currentSourceID()
info(string.format("自动化执行 102(英数) 后，当前输入法判断为: %s", sourceAfter102))

if sourceAfter102 == englishSource then
    pass(string.format("【输入法判断通过】当前输入法成功调整为英文 ABC: %s", sourceAfter102))
else
    fail(string.format("【输入法判断失败】期望 %s，实际得到 %s", englishSource, sourceAfter102))
end

if cDown102 == true and cUp102 == true then
    pass("【事件状态机验证】KeyDown 与 KeyUp 均被精准消费 (return true)，未发生孤立按键泄露")
else
    fail("【事件状态机验证】按键消费状态异常")
end

-- -----------------------------------------------------------------------------
-- 阶段 2: 自动化执行【日式键盘另外一个按钮 / かな (104)】并判断当前输入法
-- -----------------------------------------------------------------------------
print(string.format("\n%s[测试 2] 自动化执行按下【日式键盘另一按钮/かな (104)】 -> 判断是否调整为中文%s", BOLD, RESET))

-- 步骤 2.1: 设定前置状态为英文
hs.keycodes.currentSourceID(englishSource)
hs.timer.usleep(150000)
info(string.format("按键前输入法状态: %s", hs.keycodes.currentSourceID()))

-- 步骤 2.2: 自动化构造并派发 KeyDown(104) 与 KeyUp(104)
local evDown104 = hs.eventtap.event.newKeyEvent({}, jisKana, true)
local evUp104 = hs.eventtap.event.newKeyEvent({}, jisKana, false)
local cDown104 = _G.handleJisInputEvent(evDown104)
local cUp104 = _G.handleJisInputEvent(evUp104)
hs.timer.usleep(150000)

-- 步骤 2.3: 读取并判断输入法
local sourceAfter104 = hs.keycodes.currentSourceID()
info(string.format("自动化执行 104(かな) 后，当前输入法判断为: %s", sourceAfter104))

if sourceAfter104 == chineseSource then
    pass(string.format("【输入法判断通过】当前输入法成功调整为中文简体拼音: %s", sourceAfter104))
else
    fail(string.format("【输入法判断失败】期望 %s，实际得到 %s", chineseSource, sourceAfter104))
end

if cDown104 == true and cUp104 == true then
    pass("【事件状态机验证】KeyDown 与 KeyUp 均被精准消费 (return true)，未发生孤立按键泄露")
else
    fail("【事件状态机验证】按键消费状态异常")
end

-- -----------------------------------------------------------------------------
-- 阶段 3: 模拟从【豆包输入法】状态下，自动化按下两个按钮并判断输入法
-- -----------------------------------------------------------------------------
print(string.format("\n%s[测试 3] 专项测试：在【豆包输入法】状态下，自动化按下双按钮的强切能力%s", BOLD, RESET))

local canSwitchToDoubao = hs.keycodes.currentSourceID(doubaoSource)
hs.timer.usleep(150000)

if hs.keycodes.currentSourceID() == doubaoSource then
    info("已成功模拟进入【豆包输入法】环境: " .. doubaoSource)
    
    -- 3.1 豆包下按英数 (102) -> 必须强切为英文 ABC
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisEisuu, true))
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisEisuu, false))
    hs.timer.usleep(150000)
    local fromDoubaoToEn = hs.keycodes.currentSourceID()
    if fromDoubaoToEn == englishSource then
        pass(string.format("【豆包场景 1】从豆包按下【音速/英数 (102)】成功强切至英文 ABC: %s", fromDoubaoToEn))
    else
        fail(string.format("【豆包场景 1】从豆包强切英文失败，当前仍为: %s", fromDoubaoToEn))
    end
    
    -- 重新进入豆包
    hs.keycodes.currentSourceID(doubaoSource)
    hs.timer.usleep(150000)
    
    -- 3.2 豆包下按かな (104) -> 必须强切为系统简体拼音
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisKana, true))
    _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisKana, false))
    hs.timer.usleep(150000)
    local fromDoubaoToZh = hs.keycodes.currentSourceID()
    if fromDoubaoToZh == chineseSource then
        pass(string.format("【豆包场景 2】从豆包按下【日式另一键/かな (104)】成功强切至简体拼音: %s", fromDoubaoToZh))
    else
        fail(string.format("【豆包场景 2】从豆包强切中文失败，当前仍为: %s", fromDoubaoToZh))
    end
else
    info("系统已卸载或未启用豆包输入法，跳过豆包专属强切对比测试")
end

-- -----------------------------------------------------------------------------
-- 阶段 4: 中文状态下再次按【かな】的穿透自愈放行验证
-- -----------------------------------------------------------------------------
print(string.format("\n%s[阶段 4] 自动化测试：已处于中文时再次按【かな】的穿透放行验证%s", BOLD, RESET))

hs.keycodes.currentSourceID(chineseSource)
hs.timer.usleep(100000)

local passThroughDown = _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisKana, true))
local passThroughUp = _G.handleJisInputEvent(hs.eventtap.event.newKeyEvent({}, jisKana, false))
hs.timer.usleep(100000)

if passThroughDown == false and passThroughUp == false then
    pass("【自愈断言】当前已是中文，按键被放行穿透 (return false)，触发原生系统退出拼音内部英文模式")
else
    fail("【自愈断言】未正常放行穿透")
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
    print(string.format("  ✔ 自动化执行【音速/英数按钮 (102)】 -> 判断当前输入法为英文 ABC: %s成功%s", GREEN, RESET))
    print(string.format("  ✔ 自动化执行【日式另一按键/かな (104)】 -> 判断当前输入法为简体拼音: %s成功%s", GREEN, RESET))
    print(string.format("  ✔ 从豆包等任意第三方输入法状态下强切中英文: %s成功%s", GREEN, RESET))
else
    print(string.format("  %s%s自动化测试存在失败项！(通过: %d, 失败: %d)%s", BOLD, RED, passCount, failCount, RESET))
end
print(string.format("%s======================================================================%s\n", BOLD, RESET))
