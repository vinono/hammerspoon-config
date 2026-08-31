-- 豆包全局语音结束后恢复之前的输入法。
--
-- 豆包全局语音启动时会把当前输入源切到豆包；这个模块持续记住最近的
-- 非豆包输入源。只有确认豆包的语音浮窗出现过、随后又消失时，才会在
-- 2 秒后恢复，避免录音期间被固定时长的定时器提前打断。

local DOUBAO_BUNDLE_ID = "com.bytedance.inputmethod.doubaoime"
local DOUBAO_SOURCE_PREFIX = "com.bytedance.inputmethod.doubaoime"
local SYSTEM_SOURCE_IDS = {
    ["com.apple.keylayout.ABC"] = true,
    ["com.apple.inputmethod.SCIM.ITABC"] = true,
}
local POLL_INTERVAL = 0.15
local RESTORE_DELAY = 2.0
local STABLE_SOURCE_DELAY = 0.6

local log = hs.logger.new("DoubaoReturn", "info")
local lastStableNonDoubaoSource = nil
local candidateNonDoubaoSource = nil
local candidateSince = nil
local voiceSessionActive = false
local voiceWindowWasVisible = false
local restoreTimer = nil

local function isDoubaoSource(sourceID)
    return type(sourceID) == "string"
        and sourceID:sub(1, #DOUBAO_SOURCE_PREFIX) == DOUBAO_SOURCE_PREFIX
end

local function isSystemZhOrEn(sourceID)
    return SYSTEM_SOURCE_IDS[sourceID] == true
end

local function cancelRestore()
    if restoreTimer then
        restoreTimer:stop()
        restoreTimer = nil
    end
end

local function hasVisibleDoubaoWindow()
    local app = hs.application.get(DOUBAO_BUNDLE_ID)
    if not app then
        return false
    end

    for _, window in ipairs(app:allWindows()) do
        if window:isVisible() and not window:isMinimized() then
            return true
        end
    end

    return false
end

local function restorePreviousSource()
    restoreTimer = nil

    if lastStableNonDoubaoSource then
        hs.keycodes.currentSourceID(lastStableNonDoubaoSource)
        log.i("豆包语音结束，已恢复: " .. lastStableNonDoubaoSource)
    end

    voiceSessionActive = false
    voiceWindowWasVisible = false
end

local function scheduleRestore()
    if restoreTimer then
        return
    end

    restoreTimer = hs.timer.doAfter(RESTORE_DELAY, restorePreviousSource)
    log.i(string.format("豆包语音浮窗已关闭，%.1f 秒后恢复输入法", RESTORE_DELAY))
end

if _G.DoubaoReturnWatcher then
    _G.DoubaoReturnWatcher:stop()
end

_G.DoubaoReturnWatcher = hs.timer.doEvery(POLL_INTERVAL, function()
    local currentSource = hs.keycodes.currentSourceID()
    local usingDoubao = isDoubaoSource(currentSource)

    if not usingDoubao then
        -- 豆包会经历「原输入法 -> 系统拼音 -> 豆包」的短暂过渡，也可能在
        -- 关闭浮窗时先落到系统拼音。只要本次会话已进入豆包，后续离开豆包
        -- 都应恢复语音前的稳定快照，不能把这个过渡中文当作原输入法。
        if voiceSessionActive then
            scheduleRestore()
            return
        end

        cancelRestore()
        if not isSystemZhOrEn(currentSource) then
            return
        end

        local now = hs.timer.secondsSinceEpoch()
        if candidateNonDoubaoSource ~= currentSource then
            candidateNonDoubaoSource = currentSource
            candidateSince = now

            -- 脚本刚加载时，当前输入源就是可信的初始快照。
            if not lastStableNonDoubaoSource then
                lastStableNonDoubaoSource = currentSource
            end
        elseif candidateSince and now - candidateSince >= STABLE_SOURCE_DELAY then
            lastStableNonDoubaoSource = currentSource
        end
        return
    end

    if not voiceSessionActive then
        -- 日式键盘的英数/かな处理器会在按键发生时立即保存用户意图；这比
        -- 豆包触发时短暂经过的系统拼音更可靠。
        if isSystemZhOrEn(_G.LastSystemInputSourceID) then
            lastStableNonDoubaoSource = _G.LastSystemInputSourceID
        end
        voiceSessionActive = true
        log.i("检测到已切换为豆包；将等待语音浮窗出现后再监听结束")
    end

    local voiceWindowVisible = hasVisibleDoubaoWindow()
    if voiceWindowVisible then
        voiceWindowWasVisible = true
        cancelRestore()
    elseif voiceWindowWasVisible then
        scheduleRestore()
    end
end)

log.i("豆包语音自动回切监视器已启动")
