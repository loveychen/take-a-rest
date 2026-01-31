import Foundation

class TimerManager: ObservableObject {
    @Published var workTime: Int = 45 * 60
    @Published var restTime: Int = 5 * 60
    @Published var currentTime: Int = 2700
    @Published var isWorking: Bool = true
    @Published var isPaused: Bool = false
    @Published var showRestModal: Bool = false
    @Published var isBackgroundMode: Bool = false
    
    private var timer: Timer?
    
    init() {
        // 简单初始化，使用默认设置
        self.workTime = 45 * 60
        self.restTime = 5 * 60
        self.currentTime = self.workTime
        
        // 启动计时器
        startTimer()
    }
    
    @MainActor func loadUserSettings() {
        // 首先尝试从UserDefaults获取保存的时间设置
        if let (savedWorkTime, savedRestTime) = SettingsManager.shared.getCurrentTimeSettings() {
            self.workTime = savedWorkTime
            self.restTime = savedRestTime
            self.currentTime = self.workTime
        } else {
            // 如果没有保存的时间设置，尝试从数据库获取上次选择的配置
            do {
                if let lastSelectedId = SettingsManager.shared.getLastSelectedSettingId() {
                    let allSettings = try SettingsManager.shared.getAllSettings()
                    if let setting = allSettings.first(where: { $0.id == lastSelectedId }) {
                        self.workTime = setting.workTime
                        self.restTime = setting.restTime
                        self.currentTime = self.workTime
                        // 同时保存到UserDefaults
                        SettingsManager.shared.saveCurrentTimeSettings(workTime: self.workTime, restTime: self.restTime)
                        return
                    }
                }
                
                // 如果以上都失败，使用默认设置
                self.workTime = 45 * 60
                self.restTime = 5 * 60
                self.currentTime = self.workTime
            } catch {
                print("Failed to load user settings: \(error)")
                // 发生错误时使用默认设置
                self.workTime = 45 * 60
                self.restTime = 5 * 60
                self.currentTime = self.workTime
            }
        }
    }
    
    deinit {
        stopTimer()
    }
    
    private func startTimer() {
        stopTimer()
        
        // 使用传统Timer，确保在主线程运行
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func timerTick() {
        // 直接在主线程更新状态
        if !isPaused && currentTime > 0 {
            currentTime -= 1
        } else if currentTime <= 0 {
            switchMode()
        }
    }
    
    func switchMode() {
        isWorking.toggle()
        currentTime = isWorking ? workTime : restTime
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
    }
    
    // 直接设置休息时间（秒）
    func setRestTime(_ seconds: Int) {
        restTime = seconds
        if !isWorking {
            currentTime = seconds
        }
    }
    

    
    func formattedTime() -> String {
        let minutes = currentTime / 60
        let seconds = currentTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formattedTimeFromSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
