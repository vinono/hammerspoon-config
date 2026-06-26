-- ==========================================================
-- Caffeine: Mac 始终不休眠及菜单栏 Toggle
-- ==========================================================

-- 重置旧的资源，防止内存泄漏
if JisSleepMenubar then 
    JisSleepMenubar:delete() 
    JisSleepMenubar = nil
end

local isSleepPrevented = false
local sleepMenubar = nil

-- 状态同步渲染函数
local function updateSleepDisplay()
    if isSleepPrevented then
        sleepMenubar:setTitle("☕️")
        sleepMenubar:setTooltip("Mac 防休眠已开启：保持屏幕与系统常亮")
        hs.caffeinate.set("displayIdle", true, true)
    else
        sleepMenubar:setTitle("💤")
        sleepMenubar:setTooltip("Mac 防休眠已关闭：遵循系统默认电源设置")
        hs.caffeinate.set("displayIdle", false, true)
    end
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
    sleepMenubar:setClickCallback(toggleSleepPrevention)
    updateSleepDisplay()
end
