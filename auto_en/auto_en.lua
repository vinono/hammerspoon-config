-- ==========================================================
-- 特定 App 激活时自动切换为英文输入法 (Auto English for Apps)
-- ==========================================================

local ENGLISH_SOURCE = "com.apple.keylayout.ABC"

-- 预设自动切英文的 App bundleID 清单 (精确匹配)
local targetBundleIDs = {
    -- 系统与第三方终端
    ["com.apple.Terminal"]         = true, -- macOS 原生终端
    ["com.googlecode.iterm2"]      = true, -- iTerm2
    ["dev.warp.Warp-Terminal"]     = true, -- Warp Terminal
    ["com.mitchellh.ghostty"]      = true, -- Ghostty
    ["io.alacritty"]               = true, -- Alacritty
    ["net.kovidgoyal.kitty"]       = true, -- Kitty
    ["com.github.wez.wezterm"]     = true, -- WezTerm

    -- 音视频 / 投屏 / 录制工具
    ["com.tinycast.app"]           = true, -- Tinycast

    -- 开发工具 / IDE
    ["com.apple.dt.Xcode"]         = true, -- Xcode
    ["com.microsoft.VSCode"]       = true, -- VS Code
    -- ["com.google.antigravity-ide"] = true, -- Antigravity IDE
    -- ["com.torusknot.SourceTreeNotMAS"] = true, -- Sourcetree (Git客户端)
    -- ["dev.kdrag0n.MacVirt"]        = true, -- OrbStack (容器/Linux工具)
    -- ["com.jetbrains.intellij"]  = true, -- IntelliJ IDEA

    -- 设计与快捷键密集型应用 (强烈推荐：避免单字母快捷键与中文输入法冲突)
    -- ["com.figma.Desktop"]          = true, -- Figma
}

-- 也支持通过应用显示名称模糊匹配 (小写比较)
local targetAppNames = {
    ["terminal"]            = true,
    ["iterm"]               = true,
    ["iterm2"]              = true,
    ["warp"]                = true,
    ["ghostty"]             = true,
    ["alacritty"]           = true,
    ["kitty"]               = true,
    ["wezterm"]             = true,
    ["xcode"]               = true,
    ["tinycast"]            = true,
    ["code"]                = true,
    ["visual studio code"]  = true,
    -- ["figma"]               = true,
    -- ["sourcetree"]          = true,
    -- ["orbstack"]            = true,
    -- ["antigravity ide"]     = true,
}

-- 重置旧 watcher，防止配置重载时发生监听器泄漏
if AutoEnAppWatcher then
    pcall(function() AutoEnAppWatcher:stop() end)
    AutoEnAppWatcher = nil
end

local function switchToEnglish()
    if hs.keycodes.currentSourceID() ~= ENGLISH_SOURCE then
        hs.keycodes.currentSourceID(ENGLISH_SOURCE)
    end
end

local function onAppActivated(appName, eventType, app)
    if eventType ~= hs.application.watcher.activated then
        return
    end

    local bundleID = app and app:bundleID() or ""
    local name = (appName or (app and app:name()) or ""):lower()

    if targetBundleIDs[bundleID] or targetAppNames[name] then
        -- 1. 立即执行一次强切
        switchToEnglish()
        -- 2. 延迟 50ms 再次确认（防止 macOS 窗口焦点过渡时恢复旧输入法导致被覆盖）
        hs.timer.doAfter(0.05, switchToEnglish)
    end
end

AutoEnAppWatcher = hs.application.watcher.new(onAppActivated)
AutoEnAppWatcher:start()

