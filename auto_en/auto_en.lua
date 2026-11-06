-- ==========================================================
-- 特定 App 激活时自动切换为英文输入法 (Auto English for Apps)
-- ==========================================================

local ENGLISH_SOURCE = "com.apple.keylayout.ABC"

-- 预设自动切英文的 App bundleID 清单 (精确匹配)
local targetBundleIDs = {
    -- 系统与第三方终端
    ["com.apple.Terminal"]             = true, -- macOS 原生终端
    ["com.googlecode.iterm2"]          = true, -- iTerm2
    ["dev.warp.Warp-Terminal"]         = true, -- Warp Terminal
    ["com.mitchellh.ghostty"]          = true, -- Ghostty
    ["io.alacritty"]                   = true, -- Alacritty
    ["net.kovidgoyal.kitty"]           = true, -- Kitty
    ["com.github.wez.wezterm"]         = true, -- WezTerm

    -- 开发工具 / IDE
    ["com.apple.dt.Xcode"]             = true, -- Xcode
    ["com.microsoft.VSCode"]           = true, -- VS Code
    ["com.google.antigravity-ide"]     = true, -- Antigravity IDE
    ["com.google.antigravity"]         = true, -- Antigravity
    ["com.torusknot.SourceTreeNotMAS"] = true, -- Sourcetree (Git客户端)
    ["dev.kdrag0n.MacVirt"]            = true, -- OrbStack (容器/Linux工具)
    ["com.jetbrains.intellij"]          = true, -- IntelliJ IDEA

    -- 设计与创意制作 (单字母快捷键密集，避免与中文候选框冲突)
    ["com.figma.Desktop"]              = true, -- Figma
    ["com.darlingo.Darkroom"]          = true, -- Darkroom

    -- 媒体播放器 (空格/单字母快捷键)
    ["com.colliderli.iina"]            = true, -- IINA

    -- 游戏类 (避免 WASD 移动键唤起中文拼音输入)
    ["org.prismlauncher.PrismLauncher"]= true, -- Prism Launcher (Minecraft)
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
    ["code"]                = true,
    ["visual studio code"]  = true,
    ["antigravity ide"]     = true,
    ["antigravity"]         = true,
    ["sourcetree"]          = true,
    ["orbstack"]            = true,
    ["figma"]               = true,
    ["darkroom"]            = true,
    ["iina"]                = true,
    ["prism launcher"]      = true,
}

-- 重置旧 watcher、filter 和 tap，防止配置重载时发生监听器泄漏
if AutoEnAppWatcher then
    pcall(function() AutoEnAppWatcher:stop() end)
    AutoEnAppWatcher = nil
end
if AutoEnLauncherFilter then
    pcall(function() AutoEnLauncherFilter:unsubscribeAll() end)
    AutoEnLauncherFilter = nil
end
if AutoEnHotkeyTap then
    pcall(function() AutoEnHotkeyTap:stop() end)
    AutoEnHotkeyTap = nil
end

local function switchToEnglish()
    if hs.keycodes.currentSourceID() ~= ENGLISH_SOURCE then
        hs.keycodes.currentSourceID(ENGLISH_SOURCE)
    end
    if hs.keycodes.currentLayout() ~= "ABC" then
        hs.keycodes.setLayout("ABC")
    end
end

-- 1. 常规应用激活监听（窗口切换、Dock 点击、Cmd+Tab）
local function onAppActivated(appName, eventType, app)
    if eventType ~= hs.application.watcher.activated then
        return
    end

    local bundleID = app and app:bundleID() or ""
    local name = (appName or (app and app:name()) or ""):lower()

    if targetBundleIDs[bundleID] or targetAppNames[name] then
        switchToEnglish()
        hs.timer.doAfter(0.05, switchToEnglish)
    end
end

AutoEnAppWatcher = hs.application.watcher.new(onAppActivated)
AutoEnAppWatcher:start()
