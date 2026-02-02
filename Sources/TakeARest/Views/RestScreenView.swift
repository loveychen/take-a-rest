import CoreData
import Foundation
import SwiftUI

struct RestScreenView: View {
    @EnvironmentObject var timerManager: TimerState
    @State private var showLockMessage = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 标题
                VStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("休息时间")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("放松一下，恢复精力")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()
                    .frame(height: 40)

                // 大计时器
                Text(timerManager.formattedTime())
                    .font(.system(size: 120, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .tracking(2)

                Spacer()
                    .frame(height: 60)

                // 操作按钮
                VStack(spacing: 12) {
                    // 继续工作
                    Button(action: {
                        timerManager.isWorking = true
                        timerManager.currentTime = max(timerManager.workTime, 1)
                        WindowManager.shared.updateWindowToNormal(
                            isBackgroundMode: timerManager.isBackgroundMode)
                        timerManager.showRestModal = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                            Text("继续工作")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // 锁屏和延长休息
                    HStack(spacing: 12) {
                        Button(action: {
                            extendRest()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("延长5分钟")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            triggerLockScreen()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                Text("锁屏休息")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 60)

                // 提示信息
                if showLockMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("已锁屏 - 触发屏幕休眠")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            WindowManager.shared.updateWindowToFullScreen()
        }
        .onDisappear {
            WindowManager.shared.updateWindowToNormal(
                isBackgroundMode: timerManager.isBackgroundMode)
        }
    }

    private func extendRest() {
        // 延长 5 分钟（300 秒）
        let extensionTime = 5 * 60
        timerManager.restTime += extensionTime
        timerManager.currentTime = timerManager.restTime

        // 保存更新后的设置
        SettingsStorage.shared.saveCurrentTimeSettings(
            workTime: timerManager.workTime,
            restTime: timerManager.restTime
        )
        print("✅ Extended rest by 5 minutes")
    }

    private func triggerLockScreen() {
        showLockMessage = true
        lockScreenWithSystemCommand()

        // 延迟隐藏提示信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showLockMessage = false
        }
    }

    private func lockScreenWithSystemCommand() {
        // 方案 1: 使用 AppleScript 发送快捷键（Cmd+Ctrl+Q）
        let script =
            "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            // 忽略返回值，检查 error 字典中的详细信息以避免隐式类型转换警告
            _ = appleScript.executeAndReturnError(&error)
            if error == nil {
                print("✅ AppleScript lock screen triggered successfully")
                return
            } else if let errMsg = error?["NSAppleScriptErrorMessage"] as? String {
                print("⚠️ AppleScript method failed: \(errMsg)")
            } else if let error = error {
                print("⚠️ AppleScript method failed: \(error)")
            } else {
                print("⚠️ AppleScript method failed with unknown error")
            }
        }

        // 方案 2: 启动屏幕保护程序（备选方案）
        let screensaverTask = Process()
        screensaverTask.launchPath = "/bin/launchctl"
        screensaverTask.arguments = ["start", "com.apple.screensaver.engine"]

        do {
            try screensaverTask.run()
            print("✅ Screen saver triggered successfully")
            return
        } catch {
            print("⚠️ Screen saver method failed: \(error)")
        }

        // 方案 3: 让显示器睡眠（备选方案）
        let sleepTask = Process()
        sleepTask.launchPath = "/usr/bin/pmset"
        sleepTask.arguments = ["displaysleepnow"]

        do {
            try sleepTask.run()
            print("✅ Display sleep triggered")
        } catch {
            print("⚠️ Display sleep failed: \(error)")
        }
    }
}

// MARK: - 窗口管理
/// 集中管理应用窗口操作的单例类
@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private init() {}

    /// 存储为其它显示器创建的遮罩窗口
    private var overlayWindows: [NSWindow] = []

    /// 当前被监听的窗口（用于监听屏幕变更）
    private var observedWindow: NSWindow?

    /// 更新窗口为全屏休息模式；在多屏环境下为每个屏幕创建遮罩
    func updateWindowToFullScreen() {
        // 移除旧的监听以避免重复注册
        stopObserving()

        // 先清理已有的遮罩
        for w in overlayWindows {
            w.orderOut(nil)
        }
        overlayWindows.removeAll()

        // 选择最合适的主窗口（优先使用 keyWindow / mainWindow）
        guard
            let mainWindow = NSApp.keyWindow ?? NSApp.mainWindow
                ?? NSApplication.shared.windows.first
        else {
            print("⚠️ No active window found")
            return
        }

        DispatchQueue.main.async {
            // 确定主交互屏幕（优先使用主窗口所在屏幕）
            let primaryScreen = mainWindow.screen ?? NSScreen.main
            let screens = NSScreen.screens

            for screen in screens {
                if screen == primaryScreen {
                    // 把主应用窗口移动到主屏并设置为互动的遮罩窗口
                    mainWindow.makeKeyAndOrderFront(nil)
                    mainWindow.setFrame(screen.frame, display: true)
                    mainWindow.level = .screenSaver + 1
                    mainWindow.collectionBehavior = [
                        .canJoinAllSpaces, .fullScreenPrimary, .stationary,
                    ]
                    mainWindow.isMovable = false
                    mainWindow.isOpaque = true
                    mainWindow.backgroundColor = NSColor.black
                    mainWindow.ignoresMouseEvents = false
                    mainWindow.styleMask = [.fullSizeContentView]
                    mainWindow.titleVisibility = .hidden
                    mainWindow.titlebarAppearsTransparent = true
                    mainWindow.hasShadow = false

                    // 调试信息：打印主窗口与屏幕帧以帮助诊断覆盖问题
                    print(
                        "🖥️ Primary screen: frame=\(screen.frame), visible=\(screen.visibleFrame), windowFrame=\(mainWindow.frame), scale=\(screen.backingScaleFactor)"
                    )
                } else {
                    // 为其它屏幕创建不可移动、占位的遮罩窗口以阻断交互
                    let overlay = NSWindow(
                        contentRect: screen.frame,
                        styleMask: [.borderless],
                        backing: .buffered,
                        defer: false,
                        screen: screen
                    )

                    overlay.level = .screenSaver + 1
                    overlay.backgroundColor = NSColor.black
                    overlay.isOpaque = true
                    // 不忽略鼠标事件，这样遮罩会拦截点击，阻止用户与下面的窗口交互
                    overlay.ignoresMouseEvents = false
                    // 确保遮罩也出现在全屏空间中
                    overlay.collectionBehavior = [
                        .canJoinAllSpaces, .fullScreenAuxiliary, .stationary,
                    ]
                    overlay.hasShadow = false

                    // 明确设置 frame（兼容不同缩放/菜单栏）并打印调试信息
                    overlay.setFrame(screen.frame, display: true)
                    if overlay.frame.integral != screen.frame.integral {
                        let adjusted = screen.frame.insetBy(dx: -1, dy: -1)
                        overlay.setFrame(adjusted, display: true)
                        print(
                            "🛠️ Adjusted overlay frame for screen: adjustedFrame=\(overlay.frame) (was \(screen.frame))"
                        )
                    }
                    print(
                        "🖥️ Overlay created for screen: frame=\(screen.frame), visible=\(screen.visibleFrame), overlayFrame=\(overlay.frame), scale=\(screen.backingScaleFactor)"
                    )

                    // 让遮罩出现在最前，但不要抢主窗口的 key 状态
                    overlay.orderFrontRegardless()

                    self.overlayWindows.append(overlay)
                }
            }

            // 隐藏系统 UI 元素
            NSApp.presentationOptions = [
                .hideDock,
                .hideMenuBar,
                .disableProcessSwitching,
                .disableForceQuit,
                .disableSessionTermination,
                .disableHideApplication,
                .fullScreen,
            ]

            // 激活应用
            NSApp.activate(ignoringOtherApps: true)

            // 开始监听主窗口与屏幕变更，保证在移动显示器或分辨率变化时自动调整
            self.startObserving(window: mainWindow)
        }
    }

    /// 恢复窗口为正常模式
    /// - Parameter isBackgroundMode: 是否应该在后台运行
    func updateWindowToNormal(isBackgroundMode: Bool) {
        // 移除并关闭所有遮罩窗口
        for overlay in overlayWindows {
            overlay.orderOut(nil)
        }
        overlayWindows.removeAll()

        // 停止监听屏幕变更
        stopObserving()

        guard let window = NSApplication.shared.windows.first else {
            print("⚠️ No active window found")
            return
        }

        DispatchQueue.main.async {
            // 保持窗口最大化
            window.zoom(nil)

            window.level = .normal
            window.collectionBehavior = []
            window.isMovable = true
            window.isOpaque = true
            window.backgroundColor = NSColor.windowBackgroundColor
            window.ignoresMouseEvents = false

            NSApp.presentationOptions = []

            // 根据后台模式决定是否显示窗口
            if !isBackgroundMode {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                window.orderOut(nil)
            }
        }
    }

    // MARK: - 屏幕/窗口监听
    /// 开始监听主窗口的屏幕变更以及系统屏幕参数变更
    private func startObserving(window: NSWindow) {
        observedWindow = window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidChangeScreen(_:)),
            name: NSWindow.didChangeScreenNotification,
            object: window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    /// 停止监听
    private func stopObserving() {
        if let window = observedWindow {
            NotificationCenter.default.removeObserver(
                self, name: NSWindow.didChangeScreenNotification, object: window)
            observedWindow = nil
        }
        NotificationCenter.default.removeObserver(
            self, name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func windowDidChangeScreen(_ notification: Notification) {
        // 当主窗口移动到另一块屏幕时，重新计算全屏/遮罩设置
        DispatchQueue.main.async {
            if !self.overlayWindows.isEmpty {
                self.updateWindowToFullScreen()
            }
        }
    }

    @objc private func screensDidChange(_ notification: Notification) {
        // 显示器连接/断开或分辨率变化时，重新计算全屏/遮罩设置
        DispatchQueue.main.async {
            if !self.overlayWindows.isEmpty {
                self.updateWindowToFullScreen()
            }
        }
    }
}
