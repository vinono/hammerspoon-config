-- ==========================================================
-- 日式键盘 (JIS) 输入法切换：稳健版
-- - 支持唤醒/解锁后自愈
-- - 记录切换失败日志
-- - Secure Input 场景不盲目吞键
-- - 前台应用切换时轻量重建 eventtap
-- ==========================================================

local CHINESE_ID = "com.apple.inputmethod.SCIM.ITABC"
local ENGLISH_ID = "com.apple.keylayout.ABC"

local JIS_EISUU = 102
local JIS_KANA = 104

local LOG_FILE = os.getenv("HOME") .. "/.hammerspoon/ime/ime.log"
local REBUILD_DELAY = 0.25

-- 重置旧的资源，防止内存泄漏/重复监听
if JisKeyInterceptor then pcall(function() JisKeyInterceptor:stop() end) JisKeyInterceptor = nil end
if JisSystemWatcher then pcall(function() JisSystemWatcher:stop() end) JisSystemWatcher = nil end
if JisAppWatcher then pcall(function() JisAppWatcher:stop() end) JisAppWatcher = nil end
if JisRebuildTimer then pcall(function() JisRebuildTimer:stop() end) JisRebuildTimer = nil end

local lastSecureInputState = nil

local function appendLog(message)
    local ok, err = pcall(function()
        local f = io.open(LOG_FILE, "a")
        if not f then return end
        f:write(os.date("%Y-%m-%d %H:%M:%S ") .. tostring(message) .. "\n")
        f:close()
    end)
    if not ok then
        print("[ime] log write failed:", err)
    end
end

local function safeCurrentSourceID()
    local ok, currentID = pcall(hs.keycodes.currentSourceID)
    if ok then return currentID end
    appendLog("read currentSourceID failed: " .. tostring(currentID))
    return nil
end

local function switchInput(targetID, label)
    local before = safeCurrentSourceID()
    if before == targetID then
        return true
    end

    local ok, result = pcall(hs.keycodes.currentSourceID, targetID)
    if not ok then
        appendLog("switch to " .. label .. " failed (pcall): " .. tostring(result))
        return false
    end

    local after = safeCurrentSourceID()
    if after ~= targetID then
        appendLog("switch to " .. label .. " not applied, before=" .. tostring(before) .. ", after=" .. tostring(after))
        return false
    end

    return true
end

local function stopInterceptor()
    if JisKeyInterceptor then
        JisKeyInterceptor:stop()
        JisKeyInterceptor = nil
    end
end

local function secureInputEnabled()
    local ok, enabled = pcall(hs.eventtap.isSecureInputEnabled)
    if ok then return enabled end
    appendLog("isSecureInputEnabled failed: " .. tostring(enabled))
    return false
end

local function buildInterceptor()
    stopInterceptor()

    JisKeyInterceptor = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local keyCode = event:getKeyCode()
        if keyCode ~= JIS_KANA and keyCode ~= JIS_EISUU then
            return false
        end

        local secure = secureInputEnabled()
        if lastSecureInputState ~= secure then
            lastSecureInputState = secure
            appendLog("secure input changed: " .. tostring(secure))
        end

        if secure then
            appendLog("secure input enabled, skip intercept for keyCode=" .. tostring(keyCode))
            return false
        end

        if keyCode == JIS_KANA then
            -- 拼音处于英文子模式时，currentSourceID 仍会是 CHINESE_ID。
            -- 此时不能吞掉原始 Kana 键，否则系统没有机会把拼音切回中文。
            if safeCurrentSourceID() == CHINESE_ID then
                appendLog("Chinese source already selected; pass through Kana for native Chinese mode")
                return false
            end
            local switched = switchInput(CHINESE_ID, "Chinese")
            return switched
        end

        if keyCode == JIS_EISUU then
            local switched = switchInput(ENGLISH_ID, "English")
            return switched
        end

        return false
    end)

    local ok, err = pcall(function() JisKeyInterceptor:start() end)
    if not ok then
        appendLog("eventtap start failed: " .. tostring(err))
        return false
    end

    appendLog("eventtap started")
    return true
end

local function scheduleRebuild(reason)
    if JisRebuildTimer then
        JisRebuildTimer:stop()
        JisRebuildTimer = nil
    end

    JisRebuildTimer = hs.timer.doAfter(REBUILD_DELAY, function()
        appendLog("rebuild interceptor: " .. tostring(reason))
        buildInterceptor()
        JisRebuildTimer = nil
    end)
end

local function installWatchers()
    if JisSystemWatcher then
        JisSystemWatcher:stop()
        JisSystemWatcher = nil
    end
    if JisAppWatcher then
        JisAppWatcher:stop()
        JisAppWatcher = nil
    end

    JisSystemWatcher = hs.caffeinate.watcher.new(function(eventType)
        if eventType == hs.caffeinate.watcher.systemDidWake or
           eventType == hs.caffeinate.watcher.screensDidUnlock then
            scheduleRebuild("wake/unlock")
        end
    end)
    JisSystemWatcher:start()

    JisAppWatcher = hs.application.watcher.new(function(appName, eventType)
        if eventType == hs.application.watcher.activated then
            scheduleRebuild("app activated: " .. tostring(appName))
        end
    end)
    JisAppWatcher:start()
end

appendLog("ime module loading")
buildInterceptor()
installWatchers()
appendLog("ime module ready")
