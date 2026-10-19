-- 隔离 Hammerspoon 系统边界，不修改当前运行中的 watcher。
local runtime, originalWatcher = hs, NoTunesAppWatcher
local results = {}
local ok, err = xpcall(function()
    local callbacks, watchers, launched = {}, {}, {}
    hs = { application = {
        watcher = { launched = 1, activated = 2, new = function(callback)
            callbacks[#callbacks + 1] = callback
            local watcher = { starts = 0, stops = 0 }
            function watcher:start() self.starts = self.starts + 1; return self end
            function watcher:stop() self.stops = self.stops + 1; return self end
            watchers[#watchers + 1] = watcher
            return watcher
        end },
        launchOrFocus = function(name) launched[#launched + 1] = name end,
    } }
    NoTunesAppWatcher = nil
    -- dofile 创建独立模块，避免污染运行中的 require 缓存。
    local path = (runtime and runtime.configdir or ".") .. "/notunes/notunes.lua"
    local notunes = dofile(path)
    local first = notunes.start("Spotify")
    assert(first == NoTunesAppWatcher and first.starts == 1, "start 应启动并全局保留 watcher")
    local kills = 0
    local app = { kill = function() kills = kills + 1 end }
    callbacks[1]("Music", 2, app)
    assert(kills == 0 and #launched == 0, "非 launched 数字事件应忽略")
    callbacks[1]("Music", 1, app)
    assert(kills == 1 and launched[1] == "Spotify", "应将 launched 映射到核心逻辑")
    local second = notunes.start()
    assert(first.stops == 1 and second.starts == 1, "重复 start 应停止旧 watcher")
    callbacks[2]("iTunes", 1, app)
    assert(kills == 2 and #launched == 1, "默认仅拦截，不启动替代应用")
    notunes.stop()
    assert(second.stops == 1 and NoTunesAppWatcher == nil, "stop 应停止并释放 watcher")
    notunes.stop()
    assert(second.stops == 1, "重复 stop 应安全")
    results[#results + 1] = "NOTUNES_WATCHER_TESTS_OK: 7 checks"
end, debug.traceback)
hs, NoTunesAppWatcher = runtime, originalWatcher
if not ok then error(err) end
print(table.concat(results, "\n"))
