-- ==========================================================
-- 日式键盘 (JIS) 输入法切换：极简极速版
-- ==========================================================

local CHINESE_ID = "com.apple.inputmethod.SCIM.ITABC"
local ENGLISH_ID = "com.apple.keylayout.ABC"

local JIS_EISUU = 102  -- 空格左侧：英数 键
local JIS_KANA  = 104  -- 空格右侧：かな 键

-- 清理旧资源，防止重载内存泄漏
if JisKeyInterceptor then pcall(function() JisKeyInterceptor:stop() end) JisKeyInterceptor = nil end

local function secureInputEnabled()
    local ok, enabled = pcall(hs.eventtap.isSecureInputEnabled)
    return ok and enabled
end

-- 使用全局变量挂载，防止被 Lua GC 垃圾回收导致监听静默失效
_G.JisKeyInterceptor = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local keyCode = event:getKeyCode()
    if keyCode ~= JIS_KANA and keyCode ~= JIS_EISUU then
        return false
    end

    -- 忽略按键长按连发 (Autorepeat)
    local isRepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat)
    if isRepeat and isRepeat ~= 0 then
        return true
    end

    -- 密码框/终端 sudo 场景放行
    if secureInputEnabled() then
        return false
    end

    -- 1. 按下 Kana 键 -> 强制切换中文
    if keyCode == JIS_KANA then
        pcall(hs.keycodes.currentSourceID, CHINESE_ID)
        return true
    end

    -- 2. 按下 Eisuu 键 -> 强制切换英文
    if keyCode == JIS_EISUU then
        pcall(hs.keycodes.currentSourceID, ENGLISH_ID)
        return true
    end

    return false
end)

_G.JisKeyInterceptor:start()
