import SwiftUI
import AppKit
import GRDB

struct ContentView: View {
    @State private var workTime: Int = 45 * 60 // 秒（统一以秒存储）
    @State private var restTime: Int = 5 * 60 // 秒（统一以秒存储）
    @State private var currentTime: Int = 2700 // 秒（内部计算使用）
    @State private var isWorking: Bool = true
    @State private var isPaused: Bool = false
    @State private var selectedTab: Tab = .main
    @State private var showRestModal: Bool = false
    
    // 设置相关状态
    @State private var allSettings: [AppSetting] = []
    @State private var selectedSettingId: Int64?
    @State private var isEditingWorkTime: Bool = false
    @State private var isEditingRestTime: Bool = false
    @State private var workTimeMinutes: Int = 45 // 用于编辑模式的分钟数
    @State private var restTimeMinutes: Int = 5 // 用于编辑模式的分钟数
    @State private var newSettingName: String = ""
    @State private var showSaveOptions: Bool = false
    @State private var saveOption: SaveOption = .override
    @State private var isBackgroundMode: Bool = false // 后台模式开关
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum Tab: String {
        case main = "主界面"
        case settings = "设置"
    }
    
    enum SaveOption {
        case override
        case new
    }
    
    // 焦点状态管理
    @FocusState private var focusedField: FocusField?
    
    enum FocusField: Hashable {
        case workTime
        case restTime
    }
    
    // 主界面内容
    private var mainView: some View {
        VStack(spacing: 20) {
            Text(formattedTime(time: currentTime))
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.red)
                .padding()
            
            ProgressView(value: Double(currentTime), total: Double(isWorking ? workTime : restTime))
                .frame(height: 10)
                .padding(.horizontal, 40)
                .progressViewStyle(LinearProgressViewStyle(tint: isWorking ? .red : .green))
            
            HStack {
                Text("工作中")
                    .font(.headline)
            }
            .padding(.bottom, 10)
        }
    }
    
    // 设置界面内容
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("设置管理")
                .font(.headline)
                .padding(.top, 10)
            
            // 1. 下拉框选择设置
            if !allSettings.isEmpty {
                Picker(selection: $selectedSettingId, label: Text("选择设置:")) {
                    ForEach(allSettings) { setting in
                        Text(setting.name)
                            .tag(setting.id as Int64?)
                    }
                }
                .frame(width: 300)
                .onChange(of: selectedSettingId) { _ in
                    if let id = selectedSettingId,
                       let setting = allSettings.first(where: { $0.id == id }) {
                        workTime = setting.workTime
                        restTime = setting.restTime
                        currentTime = workTime
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // 2. 时间展示框
            timeDisplaySection
            
            Divider()
                .padding(.vertical, 10)
            
            // 4. 后台模式开关
            Toggle("工作模式下后台运行", isOn: $isBackgroundMode)
                .padding(.horizontal, 40)
                .onChange(of: isBackgroundMode) { _ in
                    updateWindowLeveling()
                }
            
            Divider()
                .padding(.vertical, 10)
            
            // 5. 使用和保存按钮
            actionButtons
        }
        .padding(.horizontal, 40)
        .onAppear {
            // 加载所有设置
            do {
                allSettings = try SettingsManager.shared.getAllSettings()
                // 只有在没有选择设置时，才从数据库加载当前设置
                if selectedSettingId == nil {
                    if let current = try SettingsManager.shared.getCurrentSettings() {
                        selectedSettingId = current.id
                        workTime = current.workTime
                        restTime = current.restTime
                    }
                } else {
                    // 如果已经有选择的设置ID，确保时间值与当前选择的设置一致
                    // 这里不需要强制更新时间值，因为用户可能已经手动修改了时间
                    // 只有当用户重新选择设置时，才会更新时间值
                }
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
        .sheet(isPresented: $showSaveOptions) {
            // 保存选项弹窗
            saveOptionsSheet
        }
    }
    
    // 时间展示部分
    private var timeDisplaySection: some View {
        VStack(spacing: 15) {
            HStack(spacing: 10) {
                Text("工作时间:")
                    .font(.subheadline)
                
                if isEditingWorkTime {
                    // 编辑模式下显示分钟，存储为秒
                    TextField("", value: $workTimeMinutes, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .workTime)
                        .onSubmit {
                            workTime = workTimeMinutes * 60
                            isEditingWorkTime = false
                            focusedField = nil
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .workTime
                            }
                        }
                } else {
                    Text("\(workTime / 60) 分钟")
                        .font(.subheadline)
                        .frame(width: 100)
                }
                
                Button(action: {
                    isEditingWorkTime.toggle()
                    if isEditingWorkTime {
                        // 进入编辑模式时，将当前秒数转换为分钟
                        workTimeMinutes = workTime / 60
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .workTime
                        }
                    }
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                
                Stepper(value: $workTime, in: 60...3600, step: 60) {
                    EmptyView()
                }
                .labelsHidden()
            }
            
            HStack(spacing: 10) {
                Text("休息时间:")
                    .font(.subheadline)
                
                if isEditingRestTime {
                    // 编辑模式下显示分钟，存储为秒
                    TextField("", value: $restTimeMinutes, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .restTime)
                        .onSubmit {
                            restTime = restTimeMinutes * 60
                            isEditingRestTime = false
                            focusedField = nil
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .restTime
                            }
                        }
                } else {
                    Text("\(restTime / 60) 分钟")
                        .font(.subheadline)
                        .frame(width: 100)
                }
                
                Button(action: {
                    isEditingRestTime.toggle()
                    if isEditingRestTime {
                        // 进入编辑模式时，将当前秒数转换为分钟
                        restTimeMinutes = restTime / 60
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .restTime
                        }
                    }
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                
                Stepper(value: $restTime, in: 60...600, step: 60) {
                    EmptyView()
                }
                .labelsHidden()
            }
        }
    }
    
    // 操作按钮部分
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button("使用") {
            // 切换到当前设置的工作时间和休息时间，但不保存到数据库
            isWorking = true
            isPaused = false
            currentTime = workTime
            showRestModal = false
        }
            .buttonStyle(.borderedProminent)
            .frame(width: 100, height: 40)
            
            Button("保存") {
                if let id = selectedSettingId,
                   let setting = allSettings.first(where: { $0.id == id }),
                   setting.isSystemPreset {
                    // 系统预设不能覆盖，直接选择新建
                    saveOption = .new
                    showSaveOptions = true
                } else {
                    // 显示保存选项
                    showSaveOptions = true
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(width: 100, height: 40)
        }
    }
    
    // 保存选项弹窗
    private var saveOptionsSheet: some View {
        VStack(spacing: 20) {
            Text("保存设置")
                .font(.headline)
            
            if saveOption == .new {
                TextField("输入设置名称", text: $newSettingName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)
            }
            
            HStack(spacing: 20) {
                if saveOption != .new {
                    Button("覆盖") {
                        saveOption = .override
                    }
                    .buttonStyle(.bordered)
                    .background(saveOption == .override ? Color.blue : Color.clear)
                    .foregroundColor(saveOption == .override ? .white : .primary)
                }
                
                Button("新建") {
                    saveOption = .new
                    newSettingName = ""
                }
                .buttonStyle(.bordered)
                .background(saveOption == .new ? Color.blue : Color.clear)
                .foregroundColor(saveOption == .new ? .white : .primary)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                Button("取消") {
                    showSaveOptions = false
                }
                .buttonStyle(.bordered)
                
                Button("确认") {
                    do {
                        if saveOption == .override {
                            // 覆盖当前设置
                            if let id = selectedSettingId,
                               let setting = allSettings.first(where: { $0.id == id }) {
                                try SettingsManager.shared.saveSettings(
                                    id: id,
                                    name: setting.name,
                                    workTime: workTime,
                                    restTime: restTime,
                                    isSystemPreset: setting.isSystemPreset
                                )
                            }
                        } else {
                            // 新建设置
                            if !newSettingName.trimmingCharacters(in: .whitespaces).isEmpty {
                                // 检查名称是否重复
                                let settings = try SettingsManager.shared.getAllSettings()
                                if !settings.contains(where: { $0.name == newSettingName }) {
                                    try SettingsManager.shared.saveSettings(
                                        id: nil,
                                        name: newSettingName,
                                        workTime: workTime,
                                        restTime: restTime,
                                        isSystemPreset: false
                                    )
                                    
                                    // 更新设置列表
                                    allSettings = try SettingsManager.shared.getAllSettings()
                                    if let newSetting = allSettings.first(where: { $0.name == newSettingName }) {
                                        selectedSettingId = newSetting.id
                                    }
                                } else {
                                    print("设置名称已存在")
                                }
                            }
                        }
                    } catch {
                        print("Failed to save settings: \(error)")
                    }
                    
                    showSaveOptions = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 300, height: saveOption == .new ? 250 : 180)
    }
    
    // 休息弹窗
    private var restModal: some View {
        VStack(spacing: 50) {
            Text("休息时间")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white)
            
            Text(formattedTime(time: currentTime))
                .font(.system(size: 120, weight: .bold))
                .foregroundColor(.green)
            
            HStack(spacing: 30) {
                Button("工作") {
                    showRestModal = false
                    isWorking = true
                    currentTime = workTime
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
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("TakeARest")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 20)
                
                HStack(spacing: 0) {
                    ForEach([Tab.main, Tab.settings], id: \.self) { tab in
                        Button(tab.rawValue) {
                            selectedTab = tab
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .blue : .primary)
                        .cornerRadius(8)
                    }
                }
                
                if selectedTab == .main {
                    mainView
                } else {
                    settingsView
                }
                
                HStack(spacing: 15) {
                    Button(isPaused ? "继续" : "暂停") {
                        isPaused.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("重置") {
                        resetTimer()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("退出") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.bottom, 20)
            }
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            
            if showRestModal {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                restModal
            }
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onChange(of: isWorking) { newValue in
            if !newValue {
                showRestModal = true
                // 延迟调用updateWindowLeveling，避免立即激活应用
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updateWindowLeveling()
                    // 显式地将应用程序置于非活动状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NSApp.deactivate()
                    }
                }
            } else {
                showRestModal = false
                updateWindowLeveling()
            }
        }
        .onChange(of: workTime) { newValue in
            currentTime = newValue
        }
        .onAppear {
            updateWindowLeveling()
            // 只在第一次加载时从数据库获取设置，如果已经有selectedSettingId则不覆盖
            if selectedSettingId == nil {
                do {
                    if let settings = try SettingsManager.shared.getCurrentSettings() {
                        workTime = settings.workTime
                        restTime = settings.restTime
                        currentTime = workTime
                    }
                } catch {
                    print("Failed to load settings: \(error)")
                }
            }
        }
    }
    
    private func updateTimer() {
        if !isPaused && currentTime > 0 {
            currentTime -= 1
        } else if currentTime <= 0 {
            switchMode()
        }
    }
    
    private func switchMode() {
        isWorking.toggle()
        currentTime = isWorking ? workTime : restTime
    }
    
    private func updateWindowLeveling() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // 保存窗口的引用，确保不会被释放
        let retainedWindow = window
        
        if showRestModal {
            // 休息模式处理
            DispatchQueue.main.async {
                if let screen = NSScreen.main {
                    let screenFrame = screen.frame
                    // 使用display: false来避免激活窗口
                    retainedWindow.setFrame(screenFrame, display: false)
                }
                
                // 使用screenSaver级别确保窗口可见
                retainedWindow.level = .screenSaver
                retainedWindow.collectionBehavior = [.canJoinAllSpaces]
                retainedWindow.isMovable = false
                retainedWindow.isOpaque = false
                retainedWindow.backgroundColor = NSColor.clear
                retainedWindow.ignoresMouseEvents = false
                
                // 设置窗口行为，允许看到其他应用界面
                // 不隐藏菜单栏和Dock，保持完整的系统UI可见
                NSApp.presentationOptions = []
            }
        } else {
            // 正常模式处理
            DispatchQueue.main.async {
                // 只在窗口还没有大小或者需要重置位置时设置大小和居中
                if retainedWindow.frame.size.width < 400 || retainedWindow.frame.size.height < 300 {
                    retainedWindow.setFrame(NSRect(x: 0, y: 0, width: 550, height: 350), display: false)
                    retainedWindow.center()
                }
                
                retainedWindow.level = .normal
                retainedWindow.collectionBehavior = []
                retainedWindow.isMovable = true
                retainedWindow.isOpaque = true
                retainedWindow.backgroundColor = NSColor.windowBackgroundColor
                retainedWindow.ignoresMouseEvents = false
                
                // 恢复正常行为
                NSApp.presentationOptions = []
                
                // 后台模式处理
                if self.isBackgroundMode {
                    // 隐藏窗口但保持应用运行
                    retainedWindow.orderOut(nil)
                } else {
                    // 恢复应用到前台
                    retainedWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    private func resetTimer() {
        isWorking = true
        isPaused = false
        currentTime = workTime
        showRestModal = false
    }
    
    private func lockScreen() {
        // 使用 CoreGraphics 直接调用系统锁屏，无需依赖 AppleScript
        let service = "com.apple.screensaver"
        let selector = sel_registerName("lock")
        
        if let screenSaver = NSClassFromString(service) {
            if (screenSaver as AnyObject).responds(to: selector) {
                let _ = (screenSaver as AnyObject).perform(selector)
            } else {
                // 如果失败，使用备用方案
                fallbackLockScreen()
            }
        } else {
            fallbackLockScreen()
        }
    }
    
    private func fallbackLockScreen() {
        // 备用方案：使用 pmset 使屏幕休眠
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        
        do {
            try task.run()
        } catch {
            print("Failed to lock screen with fallback method: \(error)")
        }
    }
    
    private func formattedTime(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
