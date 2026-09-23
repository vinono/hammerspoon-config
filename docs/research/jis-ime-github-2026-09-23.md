# JIS Kana / Eisuu 输入法切换：GitHub 源码调查

调查日期：2026-09-23。目标症状：Chrome 输入框已有焦点，Kana 偶发无效；Eisuu → Kana 后光标旁显示中文，但实际仍输入英文。

本次只读取上游代码、issue 和本机配置，未修改或重载运行中的输入法配置，未执行上游代码。以下是证据和候选实验，不是修复验收。

## 结论

优先验证“直接调用输入源选择 API”与“发送 macOS 系统输入源切换快捷键”的差异。官方 issue 有高度相似症状；Karabiner 当前文档仍明确推荐 CJKV 输入法使用系统切换快捷键。不能把 `currentSourceID(...) == true`、输入源 ID 正确或角标正确作为中文输入生效的证明。

## 1. Hammerspoon 官方 issue：图标变化，但仍只能输入英文

[Hammerspoon #1429](https://github.com/Hammerspoon/hammerspoon/issues/1429) 的原报告描述：中文输入源被选中，图标变化，但只能输入英文；Firefox 输入框失焦再聚焦能恢复。

- [报告者确认改用 setMethod / setLayout 仍失败，并提及 Chrome](https://github.com/Hammerspoon/hammerspoon/issues/1429#issuecomment-302046001)。
- [报告者确认 currentSourceID 返回 true 时仍无法正常输入](https://github.com/Hammerspoon/hammerspoon/issues/1429#issuecomment-302069888)。
- [2025 年评论仍报告 macOS 15.3.2 / Safari 存在问题](https://github.com/Hammerspoon/hammerspoon/issues/1429#issuecomment-2833333659)。

这些是社区实测报告，支持症状具有先例；不能证明本机故障必然同因。报告提到的是菜单栏图标，而本次用户看到的是光标旁提示，两种 UI 不能直接等同。

## 2. 官方源码：成功返回值只来自 TISSelectInputSource

[Hammerspoon libkeycodes.m，固定版本](https://github.com/Hammerspoon/hammerspoon/blob/23e387e2805a9890066366e0ac96c71b27f0cfd5/extensions/keycodes/libkeycodes.m#L334-L368)：

```objc
found = (TISSelectInputSource((TISInputSourceRef)CFArrayGetValueAtIndex(sources, 0)) == noErr);
```

`currentSourceID` setter 的布尔值来自 API 状态，没有检查 Chrome 当前输入框是否进入拼音组合输入。该文件中的 `setLayout` 和 `setMethod` 也调用 `TISSelectInputSource`，因此仅更换这几个 Hammerspoon API 没有绕过底层路径。

同一源码还显式定义 `eisu` / `kana` 的 JIS 键码映射；这与电脑控制工具是否支持这些键名是不同的问题。

## 3. Karabiner 官方建议：CJKV 走系统快捷键

[当前官方文档](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/select-input-source/) 与其 [GitHub 固定版本](https://github.com/pqrs-org/pqrs.org/blob/50ef8cb1db71bff88c0c49b97e7587055b942d80/sites/karabiner-elements/content/en/docs/json/complex-modifications-manipulator-definition/to/select-input-source/index.md) 明确提醒：带有 `input_mode_id` 的中日韩越输入源可能因 macOS 问题切换失败，建议发送系统输入源切换快捷键，例如 Control+Space。

[Karabiner 作者的原始说明](https://github.com/tekezo/Karabiner/issues/308#issuecomment-190693550) 建议先选目标前一个输入源，再发送“选择输入法菜单中的下一个输入源”的快捷键。

[历史实现说明，version_10.15.0](https://github.com/tekezo/Karabiner/blob/version_10.15.0/src/core/server/Resources/vkchangeinputsourcedef.xml#L210-L236) 具体描述“指示器变化，但输入行为没变”，示例先选择英文，等待 100 ms，再通过系统快捷键进入日文。

限制：历史示例针对日文，快捷键和等待时长不能直接照抄。应核实本机实际快捷键、输入源顺序，实测切换耗时及中文组合输入。它不是所有 macOS 版本上的保证。

## 4. GitHub JIS 配置实例

### ivancation/hammerspoon-config：本机已沿用的逻辑

[init.lua，固定版本 599774d](https://github.com/ivancation/hammerspoon-config/blob/599774d7a180e3521dfb5b2c29f4f1c9c102502e/init.lua)：

- 102 → ABC；104 → 苹果简体拼音。
- 成对处理 keyDown / keyUp，连发继承消费状态。
- 已是拼音时，Kana 原样放行，注释声称可退出拼音内部英文模式。
- 其他输入源时调用 `currentSourceID(chineseSource)`。

本地 `ime/ime.lua` 已使用同样结构。源码中的注释没有提供独立验证、实际组合输入检查或同源失效恢复；重新复制此仓库不能解决缺少验证的问题。

### mega-Meta/macos-jis-hammerspoon：浏览器走系统快捷键

[init.lua，固定版本 bd46cca](https://github.com/mega-Meta/macos-jis-hammerspoon/blob/bd46cca705db1bea421dcd38a7be4c625ed6d9cf/init.lua)；[README](https://github.com/mega-Meta/macos-jis-hammerspoon/blob/bd46cca705db1bea421dcd38a7be4c625ed6d9cf/README.md)。

- 102 → ABC；104 → 仓颉。
- Safari 中目标输入源与当前不同，则发送 `hs.eventtap.keyStroke({"ctrl"}, "space", 10000)`；其他应用仍直接选择 source ID。
- 系统切换有 0.15 秒冷却，Kana 单击延迟 0.3 秒以检测双击；双击调用系统切换。
- 作者说明用于 Safari 中文字根散落问题，要求系统快捷键匹配。

可借鉴的是系统快捷键路径。不能整份照搬：它针对 Safari / 仓颉，而本次是 Chrome / 拼音；同 source 仍跳过，不能直接处理用户的同源失效；还带有截图、剪贴板和应用自动切换等无关逻辑。多输入源时，简单切换不保证选中指定语言。

搜索范围：GitHub 仓库元数据搜索 `hammerspoon jis` 返回上述两项，`hammerspoon eisuu` 无结果；这不是全 GitHub 已认证代码搜索，不能声称只有这两种实现。

## 5. 本机只读对照

本地 `ime/ime.lua:75-85`：已是拼音时放行 Kana；否则调用 `currentSourceID`。Eisuu 直接选择 ABC。

2026-09-23 读取磁盘偏好文件：

- `AppleEnabledInputSources` 列出 ABC、简体拼音及其输入法父条目，另有非键盘输入服务。
- `AppleSymbolicHotKeys` 的 60 / 61 都启用，分别保存 Control+Space / Control+Option+Space。

这是磁盘配置证据，尚需在实际会话中确认快捷键生效及轮转顺序，不能当作真实输入测试结果。

本地 README 将“放行 Kana 会退出拼音内部英文模式”“彻底杜绝 EventTap 假死”写成确定保证；本次研究不支持这些无条件保证，应在后续修复和验收时同步收敛文案。

## 6. 下一步实验建议（尚未实施）

1. 保留现有配置作为 A 组；B 组只更换进入拼音的路径，不同时更换输入法或安装其他工具。
2. 在独立 Chrome 测试框比较：直接 source ID 选择；配置中的系统切换快捷键；先选 ABC 再用系统快捷键进入拼音。
3. 覆盖当前为 ABC、当前 ID 已是拼音但实际英文、已有焦点、切换输入框、快速连按、正在组词、不同按键间隔等情况。
4. 验收同时记录 JIS 事件、输入源变化、网页 `compositionstart/update/end` 和 `nihao` + 空格的最终中文结果。任何一层正常都不能代替完整验证。
5. 候选修复应维持 Eisuu / Kana 的单向语义；处理异步切换取消、焦点变化和已有组合输入。不要把 Kana 无条件改为 Control+Space，否则正常中文状态可能被切回英文。

本次交付为研究结论。未证明系统快捷键方案已修复本机问题。
