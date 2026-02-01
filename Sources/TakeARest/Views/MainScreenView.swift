import SwiftUI

/// 圆形进度视图
struct CircularProgressView: View {
    var progress: Double
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // 进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.8, blue: 0.4),
                            Color(red: 0.8, green: 0.2, blue: 0.2),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

struct MainScreenView: View {
    @EnvironmentObject var timerManager: TimerState

    private var progress: Double {
        let total = timerManager.isWorking ? timerManager.workTime : timerManager.restTime
        return Double(timerManager.currentTime) / Double(total)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 模式卡片
            modeCard

            Spacer()
                .frame(height: 30)

            // 时间显示和进度圆圈
            ZStack(alignment: .center) {
                // 圆形进度视图
                let progress =
                    timerManager.isWorking
                    ? Double(timerManager.workTime - timerManager.currentTime)
                        / Double(timerManager.workTime)
                    : Double(timerManager.restTime - timerManager.currentTime)
                        / Double(timerManager.restTime)

                CircularProgressView(progress: progress)
                    .frame(width: 220, height: 220)

                // 时间文本
                VStack(spacing: 8) {
                    Text(timerManager.formattedTime())
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)

                    Text(timerManager.isWorking ? "工作时间" : "休息时间")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()
                .frame(height: 40)

            // 统计信息
            statisticsView

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var modeCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("当前模式")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                Text(timerManager.isWorking ? "🎯 工作中" : "☕ 休息中")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("剩余时间")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                Text(timerManager.formattedTime())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(timerManager.isWorking ? Color.orange : Color.green)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var statisticsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatisticItem(
                    label: "工作时长",
                    value: timerManager.formattedTimeFromSeconds(timerManager.workTime),
                    icon: "briefcase.fill",
                    color: Color.orange
                )

                StatisticItem(
                    label: "休息时长",
                    value: timerManager.formattedTimeFromSeconds(timerManager.restTime),
                    icon: "cup.and.saucer.fill",
                    color: Color.green
                )
            }

            HStack(spacing: 12) {
                StatisticItem(
                    label: "进度",
                    value: String(format: "%.0f%%", progress * 100),
                    icon: "chart.pie.fill",
                    color: Color.blue
                )

                StatisticItem(
                    label: "状态",
                    value: timerManager.isPaused ? "已暂停" : "运行中",
                    icon: timerManager.isPaused ? "pause.circle.fill" : "play.circle.fill",
                    color: timerManager.isPaused ? Color.gray : Color.green
                )
            }
        }
    }
}

/// 统计项视图
struct StatisticItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
            }

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}
