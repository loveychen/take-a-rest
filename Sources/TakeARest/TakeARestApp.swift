import SwiftUI
import AppKit

// AppDelegate用于处理Dock图标点击事件和应用程序状态
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 确保应用程序在Dock中显示图标
        NSApp.setActivationPolicy(.regular)
        
        // 延迟一下，确保窗口已经创建
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                // 将窗口最大化
                window.zoom(nil)
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 检查是否有窗口
        if !sender.windows.isEmpty {
            // 显示所有现有窗口
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
            // 激活应用程序
            NSApp.activate(ignoringOtherApps: true)
            // 返回false，阻止系统创建新窗口
            return false
        }
        // 如果没有窗口，允许系统创建新窗口
        return true
    }
}

@main
struct TakeARestApp: App {
    // 创建AppDelegate实例
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 600)
    }
}
