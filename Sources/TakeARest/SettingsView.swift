import SwiftUI
import GRDB

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    @State private var allSettings: [AppSetting] = []
    @State private var selectedSettingId: Int64?
    @State private var isEditingWorkTime: Bool = false
    @State private var isEditingRestTime: Bool = false
    @State private var workTimeMinutes: Int = 45
    @State private var workTimeSeconds: Int = 0
    @State private var restTimeMinutes: Int = 5
    @State private var restTimeSeconds: Int = 0
    @State private var newSettingName: String = ""
    @State private var showSaveOptions: Bool = false
    @State private var saveOption: SaveOption = .override
    // 使用TimerManager中的isBackgroundMode状态，不再使用局部状态
    
    @FocusState private var focusedField: FocusField?
    
    // 创建NumberFormatter属性
    // 秒数Formatter
    private let secondsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0
        formatter.maximum = 59
        return formatter
    }()
    
    private let workTimeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0
        formatter.maximum = 60
        return formatter
    }()
    
    private let restTimeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0
        formatter.maximum = 10
        return formatter
    }()
    
    enum SaveOption {
        case override
        case new
    }
    
    enum FocusField: Hashable {
        case workTimeMinutes
        case workTimeSeconds
        case restTimeMinutes
        case restTimeSeconds
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("设置管理")
                .font(.headline)
                .padding(.top, 10)
            
            // 设置选择器
            if !allSettings.isEmpty {
                Picker(selection: $selectedSettingId, label: Text("选择设置:")) {
                    ForEach(allSettings) { setting in
                        Text(setting.name)
                            .tag(setting.id as Int64?)
                    }
                }
                .frame(width: 300)
                .onChange(of: selectedSettingId) { newValue in
                    if let id = newValue,
                       let setting = allSettings.first(where: { $0.id == id }) {
                        timerManager.workTime = setting.workTime
                        timerManager.restTime = setting.restTime
                        timerManager.currentTime = timerManager.workTime
                        workTimeMinutes = setting.workTime / 60
                        workTimeSeconds = setting.workTime % 60
                        restTimeMinutes = setting.restTime / 60
                        restTimeSeconds = setting.restTime % 60
                        // 保存上次选择的设置ID和当前时间设置
                        SettingsManager.shared.saveLastSelectedSettingId(id)
                        SettingsManager.shared.saveCurrentTimeSettings(workTime: setting.workTime, restTime: setting.restTime)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // 时间显示和编辑
            timeDisplaySection
            
            Divider()
                .padding(.vertical, 10)
            
            // 后台模式开关
            Toggle("工作模式下后台运行", isOn: $timerManager.isBackgroundMode)
                .padding(.horizontal, 40)
                .onChange(of: timerManager.isBackgroundMode, perform: { _ in
                    updateWindowLeveling()
                })
            
            Divider()
                .padding(.vertical, 10)
            
            // 操作按钮
            actionButtons
        }
        .padding(.horizontal, 40)
        .onAppear {
            loadAllSettings()
        }
        .sheet(isPresented: $showSaveOptions) {
            saveOptionsSheet
        }
    }
    
    private var timeDisplaySection: some View {
        VStack(spacing: 15) {
            HStack(spacing: 10) {
                Text("工作时间:")
                    .font(.subheadline)
                
                if isEditingWorkTime {
                    HStack(spacing: 5) {
                        TextField("", value: $workTimeMinutes, formatter: workTimeFormatter)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .workTimeMinutes)
                            .onSubmit {
                                // 移动焦点到秒数输入框
                                focusedField = .workTimeSeconds
                            }
                        
                        Text(":")
                            .font(.subheadline)
                        
                        TextField("", value: $workTimeSeconds, formatter: secondsFormatter)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .workTimeSeconds)
                            .onSubmit {
                                updateWorkTime()
                                isEditingWorkTime = false
                                focusedField = nil
                            }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .workTimeMinutes
                        }
                    }
                } else {
                    Text(timerManager.formattedTimeFromSeconds(timerManager.workTime))
                        .font(.subheadline)
                        .frame(width: 100)
                }
                
                Button(action: {
                    isEditingWorkTime.toggle()
                    if isEditingWorkTime {
                        workTimeMinutes = timerManager.workTime / 60
                        workTimeSeconds = timerManager.workTime % 60
                    }
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                
                // 分钟调整器
                Stepper(value: Binding(
                    get: { timerManager.workTime / 60 },
                    set: { newValue in
                        let seconds = timerManager.workTime % 60
                        timerManager.workTime = newValue * 60 + seconds
                        // 更新本地状态变量
                        workTimeMinutes = newValue
                        // 保存当前时间设置
                        SettingsManager.shared.saveCurrentTimeSettings(workTime: timerManager.workTime, restTime: timerManager.restTime)
                    }
                ), in: 0...60, step: 1) {
                    Text("分钟")
                }
                .labelsHidden()
                
                // 秒数调整器
                Stepper(value: Binding(
                    get: { timerManager.workTime % 60 },
                    set: { newValue in
                        let minutes = timerManager.workTime / 60
                        timerManager.workTime = minutes * 60 + newValue
                        // 更新本地状态变量
                        workTimeSeconds = newValue
                        // 保存当前时间设置
                        SettingsManager.shared.saveCurrentTimeSettings(workTime: timerManager.workTime, restTime: timerManager.restTime)
                    }
                ), in: 0...59, step: 1) {
                    Text("秒")
                }
                .labelsHidden()
            }
            
            HStack(spacing: 10) {
                Text("休息时间:")
                    .font(.subheadline)
                
                if isEditingRestTime {
                    HStack(spacing: 5) {
                        TextField("", value: $restTimeMinutes, formatter: restTimeFormatter)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .restTimeMinutes)
                            .onSubmit {
                                // 移动焦点到秒数输入框
                                focusedField = .restTimeSeconds
                            }
                        
                        Text(":")
                            .font(.subheadline)
                        
                        TextField("", value: $restTimeSeconds, formatter: secondsFormatter)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .restTimeSeconds)
                            .onSubmit {
                                updateRestTime()
                                isEditingRestTime = false
                                focusedField = nil
                            }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .restTimeMinutes
                        }
                    }
                } else {
                    Text(timerManager.formattedTimeFromSeconds(timerManager.restTime))
                        .font(.subheadline)
                        .frame(width: 100)
                }
                
                Button(action: {
                    isEditingRestTime.toggle()
                    if isEditingRestTime {
                        restTimeMinutes = timerManager.restTime / 60
                        restTimeSeconds = timerManager.restTime % 60
                    }
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                
                // 分钟调整器
                Stepper(value: Binding(
                    get: { timerManager.restTime / 60 },
                    set: { newValue in
                        let seconds = timerManager.restTime % 60
                        timerManager.restTime = newValue * 60 + seconds
                        // 更新本地状态变量
                        restTimeMinutes = newValue
                        // 保存当前时间设置
                        SettingsManager.shared.saveCurrentTimeSettings(workTime: timerManager.workTime, restTime: timerManager.restTime)
                    }
                ), in: 0...10, step: 1) {
                    Text("分钟")
                }
                .labelsHidden()
                
                // 秒数调整器
                Stepper(value: Binding(
                    get: { timerManager.restTime % 60 },
                    set: { newValue in
                        let minutes = timerManager.restTime / 60
                        timerManager.restTime = minutes * 60 + newValue
                        // 更新本地状态变量
                        restTimeSeconds = newValue
                        // 保存当前时间设置
                        SettingsManager.shared.saveCurrentTimeSettings(workTime: timerManager.workTime, restTime: timerManager.restTime)
                    }
                ), in: 0...59, step: 1) {
                    Text("秒")
                }
                .labelsHidden()
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button("使用") {
                timerManager.resetTimer()
            }
            .buttonStyle(.borderedProminent)
            .frame(width: 100, height: 40)
            
            Button("保存") {
                if let id = selectedSettingId,
                   let setting = allSettings.first(where: { $0.id == id }),
                   setting.isSystemPreset {
                    saveOption = .new
                    showSaveOptions = true
                } else {
                    showSaveOptions = true
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(width: 100, height: 40)
        }
    }
    
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
                    saveSettings()
                    showSaveOptions = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 300, height: saveOption == .new ? 250 : 180)
    }
    
    private func loadAllSettings() {
        do {
            allSettings = try SettingsManager.shared.getAllSettings()
            if selectedSettingId == nil {
                // 首先尝试恢复上次选择的设置
                if let lastId = SettingsManager.shared.getLastSelectedSettingId() {
                    selectedSettingId = lastId
                } else if let current = try SettingsManager.shared.getCurrentSettings() {
                    selectedSettingId = current.id
                }
            }
            // 如果恢复的ID在当前设置列表中不存在，则使用默认设置
            if selectedSettingId != nil && !allSettings.contains(where: { $0.id == selectedSettingId }) {
                if let defaultSetting = allSettings.first(where: { $0.name == "我的默认配置" }) {
                    selectedSettingId = defaultSetting.id
                    SettingsManager.shared.saveLastSelectedSettingId(defaultSetting.id)
                }
            }
            
            // 始终使用当前timerManager的设置
            workTimeMinutes = timerManager.workTime / 60
            workTimeSeconds = timerManager.workTime % 60
            restTimeMinutes = timerManager.restTime / 60
            restTimeSeconds = timerManager.restTime % 60
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    // 更新工作时间（分钟+秒）
    private func updateWorkTime() {
        let totalSeconds = workTimeMinutes * 60 + workTimeSeconds
        // 确保至少1秒
        let adjustedSeconds = max(totalSeconds, 1)
        timerManager.workTime = adjustedSeconds
        // 同步更新本地状态
        workTimeMinutes = adjustedSeconds / 60
        workTimeSeconds = adjustedSeconds % 60
        // 保存当前时间设置
        SettingsManager.shared.saveCurrentTimeSettings(workTime: timerManager.workTime, restTime: timerManager.restTime)
    }
    
    // 更新休息时间（分钟+秒）
    private func updateRestTime() {
        let totalSeconds = restTimeMinutes * 60 + restTimeSeconds
        // 确保至少1秒
        let adjustedSeconds = max(totalSeconds, 1)
        timerManager.restTime = adjustedSeconds
        // 同步更新本地状态
        restTimeMinutes = adjustedSeconds / 60
        restTimeSeconds = adjustedSeconds % 60
        // 保存当前时间设置
        SettingsManager.shared.saveCurrentTimeSettings(workTime: timerManager.workTime, restTime: timerManager.restTime)
    }
    
    private func saveSettings() {
        do {
            if saveOption == .override {
                if let id = selectedSettingId,
                    let setting = allSettings.first(where: { $0.id == id }) {
                    try SettingsManager.shared.saveSettings(
                        id: id,
                        name: setting.name,
                        workTime: timerManager.workTime,
                        restTime: timerManager.restTime,
                        isSystemPreset: setting.isSystemPreset
                    )
                }
            } else {
                if !newSettingName.trimmingCharacters(in: .whitespaces).isEmpty {
                    let settings = try SettingsManager.shared.getAllSettings()
                    if !settings.contains(where: { $0.name == newSettingName }) {
                        try SettingsManager.shared.saveSettings(
                            id: nil,
                            name: newSettingName,
                            workTime: timerManager.workTime,
                            restTime: timerManager.restTime,
                            isSystemPreset: false
                        )
                        
                        loadAllSettings()
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
    }
    
    private func updateWindowLeveling() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        let retainedWindow = window
        
        DispatchQueue.main.async {
            if self.timerManager.isBackgroundMode {
                retainedWindow.orderOut(nil)
            } else {
                retainedWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
