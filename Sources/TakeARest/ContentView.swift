import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var timerManager: TimerManager
    @State private var selectedTab: Tab = .main
    @State private var hasLoadedSettings = false

    enum Tab: String {
        case main = "主界面"
        case settings = "设置"
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
                    MainView()
                } else {
                    SettingsView()
                }

                HStack(spacing: 15) {
                    Button(timerManager.isPaused ? "继续" : "暂停") {
                        timerManager.togglePause()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("重置") {
                        timerManager.resetTimer()
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

            if timerManager.showRestModal {
                RestModal()
            }
        }
        .onAppear {
            // 只在首次加载时调用 loadUserSettings
            if !hasLoadedSettings {
                hasLoadedSettings = true
                // 加载用户设置（在方法内部会处理线程调度）
                timerManager.loadUserSettings()
            }
        }
    }
}
