# 🔨🥄 Hammerspoon Config

> **Make my Mac smarter. Make my typing flow.**
>
> 这是一个高度精炼、稳健且模块化的 Hammerspoon 配置项目。致力于解决 macOS 系统在日式键盘（JIS Layout）输入法切换时的痛点，并提供便捷的系统常亮控制（Caffeine）。

---

## 🚀 核心特性 (Features)

本项目采用模块化设计，每个功能都作为一个独立的子模块进行加载：

| 模块名称 | 功能说明 | 核心机制 | 状态栏反馈 |
| :--- | :--- | :--- | :---: |
| **`ime`** | **日式键盘成对精准强切** | 基于 KeyDown/KeyUp 成对拦截状态机，100% 解决跨应用孤立按键泄露；智能穿透自愈拼音内部英文模式；自动自愈 Quartz 超时与系统唤醒。 | - |
| **`caffeine`** | **Caffeine 防休眠 Toggle** | 一键阻止/允许系统与屏幕空闲休眠；合盖状态智能感知，合盖时自动恢复正常睡眠策略。 | ☕️ / 🌙 |
| **`reload`** | **配置自动热重载** | 监听配置文件变动，`.lua` 文件保存时瞬时完成 Reload。 | 🚀 气泡提示 |

---

## 📂 目录结构 (Structure)

本项目的目录结构非常清晰，采用模块化工程管理：

```text
~/.hammerspoon/
├── init.lua              # 主入口：负责全局异常守护与模块加载
├── .gitignore            # Git 忽略配置
├── README.md             # 项目自述文档
├── ime/
│   └── ime.lua           # 日式键盘 (JIS 102/104) 成对拦截与无缝输入法强切
├── caffeine/
│   ├── caffeine.lua      # 菜单栏防休眠与 Toggle 机制
│   └── assets/           # 菜单栏自定义模板图标资源 (active.png / inactive.png)
└── reload/
    └── reload.lua        # 配置文件变动自动重载模块
```

---

## 🛠️ 安装与快速上手 (Installation & Usage)

### 1. 前置准备
- 确保您的 Mac 上已安装了 [Hammerspoon](https://www.hammerspoon.org/)。
- 确保系统已启用以下两种系统输入法：
  - **ABC 英文** (`com.apple.keylayout.ABC`)
  - **简体拼音** (`com.apple.inputmethod.SCIM.ITABC`)

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
- 若系统未启用 ABC 或简体拼音，会主动弹窗警示。
- 状态栏会出现 🌙 图标，表示 Caffeine 防休眠处于就绪状态。

---

## ⚙️ 模块详解 (Deep Dive)

### 1. 日式键盘 (JIS Layout) 输入法成对精准拦截机制
在 macOS 系统中使用日式键盘（JIS 102/104 键位）时，按下空格左侧的 `英数 (Eisuu)` 和右侧的 `かな (Kana)` 切换输入法，在某些浏览器输入框或特定终端中可能会引起**光标失去焦点**、**按键粘滞**或**跨输入框无法直接切中文**的 Bug。

- **成对按键精准拦截 (`KeyDown` + `KeyUp`)**：
  传统的单向拦截往往只捕获 `keyDown` 并吞掉，导致手指松开时的 `keyUp` 泄露给前台应用，引起 Electron/终端/远程桌面等应用内部键盘状态机混乱。本模块维护按键消费状态字典，`keyDown` 消费时其对应的 `keyUp` 同步被消费；穿透放行时 `keyUp` 也对称放行，向系统派发的按键事件 100% 完整对称。
- **拼音内部英文模式自愈**：
  若当前已处于简体拼音状态（例如用户按 Shift 进入了临时英文输入），此时按下 `かな`，系统会自动将 `keyDown` 与 `keyUp` 完整放行给 macOS 原生驱动，触发原生系统退出拼音内部英文状态。
- **连发 (Autorepeat) 一致性**：
  按键连发严格继承首击的放行/消费决策，长按或快速连击时不会意外破坏穿透逻辑。
- **Quartz 超时与系统唤醒自愈**：
  监听 `tapDisabledByTimeout` 与 `tapDisabledByUserInput` 原地重启，并在系统睡眠唤醒、锁屏解锁后重建 EventTap，彻底杜绝 EventTap 假死。

### 2. Caffeine 菜单栏防休眠
- **操作方式**：单击状态栏中的 🌙 即可切换至 ☕️ 模式。
- **图标自定义**：
  - 默认降级使用 `☕️` 与 `🌙` Emoji。
  - 支持在 `caffeine/assets/` 目录中放置 36x36px 透明背景的纯黑 PNG 图片（`active.png` 与 `inactive.png`），自动开启 `template(true)` 适配 macOS 深色/浅色外观。
- **安全保障与合盖感知**：
  - 检测系统休眠/合盖事件，在准备休眠或合盖时自动关闭防休眠，防止电脑在背包中发热耗电。
  - 针对外接显示器合盖（Clamshell Mode）场景，通过 `ioreg` 底层状态轮询作为兜底保护，自动恢复正常休眠策略。

### 3. 配置热更新
- **工作机制**：在 `reload` 模块中创建了 `hs.pathwatcher` 监控整个配置文件目录。只要在此目录下保存任何 `.lua` 文件，Hammerspoon 就会立即自动重新加载，大幅提升微调配置时的开发体验。

---

## 📄 开源协议 (License)

本项目基于 [MIT](LICENSE) 协议开源。
