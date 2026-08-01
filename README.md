# 🔨🥄 Hammerspoon Config

> **Make my Mac smarter. Make my typing flow.**
>
> 这是一个高度精炼、稳健且模块化的 Hammerspoon 配置项目。致力于解决 macOS 系统在日式键盘（JIS Layout）输入法切换时的痛点，并提供便捷的系统常亮控制（Caffeine）与剪贴板历史记录。

---

## 🚀 核心特性 (Features)

本项目采用模块化设计，每个功能都作为一个独立的子模块进行加载：

| 模块名称 | 功能说明 | 核心机制 | 状态栏反馈 |
| :--- | :--- | :--- | :---: |
| **`ime`** | **日式键盘零失焦强切** | 基于 Carbon API 底层单向强切输入法，100% 解决多焦点/跨输入框切换死锁，物理按键精准拦截。 | - |
| **`caffeine`** | **Caffeine 防休眠 Toggle** | 一键阻止/允许系统休眠与屏幕自动变暗，支持 SF Symbols / 自定义 PNG 图标及主题自适应。 | ☕️ / 🌙 |
| **`clipboard`** | **剪贴板历史记录** | 利用 `hs.pasteboard.watcher` 异步事件监听剪贴板更新，自动持久化，支持超长文本安全截断及防自触发循环。 | 📋 |
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
│   └── ime.lua           # 日式键盘 (JIS 102/104) 极简无缝输入法强切
├── caffeine/
│   ├── caffeine.lua      # 菜单栏防休眠与 Toggle 机制
│   └── assets/           # 菜单栏自定义模板图标资源 (active.png / inactive.png)
├── clipboard/
│   └── clipboard.lua     # 剪贴板历史数据持久化与状态栏管理模块
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
- 此时状态栏会出现 🌙 图标，表示 Caffeine 防休眠处于就绪状态。

---

## ⚙️ 模块详解 (Deep Dive)

### 1. 日式键盘 (JIS Layout) 极简无缝强切机制
在 macOS 系统中使用日式键盘（JIS 102/104 键位）时，按下空格左侧的 `英数 (Eisuu)` 和右侧的 `かな (Kana)` 切换输入法，在某些浏览器输入框或特定终端中可能会引起**光标失去焦点**或**跨输入框无法直接切中文**的 Bug。
- **解决方案**：此配置采用极简单向强切机制。无论在哪个输入框、不论前台是什么软件，按下 `かな` 瞬间强制调用系统 API 切换至中文拼音，按下 `英数` 瞬间强切英文。
- **性能优化**：去除了所有多余的逻辑分支和冗余看门狗，忽略按键长按连发 (Autorepeat)，使响应延迟降至最低。

### 2. Caffeine 菜单栏防休眠
- **操作方式**：单击状态栏中的 🌙 即可切换至 ☕️ 模式。
- **图标自定义**：
  - 默认降级使用 `☕️` 与 `🌙` Emoji。
  - 支持在 `caffeine/assets/` 目录中放置 36x36px 透明背景的纯黑 PNG 图片（`active.png` 与 `inactive.png`），自动开启 `template(true)` 适配 macOS 深色/浅色外观。
- **安全保障**：检测系统休眠/合盖事件，在合盖时自动关闭防休眠，防止电脑在背包中发热耗电。

### 3. 配置热更新
- **工作机制**：在 `reload` 模块中创建了 `hs.pathwatcher` 监控整个配置文件目录。只要在此目录下保存任何 `.lua` 文件，Hammerspoon 就会立即自动重新加载，大幅提升微调配置时的开发体验。

### 4. 剪贴板历史记录 (Clipboard History)
- **状态栏反馈**：点击状态栏中的 📋 图标展示最近 30 条剪贴板文本历史，支持滑动滚动。
- **工作机制**：
  - **事件驱动监听**：利用 `hs.pasteboard.watcher` 挂载系统事件回调进行异步监控。常态 CPU 占用为 0%，响应延迟在 0.25s 内。
  - **智能过滤**：自动过滤并去重已存在的记录，限制单条最大长度为 100KB；采用 Lua `utf8` 库安全截断超长文本并替换换行符为 ` ↵ `。
  - **持久化**：所有的历史条目均利用 `hs.settings` 实现本地同步存储，重启或 Reload 不丢失。

---

## 📄 开源协议 (License)

本项目基于 [MIT](LICENSE) 协议开源。
