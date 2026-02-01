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
            let result = appleScript.executeAndReturnError(&error)
            if error == nil {
                print("✅ AppleScript lock screen triggered successfully")
                return
            } else {
                print(
                    "⚠️ AppleScript method failed: \(String(describing: error?["NSAppleScriptErrorMessage"] ?? error))"
                )
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

    /// 更新窗口为全屏休息模式
    func updateWindowToFullScreen() {
        guard let window = NSApplication.shared.windows.first else {
            print("⚠️ No active window found")
            return
        }

        DispatchQueue.main.async {
            // 确保窗口显示出来
            window.makeKeyAndOrderFront(nil)

            // 获取当前屏幕的尺寸
            if let screenFrame = NSScreen.main?.frame {
                window.setFrame(screenFrame, display: true)
            }

            // 设置窗口为最高优先级
            window.level = .screenSaver + 1
            window.collectionBehavior = [
                .canJoinAllSpaces, .fullScreenPrimary, .stationary,
            ]
            window.isMovable = false
            window.isOpaque = true
            window.backgroundColor = NSColor.black
            window.ignoresMouseEvents = false
            window.styleMask = [.fullSizeContentView]
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.hasShadow = false

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
        }
    }

    /// 恢复窗口为正常模式
    /// - Parameter isBackgroundMode: 是否应该在后台运行
    func updateWindowToNormal(isBackgroundMode: Bool) {
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
}
