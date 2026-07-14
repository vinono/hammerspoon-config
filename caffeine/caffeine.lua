-- ==========================================================
-- Caffeine: Mac 始终不休眠及菜单栏 Toggle
-- ==========================================================

-- 重置旧的资源，防止内存泄漏/重复监听
if JisSleepMenubar then 
    JisSleepMenubar:delete() 
    JisSleepMenubar = nil
end
if JisCaffeineSleepWatcher then
    JisCaffeineSleepWatcher:stop()
    JisCaffeineSleepWatcher = nil
end
if JisCaffeineScreenWatcher then
    JisCaffeineScreenWatcher:stop()
    JisCaffeineScreenWatcher = nil
end

local isSleepPrevented = hs.settings.get("caffeine_isSleepPrevented") or false
local sleepMenubar = nil

-- 加载原生单色模板图标，若系统不支持则降级使用 Emoji
local activeIcon = hs.image.imageFromName("cup.and.saucer.fill")
if activeIcon then
    activeIcon:template(true)
    activeIcon = activeIcon:size({w = 16, h = 16})
end

local inactiveIcon = hs.image.imageFromName("zzz")
if inactiveIcon then
    inactiveIcon:template(true)
    inactiveIcon = inactiveIcon:size({w = 16, h = 16})
end

-- 状态同步渲染函数
local function updateSleepDisplay()
    if isSleepPrevented then
        if activeIcon then
            sleepMenubar:setIcon(activeIcon)
        else
            sleepMenubar:setTitle("☕️")
        end
        sleepMenubar:setTooltip("Mac 防休眠已开启：保持屏幕与系统常亮")
        hs.caffeinate.set("displayIdle", true, true)
    else
        if inactiveIcon then
            sleepMenubar:setIcon(inactiveIcon)
        else
            sleepMenubar:setTitle("💤")
        end
        sleepMenubar:setTooltip("Mac 防休眠已关闭：遵循系统默认电源设置")
        hs.caffeinate.set("displayIdle", false, true)
    end
    hs.settings.set("caffeine_isSleepPrevented", isSleepPrevented)
end

-- 状态切换回调
local function toggleSleepPrevention()
    isSleepPrevented = not isSleepPrevented
    updateSleepDisplay()
end

-- 实例化菜单栏
JisSleepMenubar = hs.menubar.new()
if JisSleepMenubar then
    sleepMenubar = JisSleepMenubar
    if activeIcon and inactiveIcon then
        sleepMenubar:setTitle("")
    end
    sleepMenubar:setClickCallback(toggleSleepPrevention)
    updateSleepDisplay()
end

-- 监听系统休眠事件以检测合盖动作并重置状态
JisCaffeineSleepWatcher = hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.systemWillSleep then
        -- 当系统即将休眠时（如合盖），自动关闭防休眠，确保安全睡眠，防止在包里发热耗电
        if isSleepPrevented then
            isSleepPrevented = false
            updateSleepDisplay()
        end
    end
end)
if JisCaffeineSleepWatcher then
    JisCaffeineSleepWatcher:start()
end

-- 检测内置屏幕是否处于激活状态的辅助函数
local function hasBuiltInScreen()
    for _, screen in ipairs(hs.screen.allScreens()) do
        local name = screen:name():lower()
        if name:match("built%-in") or name:match("color lcd") or name:match("retina") then
            return true
        end
    end
    return false
end

-- 屏幕变化事件回调：用于捕获无外接显示器时的合盖动作
local function handleScreenChange()
    -- 如果内置屏幕断开（合盖），且当前没有接任何外接显示器（即活动屏幕数为 0），自动关闭防休眠允许 Mac 休眠
    if not hasBuiltInScreen() and #hs.screen.allScreens() == 0 then
        if isSleepPrevented then
            isSleepPrevented = false
            updateSleepDisplay()
        end
    end
end

-- 注册屏幕变化监听器，确保合盖能及时自愈
JisCaffeineScreenWatcher = hs.screen.watcher.new(handleScreenChange)
if JisCaffeineScreenWatcher then
    JisCaffeineScreenWatcher:start()
end
