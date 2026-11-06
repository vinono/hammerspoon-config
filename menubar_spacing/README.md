# 菜单栏间距能力诊断

此模块仅返回能力报告，不修改偏好、不创建图标、不安装监听器，不接入 init.lua。
截至本次调查，Hammerspoon 公开 hs.menubar 接口没有全局图标间距控制方法。
`diagnose` 的 supported=false 表示没有经过验证的受支持实现，并非断言系统绝无其他方法。
不把 defaults 读写成功当作视觉生效，也不使用私有 API。

仓库根目录运行：

```sh
lua menubar_spacing/test_spacing.lua
# Hammerspoon CLI 可正常连接时：
hs -c 'print(require("menubar_spacing.spacing").diagnose(hs.host.operatingSystemVersion()).reason)'
```

本机调查：macOS 27.2 (26B123)；currentHost 的 NSStatusItemSpacing 和
NSStatusItemSelectionPadding 均为 8；全局 NSStatusItemSpacing 为 8，
全局 NSStatusItemSelectionPadding 未设置。未改动这些值。
CLI 通信进程以退出码 133 结束，无法确认运行中的配置、取得图标位置或验证实际间距。
纯 Lua 测试通过不代表菜单栏视觉效果通过。

回滚：移除此 menubar_spacing 目录即可；没有系统偏好需要恢复。
