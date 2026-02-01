import CoreData
import SwiftUI

struct RestModal: View {
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 50) {
                Text("休息时间")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)

                Text(timerManager.formattedTime())
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.green)

                HStack(spacing: 30) {
                    Button("工作") {
                        // 用户手动结束休息，切换回工作模式
                        timerManager.isWorking = true
                        timerManager.currentTime = max(timerManager.workTime, 1)
                        updateWindowToNormal()
                        // 直接关闭模态框
                        timerManager.showRestModal = false
                    }
                    .font(.system(size: 30, weight: .semibold))
                    .frame(width: 250, height: 80)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)

                    Button("锁屏") {
                        lockScreen()
                    }
                    .font(.system(size: 30, weight: .semibold))
                    .frame(width: 250, height: 80)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            updateWindowToFullScreen()
        }
        .onDisappear {
            // 当休息模态框消失时，确保窗口恢复正常状态
            updateWindowToNormal()
        }
    }

    private func updateWindowToFullScreen() {
        guard let window = NSApplication.shared.windows.first else { return }

        let retainedWindow = window

        DispatchQueue.main.async {
            // 确保窗口显示出来（无论是否在后台模式下）
            retainedWindow.makeKeyAndOrderFront(nil)

            // 获取当前屏幕的尺寸（包括菜单栏区域）
            let screen = NSScreen.main
            if let screenFrame = screen?.frame {
                // 直接将窗口尺寸设置为屏幕尺寸
                retainedWindow.setFrame(screenFrame, display: true)
            }

            // 设置窗口为最高优先级
            retainedWindow.level = .screenSaver + 1
            retainedWindow.collectionBehavior = [
                .canJoinAllSpaces, .fullScreenPrimary, .stationary,
            ]
            retainedWindow.isMovable = false
            retainedWindow.isOpaque = true
            retainedWindow.backgroundColor = NSColor.black
            retainedWindow.ignoresMouseEvents = false
            retainedWindow.styleMask = [.fullSizeContentView]
            retainedWindow.titleVisibility = .hidden
            retainedWindow.titlebarAppearsTransparent = true
            retainedWindow.hasShadow = false

            // 禁用系统功能，确保休息界面占据全局焦点
            NSApp.presentationOptions = [
                .hideDock,
                .hideMenuBar,
                .disableProcessSwitching,
                .disableForceQuit,
                .disableSessionTermination,
                .disableHideApplication,
                .fullScreen,
            ]

            // 激活应用以显示休息界面
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateWindowToNormal() {
        guard let window = NSApplication.shared.windows.first else { return }

        let retainedWindow = window

        DispatchQueue.main.async {
            // 保持窗口最大化，不调整大小
            retainedWindow.zoom(nil)

            retainedWindow.level = .normal
            retainedWindow.collectionBehavior = []
            retainedWindow.isMovable = true
            retainedWindow.isOpaque = true
            retainedWindow.backgroundColor = NSColor.windowBackgroundColor
            retainedWindow.ignoresMouseEvents = false

            NSApp.presentationOptions = []

            // 检查是否开启了后台模式
            if !timerManager.isBackgroundMode {
                // 非后台模式下，将窗口置于前台并激活应用
                retainedWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                // 后台模式下，只恢复窗口状态但不置于前台
                retainedWindow.orderOut(nil)
            }
        }
    }

    private func lockScreen() {
        let service = "com.apple.screensaver"
        let selector = sel_registerName("lock")

        if let screenSaver = NSClassFromString(service) {
            if (screenSaver as AnyObject).responds(to: selector) {
                let _ = (screenSaver as AnyObject).perform(selector)
            } else {
                fallbackLockScreen()
            }
        } else {
            fallbackLockScreen()
        }
    }

    private func fallbackLockScreen() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]

        do {
            try task.run()
        } catch {
            print("Failed to lock screen with fallback method: \(error)")
        }
    }
}
