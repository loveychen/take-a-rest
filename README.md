# TakeARest

一个简洁优雅的 macOS 休息定时器应用，帮助你维持健康的工作-休息平衡。使用 SwiftUI 和 AppKit 开发，支持菜单栏集成、系统锁屏检测和自定义工作/休息周期。

## ✨ 功能特性

### 核心计时器功能

- **灵活的工作/休息周期**：自定义工作和休息时长
- **预设配置**：内置番茄工作法、深度工作、长时间工作、短休息等预设
- **暂停/继续**：随时控制计时器运行状态
- **自动模式切换**：自动在工作和休息模式之间切换
- **休息提醒**：休息期间全屏通知
- **系统锁屏检测**：工作时锁屏自动暂停，解锁后自动继续
  - 仅影响工作模式；休息模式不受影响

### 系统集成

- **菜单栏图标**：从 macOS 菜单栏快速访问
  - 左键点击打开主窗口
  - 右键点击显示上下文菜单（打开主窗口/开始/暂停/退出）
- **Dock 集成**：完整的 Dock 图标支持和窗口管理
- **系统通知**：模式切换时的模态通知
- **键盘快捷键**：Command+Q 从菜单退出应用

### 界面和体验

- **简洁设计**：最小化、无干扰的设计
- **中文本地化**：完整的中文 UI 和菜单标签
- **响应式布局**：计时器和设置之间的平滑标签导航
- **渐变背景**：现代视觉设计和精细的渐变效果
- **mm:ss 格式**：分:秒格式的清晰时间显示
- **深色模式支持**：适配浅色和深色 macOS 主题

### 设置和持久化

- **自定义预设**：创建和管理工作/休息配置
- **预设排序**：按总时长（工作+休息）降序排列
- **Core Data 持久化**：预设保存在本地 Core Data 数据库
- **设置保存**：上次选择的预设或自定义时长在应用重启后保留

## 📋 架构设计

代码分为三个主要模块：

### 模型层 (`Sources/TakeARest/Models/`)

- **`TimerState.swift`**：计时器状态机和核心逻辑
  - 管理工作/休息周期，精度为 1 秒
  - 发布 `@Published` 属性供 SwiftUI 绑定
  - 监听系统会话变化（锁屏/解锁事件）
  - 发送状态变化通知（暂停、锁屏）
  - 处理计时器启动/停止、模式切换、暂停/继续

- **`SettingsStorage.swift`**：Core Data 持久化层
  - 管理预设配置（工作时间、休息时间、系统预设标志）
  - 提供预设的 CRUD 操作
  - 处理当前时间设置的用户默认值
  - 单例模式确保集中数据访问

- **`Constants.swift`**：时间预设和配置常量
  - 默认工作/休息时间
  - 预定义预设：番茄工作法、长工作、短工作、深度工作、测试
  - 易于扩展新预设

### 视图层 (`Sources/TakeARest/Views/`)

- **`RootView.swift`**：主应用容器
  - 标签导航（计时器/设置）
  - 顶部操作栏（暂停、重置、退出按钮）
  - 休息模态框叠加
  - 应用启动时加载设置

- **`MainScreenView.swift`**：计时器显示和控制
  - 大号时间显示（mm:ss 格式）
  - 模式指示符（工作中/休息中）
  - 可视化进度指示器
  - 状态标签和时间信息

- **`SettingsScreenView.swift`**：设置和预设管理
  - 水平可滚动预设卡片
  - 紧凑计时控制（单行 mm:ss +/- 按钮）
  - 当前设置显示
  - 动态预设排序

- **`RestScreenView.swift`**：休息模态框
  - 休息期间全屏叠加显示
  - 休息时间倒计时
  - 模式切换按钮
  - 锁屏功能（AppleScript 主方案，系统命令备选）

- **`AppIconView.swift`**：可复用应用图标组件
  - 用于设置界面的视觉品牌
  - SwiftUI View 包装器

### 控制层 (`Sources/TakeARest/Controllers/`)

- **`App.swift`**：应用入口和 AppDelegate
  - SwiftUI App 结构和场景设置
  - macOS 生命周期事件处理
  - 从捆绑的 `AppIcon.icns` 设置 Dock 图标
  - 主窗口初始化
  - Dock 重新打开处理器

- **`StatusBarController.swift`**：菜单栏集成
  - NSStatusItem 设置和管理
  - 图标加载（优先模板，备选彩色）
  - 中文标签的上下文菜单创建
  - 左右键点击区分
  - 点击操作处理（打开窗口 vs. 显示菜单）
  - 监听暂停状态变化并动态更新菜单标签

## 🚀 快速开始

### 系统要求

- macOS 13.0 或更高版本
- Swift 5.9+（Xcode 15+ 自带）
- Xcode 15+（可选，用于开发）

### 从源代码构建

**使用 Make（推荐）：**

```bash
make build          # 构建 Release 二进制文件
make bundle         # 创建 .app 应用包
make dmg            # 创建 .dmg 安装程序
make install        # 构建并安装到 /Applications
make run            # 构建并运行
make clean          # 清理构建产物
```

**使用 Swift Package Manager：**

```bash
swift build -c release
```

二进制文件将位于 `.build/release/TakeARest`。

### 安装

#### 从 DMG 安装（推荐）

1. 下载或构建 DMG：`make dmg`
2. 挂载 DMG 并将 TakeARest.app 拖放到 /Applications

#### 从源代码安装

```bash
make install
```

这将构建应用并复制到 `/Applications/TakeARest.app`。

### 使用方法

1. **启动**应用（从 Applications 文件夹或 `make run`）
2. **设置时间**：进入设置标签调整工作/休息时长或选择预设
3. **开始计时**：应用会自动加载上次选择的预设并开始计时
4. **暂停/继续**：点击顶部栏的暂停按钮或右键菜单栏图标 → "暂停"/"开始"
5. **模式切换**：计时器自动在工作和休息之间切换；也可在休息模态框中手动切换
6. **系统锁屏**：工作时锁屏会自动暂停；解锁后自动继续
7. **菜单栏**：左键点击打开窗口，右键点击显示菜单

## 🔧 配置

### 修改预设

编辑 `Models/Constants.swift` 添加或修改预设工作/休息时间：

```swift
static let customWorkTime: Int = 50 * 60
static let customRestTime: Int = 10 * 60
```

### 更改默认值

在 `Models/Constants.swift` 中更新 `TimeConstants.defaultWorkTime` 和 `TimeConstants.defaultRestTime`。

### 锁屏行为

锁屏检测在 `Models/TimerState.swift` 中：

- 在 `NSWorkspace.sessionDidResignActiveNotification` 时自动暂停
- 在 `NSWorkspace.sessionDidBecomeActiveNotification` 时自动继续
- 仅在工作模式下生效

## 📱 系统权限

### Apple Events（锁屏）

首次使用锁屏功能时，macOS 将提示你授予自动化权限：

- **提示**：「Allow TakeARest to send Apple Events to System Events?」
- **授予**：点击「OK」允许应用通过 AppleScript 锁屏
- **手动**：系统设置 → 隐私与安全性 → 自动化 → 为 TakeARest 启用「System Events」

这是以下 AppleScript 命令所需的权限：

```swift
tell application "System Events" to keystroke (key code 107) using {command down, control down}
```

## 📂 目录结构

```
TakeARest/
├── Sources/TakeARest/
│   ├── Models/
│   │   ├── Constants.swift          # 时间预设
│   │   ├── SettingsStorage.swift    # Core Data 持久化
│   │   └── TimerState.swift         # 计时器状态机
│   ├── Views/
│   │   ├── AppIconView.swift        # 图标组件
│   │   ├── MainScreenView.swift     # 计时器显示
│   │   ├── RestScreenView.swift     # 休息模态框
│   │   ├── RootView.swift           # 主容器
│   │   └── SettingsScreenView.swift # 设置界面
│   ├── Controllers/
│   │   ├── App.swift                # 应用入口和委托
│   │   └── StatusBarController.swift # 菜单栏集成
│   ├── Resources/
│   │   ├── AppIcon.icns             # Dock 图标
│   │   └── AppIcon.svg              # 菜单栏模板图标
│   └── Info.plist
├── Package.swift                     # SPM 配置
├── Makefile                          # 构建脚本
└── README.md                         # 本文件
```

## 🛠️ 开发

### 项目设置

1. 克隆仓库
2. `cd TakeARest`
3. `swift build -c release`

### 代码组织

- **Models**：业务逻辑和数据持久化
- **Views**：SwiftUI UI 组件
- **Controllers**：macOS 集成和系统交互

### 关键设计模式

- **MVVM**：视图通过 `@EnvironmentObject` 绑定到 TimerState
- **单例**：SettingsStorage.shared 提供集中的数据访问
- **通知中心**：NotificationCenter 用于组件间通信
- **观察者**：NSWorkspace 监听系统事件，NotificationCenter 监听应用事件

### 通知键值

- `"TakeARest.TogglePause"`：由状态菜单发送以切换暂停
- `"TakeARest.PauseStateChanged"`：由 TimerState 发送，userInfo["isPaused"] 包含状态

## 🐛 故障排除

### 应用无法启动

- 确保 macOS 13.0+
- 检查控制台日志：`log stream --predicate 'process=="TakeARest"'`

### 锁屏权限不工作

- 打开系统设置 → 隐私与安全性 → 自动化
- 为 TakeARest 授予「System Events」权限
- 或在首次使用锁屏功能时允许 Apple Events 提示

### 菜单栏图标不显示

- 检查图标文件（AppIcon.icns、AppIcon.svg）是否在 Resources 文件夹中
- 验证 StatusBarController 中的 `Bundle.main.url(forResource:withExtension:)` 日志

### 预设未保存

- 验证 Core Data 栈已初始化：检查 `SettingsStorage.setupDatabase()` 是否被调用
- 检查用户是否有应用目录的写入权限
- 查看控制台日志中的 Core Data 错误

## 📝 许可证

MIT 许可证。详见 LICENSE 文件。

## 👤 作者

由 Chen Diao 创建

---

**好好休息吧！💪 保护好你的眼睛和背部。👀**
