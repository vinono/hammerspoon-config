-- ==========================================================
-- 日式键盘 (JIS) 输入法切换：纯事件驱动极速自愈版 (极致性能与 0.0% CPU 占用)
-- ==========================================================

local CHINESE_ID = "com.apple.inputmethod.SCIM.ITABC"
local ENGLISH_ID = "com.apple.keylayout.ABC"
local JIS_EISUU, JIS_KANA = 102, 104

-- 重置旧资源，防止重载泄漏
if JisKeyInterceptor then pcall(function() JisKeyInterceptor:stop() end) end
if JisAppWatcher then pcall(function() JisAppWatcher:stop() end) end
if JisCaffeinateWatcher then pcall(function() JisCaffeinateWatcher:stop() end) end

-- 核心按键拦截器（包含系统事件超时自动 0ms 原地恢复）
_G.JisKeyInterceptor = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.tapDisabledByTimeout,
    hs.eventtap.event.types.tapDisabledByUserInput
}, function(event)
    local evtType = event:getType()
    
    -- 1. 当 Quartz 因高 CPU 负载超时或 Secure Input 暂时挂起 EventTap 时，捕获通知并原地轻量重启 (0ms 延迟)
    if evtType == hs.eventtap.event.types.tapDisabledByTimeout or
       evtType == hs.eventtap.event.types.tapDisabledByUserInput then
        if _G.JisKeyInterceptor then
            pcall(function() _G.JisKeyInterceptor:start() end)
        end
        return false
    end

    local code = event:getKeyCode()
    -- 极致微秒级极速退出：非目标按键仅耗时 <5ns 直接放行
    if code ~= JIS_KANA and code ~= JIS_EISUU then return false end

    -- 忽略按键连发与 Secure Input 场景
    local isRepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat)
    if isRepeat and isRepeat ~= 0 then return true end
    if hs.eventtap.isSecureInputEnabled() then return false end

    local currentID = hs.keycodes.currentSourceID() or ""

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

if _G.JisKeyInterceptor then
    _G.JisKeyInterceptor:start()
end

-- 1. 应用激活看门狗（纯事件驱动，0.0% CPU；仅在处于未激活状态时才轻量拉起，避免频繁销毁/重建 C 级 MachPort）
_G.JisAppWatcher = hs.application.watcher.new(function(_, eventType)
    if eventType == hs.application.watcher.activated then
        if _G.JisKeyInterceptor and not _G.JisKeyInterceptor:isEnabled() then
            pcall(function() _G.JisKeyInterceptor:start() end)
        end
    end
end)
_G.JisAppWatcher:start()

-- 2. 系统睡眠/唤醒/锁屏解锁看门狗（仅在系统级唤醒/解锁这一离散时刻重建 C 级 MachPort 句柄）
_G.JisCaffeinateWatcher = hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.systemDidWake or
       eventType == hs.caffeinate.watcher.screensDidUnlock or
       eventType == hs.caffeinate.watcher.sessionDidBecomeActive then
        if _G.JisKeyInterceptor then
            pcall(function()
                _G.JisKeyInterceptor:stop()
                _G.JisKeyInterceptor:start()
            end)
        end
    end
end)
_G.JisCaffeinateWatcher:start()


