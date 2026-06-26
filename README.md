# 🔨🥄 Hammerspoon Config

> **Make my Mac smarter. Make my typing flow.**
>
> 这是一个高度精炼、稳健且模块化的 Hammerspoon 配置项目。致力于解决 macOS 系统在日式键盘（JIS Layout）输入法切换时的痛点，并提供便捷的系统常亮控制（Caffeine）。

---

## 🚀 核心特性 (Features)

本项目采用模块化设计，每个功能都作为一个独立的子模块进行加载：

| 模块名称 | 功能说明 | 核心机制 | 状态栏反馈 |
| :--- | :--- | :--- | :---: |
| **`ime`** | **日式键盘零失焦强切** | 基于 Carbon API 底层单向切换输入法，移除了多余按键，完美规避文本框失焦。配备唤醒自愈看门狗。 | - |
| **`caffeine`** | **Caffeine 防休眠 Toggle** | 一键阻止/允许系统休眠与屏幕自动变暗。 | ☕️ / 💤 |
| **`reload`** | **配置自动热重载** | 监听配置文件变动，`.lua` 文件保存时瞬时完成 Reload。 | 🚀 气泡提示 |

---

## 📂 目录结构 (Structure)

本项目的目录结构非常清晰，参考了优秀开源项目的工程化管理：

```text
~/.hammerspoon/
├── init.lua              # 主入口：负责全局异常守护与模块加载
├── .gitignore            # Git 忽略配置
├── README.md             # 项目自述文档
├── ime/
│   └── ime.lua           # 输入法无缝强切与唤醒自愈看门狗逻辑
├── caffeine/
│   └── caffeine.lua      # 菜单栏防休眠与 Toggle 机制
└── reload/
    └── reload.lua        # 配置文件变动自动重载模块
```

---

## 🛠️ 安装与快速上手 (Installation & Usage)

### 1. 前置准备
确保您的 Mac 上已安装了 [Hammerspoon](https://www.hammerspoon.org/)。

### 2. 部署配置
备份您现有的配置目录（如有），然后将本项目克隆至本地：

```bash
# 备份旧配置
mv ~/.hammerspoon ~/.hammerspoon.bak

# 克隆当前仓库（将 YOUR_USERNAME 替换为您的 GitHub 用户名）
git clone https://github.com/vinono/hammerspoon-config.git ~/.hammerspoon
```

### 3. 运行与加载
- 打开或重启 **Hammerspoon**。
- 模块初始化成功后，系统会弹出通知：`Hammerspoon 配置重载成功 🚀`。
- 此时状态栏会出现 💤 图标，表示 Caffeine 防休眠处于就绪状态。

---

## ⚙️ 模块详解 (Deep Dive)

### 1. 日式键盘 (JIS Layout) 零失焦强切机制
在 macOS 系统中使用日式键盘（JIS 102/104 键位）时，按下空格左侧的 `英数 (Eisuu)` 和右侧的 `かな (Kana)` 切换输入法，在某些浏览器输入框或特定终端中可能会引起**光标失去焦点**的 Bug。
- **解决方案**：此配置基于 Carbon API 的 `currentSourceID` 实现纯单向强切机制，移除了可能导致失焦的 `Escape` 等辅助按键。
- **稳定性保障**：利用 `hs.caffeinate.watcher` 监听系统休眠唤醒（`systemDidWake`）和屏幕解锁（`screensDidUnlock`）事件。在唤醒后自动延迟 1 秒重新绑定，确保在系统输入法框架（TSM）就绪后 100% 恢复拦截工作，拒绝静默失效。

### 2. Caffeine 菜单栏防休眠
- **操作方式**：单击状态栏中的 💤 即可切换至 ☕️ 模式。
- **效果**：
  - ☕️ 模式：强行阻止系统进入 Idle 休眠并保持屏幕常亮（非常适合进行长编译、演示汇报或大文件下载）。
  - 💤 模式：恢复 macOS 系统默认的电源休眠规则。

### 3. 配置热更新
- **工作机制**：在 `reload` 模块中创建了 `hs.pathwatcher` 监控整个配置文件目录。只要在此目录下保存任何 `.lua` 文件，Hammerspoon 就会立即自动重新加载，大幅提升微调配置时的开发体验。

---

## 📄 开源协议 (License)

本项目基于 [MIT](LICENSE) 协议开源。
