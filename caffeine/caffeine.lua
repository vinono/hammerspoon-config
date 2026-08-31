-- ==========================================================
-- Caffeine: Mac 防休眠菜单栏控制 (极简优雅版)
-- ==========================================================

-- 重置旧的资源，防止内存泄漏/重复挂载
if JisSleepMenubar then pcall(function() JisSleepMenubar:delete() end) JisSleepMenubar = nil end
if JisCaffeineSleepWatcher then pcall(function() JisCaffeineSleepWatcher:stop() end) JisCaffeineSleepWatcher = nil end
if JisCaffeineLidWatcher then pcall(function() JisCaffeineLidWatcher:stop() end) JisCaffeineLidWatcher = nil end

-- 重载时始终回到系统默认睡眠策略，避免忘记关闭防休眠后持续耗电。
local isSleepPrevented = false

-- 加载 assets/ 目录下的自定义图片 (active.png / inactive.png)，若无则降级为 Emoji
local function loadIcon(name)
    local path = os.getenv("HOME") .. "/.hammerspoon/caffeine/assets/" .. name
    local ok, img = pcall(hs.image.imageFromPath, path)
    if ok and img then
        return img:template(true):size({ w = 18, h = 18 })
    end
    return nil
end

local activeIcon   = loadIcon("active.png")
local inactiveIcon = loadIcon("inactive.png")

-- 更新菜单栏 UI 与系统防休眠状态
local function updateDisplay()
    -- 同时阻止系统与显示器的空闲休眠；第三个参数使策略在电源和电池下都生效。
    hs.caffeinate.set("systemIdle", isSleepPrevented, true)
    hs.caffeinate.set("displayIdle", isSleepPrevented, true)
    hs.settings.set("caffeine_isSleepPrevented", isSleepPrevented)

    if not _G.JisSleepMenubar then return end

    local icon = isSleepPrevented and activeIcon or inactiveIcon
    if icon then
        _G.JisSleepMenubar:setIcon(icon)
        _G.JisSleepMenubar:setTitle("")
    else
        _G.JisSleepMenubar:setIcon(nil)
        _G.JisSleepMenubar:setTitle(isSleepPrevented and "☕️" or "🌙")
    end

    local statusText = isSleepPrevented and "防休眠已开启：保持系统常亮 ☕️" or "防休眠已关闭：遵循系统电源规则 🌙"
    _G.JisSleepMenubar:setTooltip("Caffeine " .. statusText)

end

local function lidIsClosed()
    local output = hs.execute("/usr/sbin/ioreg -r -k AppleClamshellState -d 4")
    return output and output:match('"AppleClamshellState"%s*=%s*Yes') ~= nil
end

local function disableForLidClose()
    if not isSleepPrevented then return end
    isSleepPrevented = false
    updateDisplay()
    hs.alert.show("已合盖：恢复正常休眠")
end

-- 创建菜单栏项并挂载点击回调
_G.JisSleepMenubar = hs.menubar.new()
if _G.JisSleepMenubar then
    _G.JisSleepMenubar:setClickCallback(function()
        if lidIsClosed() then
            isSleepPrevented = false
            updateDisplay()
            hs.alert.show("合盖状态：保持正常休眠")
            return
        end
        isSleepPrevented = not isSleepPrevented
        updateDisplay()
    end)
    updateDisplay()
end

-- 系统休眠/合盖看门狗：系统准备睡眠时自动关闭防休眠，防止在电脑包内发热耗电。
_G.JisCaffeineSleepWatcher = hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.systemWillSleep then
        disableForLidClose()
    end
end)
if _G.JisCaffeineSleepWatcher then
    _G.JisCaffeineSleepWatcher:start()
end

-- 外接显示器合盖模式未必触发 systemWillSleep，轮询作为兜底保护。
_G.JisCaffeineLidWatcher = hs.timer.doEvery(1, function()
    if lidIsClosed() then
        disableForLidClose()
    end
end)
