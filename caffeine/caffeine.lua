-- ==========================================================
-- Caffeine: Mac 防休眠菜单栏控制 (极简优雅版)
-- ==========================================================

-- 重置旧的资源，防止内存泄漏/重复挂载
if JisSleepMenubar then pcall(function() JisSleepMenubar:delete() end) JisSleepMenubar = nil end
if JisCaffeineSleepWatcher then pcall(function() JisCaffeineSleepWatcher:stop() end) JisCaffeineSleepWatcher = nil end

local isSleepPrevented = hs.settings.get("caffeine_isSleepPrevented") or false

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

    hs.caffeinate.set("displayIdle", isSleepPrevented, true)
    hs.settings.set("caffeine_isSleepPrevented", isSleepPrevented)
end

-- 创建菜单栏项并挂载点击回调
_G.JisSleepMenubar = hs.menubar.new()
if _G.JisSleepMenubar then
    _G.JisSleepMenubar:setClickCallback(function()
        isSleepPrevented = not isSleepPrevented
        updateDisplay()
    end)
    updateDisplay()
end

-- 系统休眠/合盖看门狗：系统准备睡眠时自动关闭防休眠，防止在电脑包内发热耗电
_G.JisCaffeineSleepWatcher = hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.systemWillSleep then
        if isSleepPrevented then
            isSleepPrevented = false
            updateDisplay()
        end
    end
end)
if _G.JisCaffeineSleepWatcher then
    _G.JisCaffeineSleepWatcher:start()
end
