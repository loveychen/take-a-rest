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
    
    func updateWorkTime(_ minutes: Int) {
        workTime = minutes * 60
        if isWorking {
            currentTime = workTime
        }
    }
    
    func updateRestTime(_ minutes: Int) {
        restTime = minutes * 60
        if !isWorking {
            currentTime = restTime
        }
    }
    

    
    func formattedTime() -> String {
        let minutes = currentTime / 60
        let seconds = currentTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
