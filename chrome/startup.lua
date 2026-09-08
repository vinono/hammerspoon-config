-- ==========================================================
-- Chrome: Hammerspoon 启动时用 Gemini 地区参数冷启动 Chrome
-- ==========================================================

local chromeApp = "/Applications/Google Chrome.app"
local chromeBundleID = "com.google.Chrome"
local launchArguments = {
  "-na",
  chromeApp,
  "--args",
  "--variations-override-country=us",
}

-- hs.reload() 会重新执行 init.lua，但不会重启 Hammerspoon 进程。
-- 保存当前进程 ID，确保一次 Hammerspoon 启动只处理一次 Chrome。
local markerKey = "chrome_startup_hammerspoon_pid"
local currentHammerspoonPID = hs.processInfo.processID

if hs.settings.get(markerKey) == currentHammerspoonPID then
  print("[Chrome Startup] 本次 Hammerspoon 启动已经处理过，跳过")
  return
end
hs.settings.set(markerKey, currentHammerspoonPID)

if hs.fs.attributes(chromeApp, "mode") ~= "directory" then
  hs.alert.show("未找到 Google Chrome，无法使用 Gemini 地区参数启动", 6)
  return
end

local runningChromeApps = hs.application.applicationsForBundleID(chromeBundleID) or {}
if #runningChromeApps > 0 then
  print("[Chrome Startup] Chrome 已在运行，保留现有会话并跳过启动参数")
  hs.alert.show("Chrome 已在运行，未重新应用 Gemini 地区参数", 5)
  return
end

_G.ChromeStartupTask = hs.task.new("/usr/bin/open", function(exitCode, _, standardError)
  if exitCode == 0 then
    print("[Chrome Startup] 已使用 --variations-override-country=us 启动 Chrome")
    hs.alert.show("已使用 Gemini 地区参数启动 Chrome", 5)
  else
    local detail = standardError
    if not detail or detail == "" then
      detail = "退出码 " .. tostring(exitCode)
    end
    hs.alert.show("Chrome 参数启动失败：" .. detail, 8)
  end
  _G.ChromeStartupTask = nil
end, launchArguments)

if not _G.ChromeStartupTask or not _G.ChromeStartupTask:start() then
  _G.ChromeStartupTask = nil
  hs.alert.show("无法创建 Chrome 参数启动任务", 8)
end
