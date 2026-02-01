import AppKit
import CoreData
import SwiftUI

// MARK: - 应用委托
/// 处理 macOS 应用级事件，例如 Dock 图标点击
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 延迟一点时间确保窗口已创建
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.zoom(nil)
            }
        }

        // 确保 Dock 图标显示（使用默认策略）
        NSApp.setActivationPolicy(.regular)

        // 初始化状态栏控制器
        statusBarController = StatusBarController()

        // 同时尝试设置 Dock 图标为资源的 icns（保留原色）
        if let dockIconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let dockImage = NSImage(contentsOf: dockIconURL)
        {
            dockImage.isTemplate = false
            NSApp.applicationIconImage = dockImage
        }
    }

    /// 处理用户点击 Dock 图标时的应用重新开启事件
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        // 如果有现存窗口，显示它们
        if !sender.windows.isEmpty {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
            return false
        }
        // 否则允许系统创建新窗口
        return true
    }
}

// MARK: - 应用主入口
@main
struct TakeARestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let timerManager = TimerState()

    init() {
        // 初始化数据库并插入预设配置
        SettingsStorage.shared.setupDatabase()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(timerManager)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
