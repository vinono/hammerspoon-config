-- ==========================================================
-- noTunes: 阻止 Music / iTunes 启动，可选打开替代应用
-- ==========================================================

local M = {}

-- 使用字符串事件，使核心逻辑不依赖 Hammerspoon。
function M.handleEvent(appName, eventType, app, replacement, launcher)
    if eventType ~= "launched" or (appName ~= "Music" and appName ~= "iTunes") or not app then
        return
    end

    app:kill()
    if replacement and replacement ~= "" and launcher then
        launcher(replacement)
    end
end

function M.stop()
    if NoTunesAppWatcher then
        NoTunesAppWatcher:stop()
        NoTunesAppWatcher = nil
    end
end

function M.start(replacementApp)
    M.stop()
    NoTunesAppWatcher = hs.application.watcher.new(function(appName, eventType, app)
        if eventType == hs.application.watcher.launched then
            M.handleEvent(appName, "launched", app, replacementApp, hs.application.launchOrFocus)
        end
    end)
    NoTunesAppWatcher:start()
    return NoTunesAppWatcher
end

return M
