-- ==========================================================
-- Hammerspoon 配置主入口 (模块化管理)
-- ==========================================================

-- 外层全局异常捕获，确保任何 Lua 错误都能显式弹窗和写入日志
local globalOk, globalErr = pcall(function()
    
    -- 导入功能模块
    require("ime.ime")           -- 日式键盘单向无缝强切与防失焦自愈看门狗
    require("ime.doubao_return") -- 豆包全局语音浮窗关闭后恢复之前的输入法
    require("caffeine.caffeine") -- 防休眠 Toggle 菜单栏控制
    require("reload.reload")     -- 配置文件变动自动重载

end)

-- 异常守护输出
if not globalOk then
    local errLog = "Hammerspoon 加载错误: " .. tostring(globalErr)
    local f = io.open(os.getenv("HOME") .. "/.hammerspoon/hs_error.txt", "w")
    if f then
        f:write(errLog)
        f:close()
    end
    hs.alert.show(errLog, 8)
end
