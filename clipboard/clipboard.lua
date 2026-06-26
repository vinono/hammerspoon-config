-- ==========================================================
-- Clipboard: 剪贴板历史管理器 (顶部状态栏显示)
-- ==========================================================

-- 重置旧的资源，防止内存泄漏
if JClipboardMenubar then
    JClipboardMenubar:delete()
    JClipboardMenubar = nil
end
if JClipboardWatcher then
    JClipboardWatcher:stop()
    JClipboardWatcher = nil
end

local clipboardHistory = {}
local maxHistory = 30
local maxDisplayChars = 50
local ignoreNextChange = false

-- 1. 从 hs.settings 加载持久化数据
local savedHistory = hs.settings.get("clipboardHistory")
if type(savedHistory) == "table" then
    -- 过滤出非空字符串
    for _, val in ipairs(savedHistory) do
        if type(val) == "string" and string.len(val) > 0 then
            table.insert(clipboardHistory, val)
        end
    end
end

-- 保存历史记录到 hs.settings
local function saveHistory()
    hs.settings.set("clipboardHistory", clipboardHistory)
end

-- 2. UTF-8 安全截断函数，并用 " ↵ " 替换换行符
local function formatHistoryTitle(text)
    -- 替换换行符为符号，使菜单栏只显示单行
    local cleanText = text:gsub("\r\n", " ↵ "):gsub("\n", " ↵ "):gsub("\r", " ↵ ")
    
    -- 借助 Lua 5.3+ 内置 utf8 库进行安全截断，防止中文字符半截导致乱码
    local charCount = 0
    local hasUtf8, _ = pcall(function()
        for _, _ in utf8.codes(cleanText) do
            charCount = charCount + 1
        end
    end)

    if not hasUtf8 then
        -- 降级为普通字节数截断
        if string.len(cleanText) > maxDisplayChars then
            return string.sub(cleanText, 1, maxDisplayChars) .. "..."
        end
        return cleanText
    end

    if charCount <= maxDisplayChars then
        return cleanText
    end

    -- 获取第 maxDisplayChars + 1 个字符的字节偏移
    local offset = utf8.offset(cleanText, maxDisplayChars + 1)
    if offset then
        return string.sub(cleanText, 1, offset - 1) .. "..."
    end
    return string.sub(cleanText, 1, maxDisplayChars) .. "..."
end

-- 3. 将新内容推入历史记录队列
local function pushToHistory(item)
    -- 移除可能已经存在的重复条目
    for i, val in ipairs(clipboardHistory) do
        if val == item then
            table.remove(clipboardHistory, i)
            break
        end
    end

    -- 插入到最前
    table.insert(clipboardHistory, 1, item)

    -- 限制最大保存数量
    if #clipboardHistory > maxHistory then
        table.remove(clipboardHistory, #clipboardHistory)
    end

    saveHistory()
end

-- 4. 剪贴板变更处理回调 (代替轮询，接收底层传来的 content)
local function handleClipboardChange(content)
    if ignoreNextChange then
        ignoreNextChange = false
        return
    end

    -- 性能优化过滤：仅处理 100KB 以下的文本，防止巨大文本写入持久化时引起磁盘 I/O 阻塞或高内存占用
    if content and string.len(content) > 0 and string.len(content) < 102400 then
        pushToHistory(content)
    end
end

-- 5. 动态构建下拉菜单
local function buildMenu()
    local menu = {}

    if #clipboardHistory == 0 then
        table.insert(menu, { title = "暂无剪贴板历史", disabled = true })
    else
        for i, item in ipairs(clipboardHistory) do
            local displayTitle = formatHistoryTitle(item)
            table.insert(menu, {
                title = string.format("%d. %s", i, displayTitle),
                fn = function()
                    -- 点击复制回剪贴板
                    ignoreNextChange = true
                    hs.pasteboard.setContents(item)
                    hs.alert.show("已复制到剪贴板 ✅", 1.5)
                end
            })
        end
    end

    -- 添加分割线
    table.insert(menu, { title = "-" })

    -- 清空历史选项
    table.insert(menu, {
        title = "🗑️ 清空历史",
        disabled = (#clipboardHistory == 0),
        fn = function()
            clipboardHistory = {}
            saveHistory()
            hs.alert.show("剪贴板历史已清空 🗑️", 1.5)
        end
    })

    return menu
end

-- 6. 初始化状态栏及事件监听器
JClipboardMenubar = hs.menubar.new()
if JClipboardMenubar then
    -- 优先使用系统“复制”图标，次优使用“列表”图标，若不支持则 fallback 到 emoji 字符
    local icon = hs.image.imageFromName("NSTouchBarCopyTemplate") 
              or hs.image.imageFromName("NSListViewTemplate")
    
    if icon then
        icon:template(true)
        icon = icon:size({w = 16, h = 16}) -- 缩放到菜单栏标准 16x16 尺寸
        JClipboardMenubar:setIcon(icon)
    else
        JClipboardMenubar:setTitle("📋")
    end
    
    JClipboardMenubar:setTooltip("剪贴板历史记录")
    JClipboardMenubar:setMenu(buildMenu)
end

-- 启动剪贴板事件监听器 (底层高效 0.25s 轮询，Lua 层面纯事件响应)
JClipboardWatcher = hs.pasteboard.watcher.new(handleClipboardChange)
if JClipboardWatcher then
    JClipboardWatcher:start()
end

-- 导出测试 API，用于自动化验证
JClipboardTestAPI = {
    getHistory = function() return clipboardHistory end,
    setHistory = function(h) clipboardHistory = h; saveHistory() end,
    formatHistoryTitle = formatHistoryTitle,
    handleClipboardChange = handleClipboardChange,
    pushToHistory = pushToHistory,
    buildMenu = buildMenu
}
