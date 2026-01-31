import SwiftUI
import GRDB

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    @State private var allSettings: [AppSetting] = []
    @State private var selectedSettingId: Int64?
    @State private var isEditingWorkTime: Bool = false
    @State private var isEditingRestTime: Bool = false
    @State private var workTimeMinutes: Int = 45
    @State private var restTimeMinutes: Int = 5
    @State private var newSettingName: String = ""
    @State private var showSaveOptions: Bool = false
    @State private var saveOption: SaveOption = .override
    // 使用TimerManager中的isBackgroundMode状态，不再使用局部状态
    
    @FocusState private var focusedField: FocusField?
    
    enum SaveOption {
        case override
        case new
    }
    
    enum FocusField: Hashable {
        case workTime
        case restTime
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
                .onChange(of: selectedSettingId) { _ in
                    if let id = selectedSettingId,
                       let setting = allSettings.first(where: { $0.id == id }) {
                        timerManager.workTime = setting.workTime
                        timerManager.restTime = setting.restTime
                        timerManager.currentTime = timerManager.workTime
                        workTimeMinutes = setting.workTime / 60
                        restTimeMinutes = setting.restTime / 60
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
                    TextField("", value: $workTimeMinutes, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .workTime)
                        .onSubmit {
                            timerManager.updateWorkTime(workTimeMinutes)
                            isEditingWorkTime = false
                            focusedField = nil
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .workTime
                            }
                        }
                } else {
                    Text("\(timerManager.workTime / 60) 分钟")
                        .font(.subheadline)
                        .frame(width: 100)
                }
                
                Button(action: {
                    isEditingWorkTime.toggle()
                    if isEditingWorkTime {
                        workTimeMinutes = timerManager.workTime / 60
                    }
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                
                Stepper(value: Binding(
                    get: { timerManager.workTime / 60 },
                    set: { timerManager.updateWorkTime($0) }
                ), in: 1...60, step: 1) {
                    EmptyView()
                }
                .labelsHidden()
            }
            
            HStack(spacing: 10) {
                Text("休息时间:")
                    .font(.subheadline)
                
                if isEditingRestTime {
                    TextField("", value: $restTimeMinutes, formatter: NumberFormatter())
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .restTime)
                        .onSubmit {
                            timerManager.updateRestTime(restTimeMinutes)
                            isEditingRestTime = false
                            focusedField = nil
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .restTime
                            }
                        }
                } else {
                    Text("\(timerManager.restTime / 60) 分钟")
                        .font(.subheadline)
                        .frame(width: 100)
                }
                
                Button(action: {
                    isEditingRestTime.toggle()
                    if isEditingRestTime {
                        restTimeMinutes = timerManager.restTime / 60
                    }
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                
                Stepper(value: Binding(
                    get: { timerManager.restTime / 60 },
                    set: { timerManager.updateRestTime($0) }
                ), in: 1...10, step: 1) {
                    EmptyView()
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
                if let current = try SettingsManager.shared.getCurrentSettings() {
                    selectedSettingId = current.id
                }
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
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
