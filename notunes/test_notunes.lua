-- 可用 lua notunes/test_notunes.lua 或通过 hs CLI 运行。
local runtime = hs
local results = {}
hs = nil

local ok, err = xpcall(function()
    package.loaded["notunes.notunes"] = nil
    local notunes = require("notunes.notunes")
    local passed = 0

    local function check(name, appName, eventType, replacement, expectedKills, expectedLaunches)
        local kills, launches = 0, 0
        local app = { kill = function(self)
            assert(self ~= nil, "kill 必须收到应用对象")
            kills = kills + 1
        end }
        notunes.handleEvent(appName, eventType, app, replacement, function(target)
            assert(kills == 1, "应先终止 Apple Music，再启动替代应用")
            assert(target == "Spotify", "应启动配置的替代应用")
            launches = launches + 1
        end)
        assert(kills == expectedKills, name .. ": kill 次数不符")
        assert(launches == expectedLaunches, name .. ": launcher 次数不符")
        passed = passed + 1
        results[#results + 1] = "PASS: " .. name
    end

    check("Music 启动时终止并打开 Spotify", "Music", "launched", "Spotify", 1, 1)
    check("iTunes 启动时终止并打开 Spotify", "iTunes", "launched", "Spotify", 1, 1)
    check("未配置替代应用时仅终止 Music", "Music", "launched", nil, 1, 0)
    check("Safari 启动不拦截", "Safari", "launched", "Spotify", 0, 0)
    check("Music 激活事件不拦截", "Music", "activated", "Spotify", 0, 0)
    check("iTunes 退出事件不拦截", "iTunes", "terminated", "Spotify", 0, 0)
    check("空替代应用不启动", "Music", "launched", "", 1, 0)
    notunes.handleEvent("Music", "launched", nil, "Spotify", function()
        error("应用对象缺失时不应启动替代应用")
    end)
    passed = passed + 1
    results[#results + 1] = string.format("NOTUNES_TESTS_OK: %d tests", passed)
end, debug.traceback)

hs = runtime
if not ok then error(err) end
print(table.concat(results, "\n"))
