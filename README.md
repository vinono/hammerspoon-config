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
| **`reload`** | **配置自动热重载** | 监听配置文件变动，`.lua` 文件保存时瞬时完成 Reload。 | 🚀 气泡提示 |

---

## 📂 目录结构 (Structure)

本项目的目录结构非常清晰，采用模块化工程管理：

```text
~/.hammerspoon/
├── init.lua              # 主入口：负责全局异常守护与模块加载
├── .gitignore            # Git 忽略配置
├── README.md             # 项目自述文档
├── caffeine/
│   ├── caffeine.lua      # 菜单栏防休眠与 Toggle 机制
│   └── assets/           # 菜单栏自定义模板图标资源 (active.png / inactive.png)
├── chrome/
│   └── startup.lua       # Hammerspoon 登录启动时带地区参数冷启动 Chrome
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

### 3. 配置热更新
- **工作机制**：在 `reload` 模块中创建了 `hs.pathwatcher` 监控整个配置文件目录。只要在此目录下保存任何 `.lua` 文件，Hammerspoon 就会立即自动重新加载，大幅提升微调配置时的开发体验。

---

## 📄 开源协议 (License)

本项目基于 [MIT](LICENSE) 协议开源。
