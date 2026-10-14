-- ==========================================================
-- Hammerspoon 配置主入口 (模块化管理)
-- ==========================================================

local errorFile = os.getenv("HOME") .. "/.hammerspoon/hs_error.txt"

-- 停止并清理遗留的 JIS 拦截器资源（若存在）
if jisInputEventTap then pcall(function() jisInputEventTap:stop() end); jisInputEventTap = nil end
if jisInputWakeWatcher then pcall(function() jisInputWakeWatcher:stop() end); jisInputWakeWatcher = nil end

-- 外层全局异常捕获，确保任何 Lua 错误都能显式弹窗和写入日志
local globalOk, globalErr = pcall(function()
    require("hs.ipc")            -- 启用 CLI 命令行通信支持
    require("caffeine.caffeine") -- 防休眠 Toggle 菜单栏控制
    require("chrome.startup")    -- 登录启动时为 Chrome 注入 Gemini 地区参数
    require("reload.reload")     -- 配置文件变动自动重载
end)

-- 异常守护输出
if not globalOk then
    local errLog = "Hammerspoon 加载错误: " .. tostring(globalErr)
    local f = io.open(errorFile, "w")
    if f then
        f:write(errLog)
        f:close()
    end
    hs.alert.show(errLog, 8)
else
    -- 加载成功时清空旧的错误日志
    local f = io.open(errorFile, "w")
    if f then
        f:write("")
        f:close()
    end
end
