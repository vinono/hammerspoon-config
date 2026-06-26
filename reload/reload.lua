-- ==========================================================
-- Reload: 配置文件变动自动重载
-- ==========================================================

local function reloadConfig(files)
    local doReload = false
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
            break
        end
    end
    if doReload then
        hs.reload()
    end
end

-- 全局变量防止 GC 回收
if ConfigPathWatcher then 
    ConfigPathWatcher:stop() 
    ConfigPathWatcher = nil
end
ConfigPathWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
ConfigPathWatcher:start()

hs.alert.show("Hammerspoon 配置重载成功 🚀")
