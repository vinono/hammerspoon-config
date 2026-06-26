-- ==========================================================
-- 日式键盘 (JIS) 输入法防失效切换 (终极稳健+零失焦版)
-- ==========================================================

-- 💡 正确的 macOS 系统级输入源 ID (经 defaults read HIToolbox 验证 100% 精确)
local CHINESE_ID = "com.apple.inputmethod.SCIM.ITABC"  -- 简体拼音
local ENGLISH_ID = "com.apple.keylayout.ABC"           -- 英文 ABC

local JIS_EISUU = 102 -- 空格左侧：英数
local JIS_KANA  = 104 -- 空格右侧：かな

-- 重置旧的资源，防止内存泄漏
if JisKeyInterceptor then 
    JisKeyInterceptor:stop() 
    JisKeyInterceptor = nil
end
if JisSystemWatcher then 
    JisSystemWatcher:stop() 
    JisSystemWatcher = nil
end

-- 核心初始化函数
local function initJisInterceptor()
    if JisKeyInterceptor then 
        JisKeyInterceptor:stop() 
        JisKeyInterceptor = nil
    end

    -- 全局变量防回收
    JisKeyInterceptor = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local keyCode = event:getKeyCode()
        
        -- 1. 按下右侧 Kana 键 -> 切中文
        if keyCode == JIS_KANA then
            local ok, currentID = pcall(hs.keycodes.currentSourceID)
            if not ok then currentID = "" end

            -- 💡 纯单向强切，不发出 any 多余按键，确保 0% 失去焦点
            if currentID ~= CHINESE_ID then
                pcall(hs.keycodes.currentSourceID, CHINESE_ID)
            end
            return true -- 瞬间拦截
        end
        
        -- 2. 按下左侧 Eisuu 键 -> 切英文
        if keyCode == JIS_EISUU then
            local ok, currentID = pcall(hs.keycodes.currentSourceID)
            if not ok then currentID = "" end

            -- 💡 纯单向强切，移除了导致文本框失焦的 Escape 按键发送，保障文本框光标的绝对连贯性
            if currentID ~= ENGLISH_ID then
                pcall(hs.keycodes.currentSourceID, ENGLISH_ID)
            end
            return true -- 瞬间拦截
        end
        
        return false -- 其他物理按键正常放行
    end)

    JisKeyInterceptor:start()
end

-- ==========================================================
-- 核心看门狗：唤醒自愈与解锁重建
-- ==========================================================
JisSystemWatcher = hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.systemDidWake or 
       eventType == hs.caffeinate.watcher.screensDidUnlock then
        hs.timer.doAfter(1.0, function() -- 延迟 1s 等待系统 TSM 服务完全就绪
            initJisInterceptor()
        end)
    end
end)
JisSystemWatcher:start()

-- 初始启动监听
initJisInterceptor()
