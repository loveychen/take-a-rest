import SwiftUI
import AppKit

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
                        timerManager.isWorking = true
                        timerManager.currentTime = timerManager.workTime
                        updateWindowToNormal()
                        // 延迟设置showRestModal为false，确保窗口状态已恢复
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            timerManager.showRestModal = false
                        }
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
            
            // 保持窗口最大化，不调整大小
            retainedWindow.zoom(nil)
            
            retainedWindow.level = .screenSaver
            retainedWindow.collectionBehavior = [.canJoinAllSpaces]
            retainedWindow.isMovable = false
            retainedWindow.isOpaque = false
            retainedWindow.backgroundColor = NSColor.clear
            retainedWindow.ignoresMouseEvents = false
            
            NSApp.presentationOptions = []
            
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