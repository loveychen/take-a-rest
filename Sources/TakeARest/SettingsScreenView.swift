import CoreData
import SwiftUI

struct SettingsScreenView: View {
    @EnvironmentObject var timerManager: TimerState
    @State private var allSettings: [AppSetting] = []
    @State private var selectedSettingId: Int64?
    @State private var showSaveSheet = false
    @State private var newSettingName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 预设配置选择器
                presetsSection

                Divider()
                    .padding(.vertical, 8)

                // 时间调整卡片
                timingSection

                Divider()
                    .padding(.vertical, 8)

                // 选项开关
                optionsSection

                Divider()
                    .padding(.vertical, 8)

                // 保存按钮
                actionButtons

                Spacer()
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.97, green: 0.97, blue: 0.99),
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear { loadAllSettings() }
        .onChange(of: timerManager.workTime) { _ in
            SettingsStorage.shared.saveCurrentTimeSettings(
                workTime: timerManager.workTime, restTime: timerManager.restTime)
        }
        .onChange(of: timerManager.restTime) { _ in
            SettingsStorage.shared.saveCurrentTimeSettings(
                workTime: timerManager.workTime, restTime: timerManager.restTime)
        }
        .sheet(isPresented: $showSaveSheet) {
            saveSheet
        }
    }

    // MARK: - Sections

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("预设配置", systemImage: "list.bullet.rectangle.portrait")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            if !allSettings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allSettings) { setting in
                            presetButton(for: setting)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private func presetButton(for setting: AppSetting) -> some View {
        Button(action: {
            timerManager.workTime = setting.workTime
            timerManager.restTime = setting.restTime
            timerManager.currentTime = timerManager.workTime
            selectedSettingId = setting.id
            SettingsStorage.shared.saveLastSelectedSettingId(setting.id)
        }) {
            let workMin = setting.workTime / 60
            let workSec = setting.workTime % 60
            let restMin = setting.restTime / 60
            let restSec = setting.restTime % 60
            let isSelected = selectedSettingId == setting.id

            VStack(alignment: .leading, spacing: 4) {
                Text(setting.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("工作")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(workMin):\(String(format: "%02d", workSec))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                    }

                    Divider()
                        .frame(height: 24)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("休息")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(restMin):\(String(format: "%02d", restSec))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(minWidth: 120)
            .padding(10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? .blue : .black)
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("时间设置", systemImage: "timer")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            // 工作时间
            CompactTimingControl(
                title: "工作时间",
                icon: "briefcase.fill",
                color: .orange,
                value: $timerManager.workTime,
                defaultValue: TimeConstants.defaultWorkTime
            )

            // 休息时间
            CompactTimingControl(
                title: "休息时间",
                icon: "cup.and.saucer.fill",
                color: .green,
                value: $timerManager.restTime,
                defaultValue: TimeConstants.defaultRestTime
            )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("选项", systemImage: "gear")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("后台运行")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    Text("工作时在后台运行应用")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()

                Toggle("", isOn: $timerManager.isBackgroundMode)
                    .onChange(of: timerManager.isBackgroundMode) { _ in
                        updateWindowLeveling()
                    }
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { timerManager.resetTimer() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("重置")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.black)
                .cornerRadius(8)
                .font(.system(size: 14, weight: .semibold))
            }

            Button(action: { showSaveSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("保存")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var saveSheet: some View {
        VStack(spacing: 16) {
            Text("保存为新配置")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("配置名称", text: $newSettingName)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                Button("取消") { showSaveSheet = false }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.black)
                    .cornerRadius(8)

                Button("保存") {
                    saveNewSettings()
                    showSaveSheet = false
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(minHeight: 200)
    }

    // MARK: - Methods

    private func loadAllSettings() {
        do {
            var settings = try SettingsStorage.shared.getAllSettings()
            // 排序逻辑：系统预设优先，然后按总时长（工作+休息）逆序排列
            settings.sort { a, b in
                if a.isSystemPreset == b.isSystemPreset {
                    // 同类型按总时长逆序排列（时长长的在前）
                    let aTotalTime = a.workTime + a.restTime
                    let bTotalTime = b.workTime + b.restTime
                    return aTotalTime > bTotalTime
                }
                return a.isSystemPreset && !b.isSystemPreset
            }
            allSettings = settings
            if selectedSettingId == nil,
                let lastId = SettingsStorage.shared.getLastSelectedSettingId()
            {
                selectedSettingId = lastId
            }
        } catch {
            print("⚠️ Failed to load settings: \(error)")
        }
    }

    private func saveNewSettings() {
        guard !newSettingName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        do {
            try SettingsStorage.shared.saveSettings(
                id: nil,
                name: newSettingName,
                workTime: timerManager.workTime,
                restTime: timerManager.restTime,
                isSystemPreset: false
            )
            newSettingName = ""
            loadAllSettings()
        } catch {
            print("⚠️ Failed to save settings: \(error)")
        }
    }

    private func updateWindowLeveling() {
        WindowManager.shared.updateWindowToNormal(isBackgroundMode: timerManager.isBackgroundMode)
    }
}

// MARK: - Compact Timing Control Component

struct CompactTimingControl: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var value: Int
    let defaultValue: Int

    private var minutes: Int {
        value / 60
    }

    private var seconds: Int {
        value % 60
    }

    private var displayValue: String {
        String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 标题和显示
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(displayValue)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .frame(width: 60)
            }

            // 控制按钮（单行）
            HStack(spacing: 6) {
                // 分钟减
                Button(action: { value = max(1, value - 60) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(color.opacity(0.6))
                }

                // 分钟加
                Button(action: { value += 60 }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundColor(color.opacity(0.7))
                }

                // 秒减
                Button(action: { value = max(1, value - 1) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color.opacity(0.5))
                }

                // 秒加
                Button(action: { value += 1 }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(color.opacity(0.6))
                }

                // 重置
                Button(action: { value = defaultValue }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Timing Card Component (Legacy - kept for backward compatibility)

struct TimingCard: View {
    let title: String
    let icon: String
    let color: Color
    let value: Int
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    let onReset: () -> Void

    private var displayValue: String {
        let minutes = value / 60
        let seconds = value % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                Text(displayValue)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            HStack(spacing: 10) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(color.opacity(0.6))
                }

                Spacer()

                Button(action: onReset) {
                    Text("重置")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
}
