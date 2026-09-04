-- ==========================================================
-- 日式键盘 (JIS) 输入法切换 (沿用 ivancation 成对按键精准拦截方案)
-- ==========================================================

local englishSource = "com.apple.keylayout.ABC"
local chineseSource = "com.apple.inputmethod.SCIM.ITABC"
local jisEisuu = 102
local jisKana = 104

-- 重置旧资源，防止热重载内存泄漏
if jisInputEventTap then pcall(function() jisInputEventTap:stop() end) end
if jisInputWakeWatcher then pcall(function() jisInputWakeWatcher:stop() end) end

-- 1. 检查输入法是否在系统已启用列表中
local function sourceIsEnabled(sourceID)
  for _, id in ipairs(hs.keycodes.layouts(true) or {}) do
    if id == sourceID then return true end
  end
  for _, id in ipairs(hs.keycodes.methods(true) or {}) do
    if id == sourceID then return true end
  end
  return false
end

local missingSources = {}
if not sourceIsEnabled(englishSource) then table.insert(missingSources, "ABC 英文") end
if not sourceIsEnabled(chineseSource) then table.insert(missingSources, "简体拼音") end
if #missingSources > 0 then
  hs.alert.show("未启用输入法：" .. table.concat(missingSources, "、"), 6)
end

-- 2. 追踪被消费的按键：KeyDown 被拦截消费时，其配对的 KeyUp 也会被消费
-- 当处于中文模式下按 Kana 时，放行两个事件给 macOS，触发系统退出拼音内部英文模式
local consumedJisKeys = {}

jisInputEventTap = hs.eventtap.new({
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.keyUp,
  hs.eventtap.event.types.tapDisabledByTimeout,
  hs.eventtap.event.types.tapDisabledByUserInput,
}, function(event)
  local eventType = event:getType()

  -- Quartz 超时或被临时禁用时，原地重新拉起
  if eventType == hs.eventtap.event.types.tapDisabledByTimeout or
     eventType == hs.eventtap.event.types.tapDisabledByUserInput then
    if jisInputEventTap then jisInputEventTap:start() end
    return false
  end

  local keyCode = event:getKeyCode()
  if keyCode ~= jisEisuu and keyCode ~= jisKana then return false end

  -- 安全输入场景放行并重置状态
  if hs.eventtap.isSecureInputEnabled() then
    consumedJisKeys[keyCode] = nil
    return false
  end

  -- KeyUp 对称处理
  if eventType == hs.eventtap.event.types.keyUp then
    local shouldConsume = consumedJisKeys[keyCode] == true
    consumedJisKeys[keyCode] = nil
    return shouldConsume
  end

  -- 连发按键处理：继承首击的放行/拦截策略
  local isRepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat)
  if isRepeat and isRepeat ~= 0 then
    return consumedJisKeys[keyCode] == true
  end

  local currentSource = hs.keycodes.currentSourceID() or ""

  -- Kana 键 -> 切中文
  if keyCode == jisKana then
    if currentSource == chineseSource then
      consumedJisKeys[keyCode] = nil
      return false -- 放行，让系统原生按键重置拼音内部英文模式
    end
    consumedJisKeys[keyCode] = true
    if not hs.keycodes.currentSourceID(chineseSource) then
      hs.alert.show("无法切换到简体拼音")
    end
    return true
  end

  -- Eisuu 键 -> 切英文
  consumedJisKeys[keyCode] = true
  if currentSource ~= englishSource and
     not hs.keycodes.currentSourceID(englishSource) then
    hs.alert.show("无法切换到 ABC 英文")
  end
  return true
end)

jisInputEventTap:start()

-- 3. 系统唤醒、锁屏解锁自愈看门狗
jisInputWakeWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake or
     event == hs.caffeinate.watcher.screensDidUnlock or
     event == hs.caffeinate.watcher.sessionDidBecomeActive then
    consumedJisKeys = {}
    if jisInputEventTap then
      jisInputEventTap:stop()
      jisInputEventTap:start()
    end
  end
end)
jisInputWakeWatcher:start()
