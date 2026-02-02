import AppKit
import CoreData
import Foundation

/// 计时器管理类 - 处理工作/休息周期
/// 使用 Timer 在主线程上驱动状态更新
final class TimerState: ObservableObject {
    @Published var workTime: Int = TimeConstants.defaultWorkTime
    @Published var restTime: Int = TimeConstants.defaultRestTime
    @Published var currentTime: Int = TimeConstants.defaultWorkTime
    @Published var isWorking: Bool = true
    @Published var isPaused: Bool = false
    @Published var showRestModal: Bool = false
    @Published var isBackgroundMode: Bool = false

    private var timer: Timer?
    private var isSwitchingMode: Bool = false
    // 用于记录是否因为系统锁屏自动暂停
    private var autoPausedByLock: Bool = false
    // 会话观察者改为 selector-based 注册，不再需要保存令牌

    init() {
        // 使用默认设置初始化，不启动计时器
        self.workTime = TimeConstants.defaultWorkTime
        self.restTime = TimeConstants.defaultRestTime
        self.currentTime = self.workTime

        // 注意：计时器将在 ContentView.onAppear 中调用 loadUserSettings() 时启动
        // 监听来自菜单栏的 toggle pause 通知（使用 selector 来避免捕获 self）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTogglePauseNotification(_:)),
            name: Notification.Name("TakeARest.TogglePause"),
            object: nil
        )

        // 广播初始 pause 状态，便于菜单栏同步
        NotificationCenter.default.post(
            name: Notification.Name("TakeARest.PauseStateChanged"), object: nil,
            userInfo: ["isPaused": isPaused])

        // 监听系统会话（锁屏/解锁）事件（使用 selector 来避免捕获 self）
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSessionDidResignNotification(_:)),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSessionDidBecomeActiveNotification(_:)),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )
    }

    /// 从 UserDefaults 和 Core Data 加载用户设置
    func loadUserSettings() {
        stopTimer()

        // 首先尝试从UserDefaults获取保存的时间设置
        if let (savedWorkTime, savedRestTime) = SettingsStorage.shared.getCurrentTimeSettings() {
            updateSettings(workTime: savedWorkTime, restTime: savedRestTime)
            startTimer()
            return
        }

        var loadedWorkTime = TimeConstants.defaultWorkTime
        var loadedRestTime = TimeConstants.defaultRestTime

        // 如果没有保存的时间设置，尝试从数据库获取上次选择的配置
        do {
            if let lastSelectedId = SettingsStorage.shared.getLastSelectedSettingId() {
                let allSettings = try SettingsStorage.shared.getAllSettings()
                if let setting = allSettings.first(where: { $0.id == lastSelectedId }) {
                    loadedWorkTime = setting.workTime
                    loadedRestTime = setting.restTime
                }
            }
        } catch {
            print("⚠️ Failed to load user settings: \(error)")
        }

        // 更新属性并保存到 UserDefaults
        updateSettings(workTime: loadedWorkTime, restTime: loadedRestTime)
        SettingsStorage.shared.saveCurrentTimeSettings(
            workTime: loadedWorkTime, restTime: loadedRestTime)

        startTimer()
    }

    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - 私有方法
    private func startTimer() {
        stopTimer()
        // 使用 selector-based 的 Timer，避免在 @Sendable 闭包中捕获 self
        timer = Timer.scheduledTimer(
            timeInterval: 1, target: self, selector: #selector(handleTimerDidFire(_:)),
            userInfo: nil, repeats: true)
    }

    // MARK: - Selector handlers (@objc entry points)
    // These handlers are intentionally minimal: they bridge Objective-C timers/notifications
    // into Swift methods without capturing `self` inside @Sendable closures.
    @objc private func handleTimerDidFire(_ timer: Timer) {
        timerTick()
    }

    @objc private func handleTogglePauseNotification(_ notification: Notification) {
        togglePause()
    }

    @objc private func handleSessionDidResignNotification(_ notification: Notification) {
        handleSessionResign()
    }

    @objc private func handleSessionDidBecomeActiveNotification(_ notification: Notification) {
        handleSessionBecomeActive()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateSettings(workTime: Int, restTime: Int) {
        self.workTime = workTime
        self.restTime = restTime
        self.currentTime = workTime
        self.isWorking = true
        self.showRestModal = false
    }
    // MARK: - 计时器回调
    private func timerTick() {
        // 直接在主线程更新状态
        if !isPaused && currentTime > 0 {
            currentTime -= 1
        } else if !isPaused && currentTime == 0 && !isSwitchingMode {
            // 防止重复调用 switchMode()
            isSwitchingMode = true
            defer { isSwitchingMode = false }

            stopTimer()

            // 如果是工作模式结束，显示休息模态框并设置休息时间
            if isWorking {
                isWorking = false
                currentTime = max(restTime, 1)
                showRestModal = true
            } else {
                // 如果是休息模式结束，自动切换回工作模式
                isWorking = true
                currentTime = max(workTime, 1)
                showRestModal = false
            }

            startTimer()
        }
    }

    // MARK: - 公开方法
    /// 切换工作/休息模式
    func switchMode() {
        isSwitchingMode = true
        defer { isSwitchingMode = false }

        isWorking.toggle()
        currentTime = isWorking ? max(workTime, 1) : max(restTime, 1)
        showRestModal = !isWorking
    }

    /// 切换暂停/继续
    func togglePause() {
        isPaused.toggle()
        NotificationCenter.default.post(
            name: Notification.Name("TakeARest.PauseStateChanged"), object: nil,
            userInfo: ["isPaused": isPaused])
    }

    // 系统会话：注销/锁屏 事件处理
    private func handleSessionResign() {
        // 仅在工作模式下关注锁屏，且只有在当前未暂停时才由系统自动暂停
        if isWorking && !isPaused {
            isPaused = true
            autoPausedByLock = true
            NotificationCenter.default.post(
                name: Notification.Name("TakeARest.PauseStateChanged"), object: nil,
                userInfo: ["isPaused": isPaused])
        }
    }

    // 系统会话：恢复/解锁 事件处理
    private func handleSessionBecomeActive() {
        // 仅当之前是自动因为锁屏而暂停，才恢复
        if autoPausedByLock {
            isPaused = false
            autoPausedByLock = false
            NotificationCenter.default.post(
                name: Notification.Name("TakeARest.PauseStateChanged"), object: nil,
                userInfo: ["isPaused": isPaused])
        }
    }

    /// 重置计时器
    func resetTimer() {
        isWorking = true
        isPaused = false
        currentTime = workTime
        showRestModal = false
        NotificationCenter.default.post(
            name: Notification.Name("TakeARest.PauseStateChanged"), object: nil,
            userInfo: ["isPaused": isPaused])
    }

    /// 直接设置工作时间（秒）
    func setWorkTime(_ seconds: Int) {
        workTime = seconds
        if isWorking {
            currentTime = seconds
        }
        SettingsStorage.shared.saveCurrentTimeSettings(workTime: workTime, restTime: restTime)
    }

    /// 直接设置休息时间（秒）
    func setRestTime(_ seconds: Int) {
        restTime = seconds
        if !isWorking {
            currentTime = seconds
        }
        SettingsStorage.shared.saveCurrentTimeSettings(workTime: workTime, restTime: restTime)
    }

    /// 格式化当前时间为 MM:SS
    func formattedTime() -> String {
        formattedTimeFromSeconds(currentTime)
    }

    /// 将秒数格式化为 MM:SS
    func formattedTimeFromSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// 移除 @objc timerTick 方法
