import CoreData
import Foundation

class TimerManager: ObservableObject {
    @Published var workTime: Int = TimeConstants.defaultWorkTime
    @Published var restTime: Int = TimeConstants.defaultRestTime
    @Published var currentTime: Int = TimeConstants.defaultWorkTime
    @Published var isWorking: Bool = true
    @Published var isPaused: Bool = false
    @Published var showRestModal: Bool = false
    @Published var isBackgroundMode: Bool = false

    private var timer: Timer?
    private var isSwitchingMode: Bool = false  // 防止重复切换模式的标志位

    init() {
        // 使用默认设置初始化，不启动计时器
        self.workTime = TimeConstants.defaultWorkTime
        self.restTime = TimeConstants.defaultRestTime
        self.currentTime = self.workTime

        // 注意：计时器将在 ContentView.onAppear 中调用 loadUserSettings() 时启动
        // 这样可以确保只启动一次，并且在加载用户设置后启动
    }

    func loadUserSettings() {
        // 停止计时器
        stopTimer()

        // 首先尝试从UserDefaults获取保存的时间设置
        if let (savedWorkTime, savedRestTime) = SettingsManager.shared.getCurrentTimeSettings() {
            self.workTime = savedWorkTime
            self.restTime = savedRestTime
            self.currentTime = savedWorkTime
            self.isWorking = true
            self.showRestModal = false
            self.startTimer()
            return
        }

        // 标志位，记录是否需要保存设置到UserDefaults
        var needSaveToUserDefaults = false
        var loadedWorkTime = TimeConstants.defaultWorkTime
        var loadedRestTime = TimeConstants.defaultRestTime

        // 如果没有保存的时间设置，尝试从数据库获取上次选择的配置
        do {
            if let lastSelectedId = SettingsManager.shared.getLastSelectedSettingId() {
                let allSettings = try SettingsManager.shared.getAllSettings()
                if let setting = allSettings.first(where: { $0.id == lastSelectedId }) {
                    loadedWorkTime = setting.workTime
                    loadedRestTime = setting.restTime
                } else {
                    // 没有找到对应的配置，使用默认设置
                    needSaveToUserDefaults = true
                }
            } else {
                // 没有上次选择的配置ID，使用默认设置
                needSaveToUserDefaults = true
            }
        } catch {
            print("Failed to load user settings: \(error)")
            needSaveToUserDefaults = true
        }

        // 更新属性
        self.workTime = loadedWorkTime
        self.restTime = loadedRestTime
        self.currentTime = loadedWorkTime
        self.isWorking = true
        self.showRestModal = false

        // 如果需要，保存设置到UserDefaults
        if needSaveToUserDefaults {
            SettingsManager.shared.saveCurrentTimeSettings(
                workTime: loadedWorkTime, restTime: loadedRestTime)
        }

        // 启动计时器
        self.startTimer()
    }

    deinit {
        stopTimer()
    }

    private func startTimer() {
        stopTimer()

        // 使用传统Timer，确保在主线程运行
        timer = Timer.scheduledTimer(
            timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil,
            repeats: true)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func timerTick() {
        // 直接在主线程更新状态
        if !isPaused && currentTime > 0 {
            currentTime -= 1
        } else if !isPaused && currentTime == 0 && !isSwitchingMode {
            // 防止重复调用switchMode()
            isSwitchingMode = true
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

            isSwitchingMode = false
            startTimer()
        }
    }

    func switchMode() {
        // 设置标志位，防止重复调用
        isSwitchingMode = true
        defer { isSwitchingMode = false }  // 确保标志位最终会被重置

        isWorking.toggle()
        // 确保currentTime被正确设置为正数
        currentTime = isWorking ? max(workTime, 1) : max(restTime, 1)
        showRestModal = !isWorking
    }

    func togglePause() {
        isPaused.toggle()
    }

    func resetTimer() {
        isWorking = true
        isPaused = false
        currentTime = workTime
        showRestModal = false
    }

    // 直接设置工作时间（秒）
    func setWorkTime(_ seconds: Int) {
        workTime = seconds
        if isWorking {
            currentTime = seconds
        }
        // 保存设置到UserDefaults
        SettingsManager.shared.saveCurrentTimeSettings(workTime: workTime, restTime: restTime)
    }

    // 直接设置休息时间（秒）
    func setRestTime(_ seconds: Int) {
        restTime = seconds
        if !isWorking {
            currentTime = seconds
        }
        // 保存设置到UserDefaults
        SettingsManager.shared.saveCurrentTimeSettings(workTime: workTime, restTime: restTime)
    }

    func formattedTime() -> String {
        return formattedTimeFromSeconds(currentTime)
    }

    func formattedTimeFromSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
