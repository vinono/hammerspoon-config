-- ==========================================================
-- 日式键盘 (JIS) 输入法切换：自动自愈极速版 (含防失效看门狗)
-- ==========================================================

local CHINESE_ID = "com.apple.inputmethod.SCIM.ITABC"
local ENGLISH_ID = "com.apple.keylayout.ABC"
local JIS_EISUU, JIS_KANA = 102, 104

-- 重置旧资源，防止重载泄漏
if JisKeyInterceptor then pcall(function() JisKeyInterceptor:stop() end) end
if JisAppWatcher then pcall(function() JisAppWatcher:stop() end) end
if JisWatchdogTimer then pcall(function() JisWatchdogTimer:stop() end) end

-- 核心按键拦截器
_G.JisKeyInterceptor = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local code = event:getKeyCode()
    if code ~= JIS_KANA and code ~= JIS_EISUU then return false end

    -- 忽略按键连发与 Secure Input 场景
    local isRepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat)
    if isRepeat and isRepeat ~= 0 then return true end
    local okSecure, secure = pcall(hs.eventtap.isSecureInputEnabled)
    if okSecure and secure then return false end

    local okID, currentID = pcall(hs.keycodes.currentSourceID)
    if not okID then currentID = "" end

    -- 1. Kana 键 -> 切中文
    if code == JIS_KANA then
        if currentID == CHINESE_ID then return false end -- 已是中文模式时放行，退出拼音内部英文模式
        pcall(hs.keycodes.currentSourceID, CHINESE_ID)
        return true
    end

    -- 2. Eisuu 键 -> 切英文
    if code == JIS_EISUU then
        if currentID ~= ENGLISH_ID then
            pcall(hs.keycodes.currentSourceID, ENGLISH_ID)
        end
        return true
    end

    return false
end)

_G.JisKeyInterceptor:start()

-- 零 CPU 消耗自愈看门狗：当监听器被 macOS 静默关闭时自动唤醒
local function keepAlive()
    if JisKeyInterceptor then
        local ok, enabled = pcall(function() return JisKeyInterceptor:isEnabled() end)
        if not ok or not enabled then
            pcall(function() JisKeyInterceptor:start() end)
        end
    end
end

-- 1. 应用激活看门狗（事件驱动，平时 CPU 占用 0.0%）
_G.JisAppWatcher = hs.application.watcher.new(function(_, eventType)
    if eventType == hs.application.watcher.activated then keepAlive() end
end)
_G.JisAppWatcher:start()

-- 2. 定时巡检看门狗（每 2 秒检查一次，耗时微秒级，CPU 占用 0.0%）
_G.JisWatchdogTimer = hs.timer.doEvery(2.0, keepAlive)
