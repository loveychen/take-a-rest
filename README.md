# TakeARest - macOS 原生番茄时钟应用

这是一个使用 Swift/SwiftUI 开发的 macOS 原生番茄时钟应用，具有强制休息功能和真正的系统级锁屏能力。

## Quick Start

### 开发环境要求

- macOS 13.0+ (Ventura 或更高版本)
- Xcode 15.0+ (包含 Swift 5.9+)
- Command Line Tools for Xcode

### 快速运行

```bash
# 克隆项目（如果尚未克隆）
git clone <repository-url>
cd RelaxPlease/RelaxPlease/TakeARest

# 使用 Makefile 运行（推荐）
make run

# 或者使用 Swift Package Manager 直接运行
swift run
```

## 功能特性

### ✅ 强制休息番茄时钟

- 工作/休息时间交替计时
- 自定义工作时间（1-3600秒）和休息时间（1-3600秒）
- 暂停/继续功能
- 重置计时器功能

### ✅ 系统级休息界面

- 休息模式下全屏显示，优先级最高
- 隐藏 Dock 和菜单栏
- 禁用应用切换（Command+Tab）和桌面滑动
- 完全阻止用户与其他应用程序的交互

### ✅ 系统级锁屏功能

- 直接调用 macOS 系统锁屏 API，无 AppleScript 依赖
- 双重锁屏机制：优先使用屏保服务，失败时自动降级
- 与用户手动按下快捷键效果完全一致

### ✅ 简洁直观的界面

- 工作模式：显示倒计时、进度条
- 休息模式：全屏黑色背景、大号倒计时、操作按钮
- 支持设置工作/休息时间

## 技术实现

### 开发语言与框架

- **Swift 5** - 现代、安全、高效的编程语言
- **SwiftUI** - 声明式 UI 框架，提供简洁的界面构建方式
- **AppKit** - macOS 原生应用框架，提供系统级功能访问

### 关键技术点

#### 1. 系统级休息界面实现

```swift
// 设置窗口为最高优先级
window.level = .screenSaver + 1

// 禁用系统功能
NSApp.presentationOptions = [
    .hideDock,
    .hideMenuBar,
    .disableProcessSwitching,
    .disableForceQuit,
    .disableSessionTermination,
    .disableHideApplication
]
```

#### 2. 无依赖锁屏功能实现

```swift
// 直接调用系统屏保服务
let service = "com.apple.screensaver"
let selector = sel_registerName("lock")

if let screenSaver = NSClassFromString(service) {
    if (screenSaver as AnyObject).responds(to: selector) {
        let _ = (screenSaver as AnyObject).perform(selector)
    } else {
        // 备用方案：使用 pmset 使屏幕休眠
        fallbackLockScreen()
    }
}
```

#### 3. 界面切换机制

使用 ZStack 实现工作/休息界面的无缝切换，避免多窗口管理的复杂性。

## 项目结构

```
TakeARest/
├── TakeARestApp.swift          # 应用入口文件
├── ContentView.swift           # 主界面视图（包含所有功能）
├── Makefile                    # 构建脚本
├── Package.swift               # SPM 配置文件
└── README.md                   # 项目说明文档
```

## 详细使用说明

### 主界面功能

1. **倒计时显示**：实时显示当前工作/休息剩余时间
2. **进度条**：直观展示时间进度
3. **暂停/继续**：控制计时器运行状态
4. **重置**：重置计时器到初始状态
5. **退出**：关闭应用

### 设置界面功能

1. **工作时间**：设置工作时长（秒）
2. **休息时间**：设置休息时长（秒）
3. 使用数字输入框或步进器调整时间

### 休息模式功能

1. **休息倒计时**：显示剩余休息时间
2. **工作按钮**：立即结束休息，返回工作模式
3. **锁屏按钮**：直接锁定屏幕
4. 自动结束：休息时间结束后自动返回工作模式

## Makefile 命令

```bash
# 编译项目 (Release)
make build

# 编译项目 (Debug)
make build-debug

# 运行所有测试
make test

# 编译并运行应用 (Release)
make run

# 编译并运行应用 (Debug)
make run-debug

# 清理构建产物
make clean

# 显示项目信息
make info

# 更新依赖
make update
```

## 与 Electron 版本的对比

| 功能           | Electron 版本             | Swift 原生版本               |
| -------------- | ------------------------- | ---------------------------- |
| 系统级休息界面 | ❌ 模拟实现，可被绕过     | ✅ 真正的系统级控制          |
| 锁屏功能       | ⚠️ 依赖外部工具           | ✅ 无依赖系统 API            |
| 性能           | ⚠️ 资源占用较高           | ✅ 轻量级，高性能            |
| 用户体验       | ⚠️ 可能存在界面闪烁或延迟 | ✅ 原生流畅体验              |
| 系统集成       | ⚠️ 受限于 Electron API    | ✅ 完整的 macOS 系统功能访问 |

## 总结

RelaxPleaseNative 是一个功能完整的 macOS 原生番茄时钟应用，专注于提供真正的强制休息体验。通过直接调用 macOS 系统 API，实现了传统跨平台框架难以达到的系统级控制能力，确保用户在休息时间得到真正的放松。

应用采用简洁的设计和高效的实现，既满足了功能需求，又保证了良好的用户体验和性能表现。
