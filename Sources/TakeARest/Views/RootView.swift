import AppKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var timerManager: TimerState
    @State private var hasLoadedSettings = false
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.97, green: 0.97, blue: 0.99),
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                topBar
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                // 标签导航
                tabNavigation

                // 内容区域
                ZStack {
                    if selectedTab == 0 {
                        MainScreenView()
                    } else {
                        SettingsScreenView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()
            }

            // 休息模态框
            if timerManager.showRestModal {
                RestScreenView()
            }
        }
        .onAppear {
            if !hasLoadedSettings {
                hasLoadedSettings = true
                timerManager.loadUserSettings()
            }
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TakeARest")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                Text(timerManager.isWorking ? "工作中" : "休息中")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 12) {
                // 暂停/继续按钮
                Button(action: { timerManager.togglePause() }) {
                    Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8)
                }

                // 重置按钮
                Button(action: { timerManager.resetTimer() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(8)
                }

                // 退出按钮
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
    }

    private var tabNavigation: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { index in
                    let tabName = index == 0 ? "主界面" : "设置"
                    Button(action: { selectedTab = index }) {
                        Text(tabName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedTab == index ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .background(Color.clear)
                }
            }
            .background(Color.white)

            // 下划线指示器
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    Divider()
                        .background(Color.gray.opacity(0.2))

                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width / 2 - 8, height: 3)
                        .padding(4)
                        .offset(x: CGFloat(selectedTab) * (geometry.size.width / 2))
                }
            }
            .frame(height: 8)
            .background(Color.white)
        }
    }
}
