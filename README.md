# 🔨🥄 Hammerspoon Config

> **Make my Mac smarter. Make my workflow flow.**
>
> 这是一个高度精炼、稳健且模块化的 Hammerspoon 配置项目。提供便捷的系统常亮控制（Caffeine）与 Chrome 启动优化等功能。

---

## 🚀 核心特性 (Features)

本项目采用模块化设计，每个功能都作为一个独立的子模块进行加载：

| 模块名称 | 功能说明 | 核心机制 | 状态栏反馈 |
| :--- | :--- | :--- | :---: |
| **`caffeine`** | **Caffeine 防休眠 Toggle** | 一键阻止/允许系统与屏幕空闲休眠；合盖状态智能感知，合盖时自动恢复正常睡眠策略。 | ☕️ / 🌙 |
| **`chrome`** | **Chrome 参数冷启动** | Hammerspoon 新进程启动时，在 Chrome 尚未运行的情况下使用美国地区参数启动一次；配置热重载不会重复打开 Chrome。 | - |
| **`auto_en`** | **特定 App 自动切英文** | 激活终端（Terminal/iTerm2/Warp/Ghostty等）及开发工具时自动将输入法切为 ABC 英文。 | 自动无感 |
| **`notunes`** | **阻止 Apple Music / iTunes 启动** | 监听应用启动并请求退出 Music / iTunes，可选打开 Spotify 等替代应用。 | 自动无感 |
| **`reload`** | **配置自动热重载** | 监听配置文件变动，`.lua` 文件保存时瞬时完成 Reload。 | 🚀 气泡提示 |

---

## 📂 目录结构 (Structure)

本项目的目录结构非常清晰，采用模块化工程管理：

```text
~/.hammerspoon/
├── init.lua              # 主入口：负责全局异常守护与模块加载
├── .gitignore            # Git 忽略配置
├── README.md             # 项目自述文档
├── auto_en/
│   └── auto_en.lua       # 终端等特定 App 激活时自动切英文输入法模块
├── caffeine/
│   ├── caffeine.lua      # 菜单栏防休眠与 Toggle 机制
│   └── assets/           # 菜单栏自定义模板图标资源 (active.png / inactive.png)
├── chrome/
│   └── startup.lua       # Hammerspoon 登录启动时带地区参数冷启动 Chrome
├── notunes/
│   ├── notunes.lua       # Music / iTunes 启动拦截与可选替代应用
│   ├── test_notunes.lua  # 纯逻辑单元测试（注入应用对象和启动回调）
│   └── test_watcher.lua  # watcher 生命周期与事件适配测试
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

# 克隆当前仓库
git clone https://github.com/vinono/hammerspoon-config.git ~/.hammerspoon
```

### 3. 运行与加载
- 打开或重启 **Hammerspoon**。
- 模块初始化成功后，系统会弹出通知：`Hammerspoon 配置重载成功 🚀`。
- 状态栏会出现 🌙 图标，表示 Caffeine 防休眠处于就绪状态。
- Hammerspoon 已开启“登录时启动”且 Chrome 尚未运行时，会使用 `--variations-override-country=us` 启动 Chrome。Chrome 已在运行时不会强制退出或重启，并会提示本次未重新应用参数。

---

## ⚙️ 模块详解 (Deep Dive)

### 1. Caffeine 菜单栏防休眠
- **操作方式**：单击状态栏中的 🌙 即可切换至 ☕️ 模式。
- **图标自定义**：
  - 默认降级使用 `☕️` 与 `🌙` Emoji。
  - 支持在 `caffeine/assets/` 目录中放置 36x36px 透明背景的纯黑 PNG 图片（`active.png` 与 `inactive.png`），自动开启 `template(true)` 适配 macOS 深色/浅色外观。
- **安全保障与合盖感知**：
  - 检测系统休眠/合盖事件，在准备休眠或合盖时自动关闭防休眠，防止电脑在背包中发热耗电。
  - 针对外接显示器合盖（Clamshell Mode）场景，通过 `ioreg` 底层状态轮询作为兜底保护，自动恢复正常休眠策略。

### 2. Chrome 冷启动参数优化
- **工作机制**：在登录启动时为 Chrome 提供指定的运行参数；重载或日常使用期间不会打扰正在运行的 Chrome。

### 3. 特定 App 自动切英文 (Auto English)
- **解决痛点**：在终端执行命令或写代码时，误处在中文输入法状态下会导致按键乱码或需要多次按回车。
- **支持应用**：
  - 终端工具：原生 Terminal、iTerm2、Warp、Ghostty、Alacritty、Kitty、WezTerm 等。
  - 开发工具：Xcode（支持在 `auto_en/auto_en.lua` 中快速取消注释或添加 VS Code、IntelliJ 等）。
- **抗焦点竞争机制**：macOS 切换窗口时会异步恢复窗口先前的输入法状态（约 20~50ms 延迟），本模块采用即时切换 + 50ms 延时二重校验策略，确保稳定切换为英文 ABC (`com.apple.keylayout.ABC`)。

### 4. 配置热更新
- **工作机制**：在 `reload` 模块中创建了 `hs.pathwatcher` 监控整个配置文件目录。只要在此目录下保存任何 `.lua` 文件，Hammerspoon 就会立即自动重新加载，大幅提升微调配置时的开发体验。

### 5. Apple Music / iTunes 启动拦截 (noTunes)
- **工作机制**：通过 `hs.application.watcher` 监听 `launched` 事件，对 `Music`、`iTunes` 调用 `app:kill()` 请求退出；Safari 等其他应用及激活、退出事件不受影响。这是在应用启动后立即退出，因此可能短暂看到窗口。
- **默认配置**：`init.lua` 中启用拦截，替代应用默认为 `nil`。Hammerspoon 需要保持运行；启用前已经运行的 Music 不会主动关闭。
- **替代应用**：修改 `init.lua` 中对应的一行，保存后自动重载。替代应用须已安装，不能配置为被拦截的 Music 或 iTunes。

```lua
require("notunes.notunes").start(nil)       -- 仅拦截（默认）
-- 或改为：
require("notunes.notunes").start("Spotify") -- 拦截后打开/聚焦 Spotify
```

- **生命周期**：全局变量 `NoTunesAppWatcher` 保留 watcher 引用，避免被 GC 回收；重复 `start()` 会先停止旧 watcher。可在 Hammerspoon Console 中运行 `require("notunes.notunes").stop()` 临时停用，下一次配置重载会重新启用。
- **单元测试**：在仓库根目录执行以下命令，无需启动 Music 或 Spotify。核心测试临时隐藏 `hs`，通过 Mock 应用对象和 launcher 验证行为；watcher 测试使用独立 Mock，不影响当前监听器。

```bash
cd ~/.hammerspoon
hs -c 'dofile(hs.configdir .. "/notunes/test_notunes.lua"); dofile(hs.configdir .. "/notunes/test_watcher.lua")'
# 若安装了独立 Lua，也可执行：
lua notunes/test_notunes.lua
lua notunes/test_watcher.lua
```

- **真机验证**：启用后执行 `open -a "Music"`，等待 2 秒，再执行 `pgrep -x "Music"`；无输出且退出码为 1 表示 Music 已退出。

---

## 📄 开源协议 (License)

本项目基于 [MIT](LICENSE) 协议开源。
