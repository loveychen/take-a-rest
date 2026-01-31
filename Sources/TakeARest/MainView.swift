import SwiftUI

struct GradientProgressView: View {
    var value: Double
    var total: Double
    var height: CGFloat = 10
    var gradient: Gradient = Gradient(colors: [.green, .yellow, .red])
    
    var percentage: Double {
        min(max(value / total, 0), 1)
    }
    
    var body: some View {
        GeometryReader {
            geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                Rectangle()
                    .frame(width: geometry.size.width, height: height)
                    .foregroundColor(.gray.opacity(0.3))
                    .cornerRadius(height / 2)
                
                // 渐变进度条
                Rectangle()
                    .frame(width: geometry.size.width * CGFloat(percentage), height: height)
                    .background(LinearGradient(gradient: gradient, startPoint: .trailing, endPoint: .leading))
                    .foregroundColor(.clear)
                    .cornerRadius(height / 2)
            }
        }
        .frame(height: height)
    }
}

struct MainView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    // 计算进度条颜色：根据剩余时间百分比从绿色渐变为红色
    private var progressColor: Color {
        guard timerManager.isWorking else { return .green }
        
        let totalTime = timerManager.workTime
        let remainingTime = timerManager.currentTime
        let percentage = Double(remainingTime) / Double(totalTime)
        
        // 当时间剩余超过50%时，主要显示绿色
        // 当时间剩余少于20%时，主要显示红色
        // 中间部分使用渐变色
        if percentage > 0.5 {
            // 从红色渐变到绿色（50%-100%）
            let greenValue = 1.0
            let redValue = 1.0 - 2.0 * (percentage - 0.5)
            return Color(red: redValue, green: greenValue, blue: 0.0)
        } else {
            // 从绿色渐变到红色（0%-50%）
            let redValue = 1.0
            let greenValue = 2.0 * percentage
            return Color(red: redValue, green: greenValue, blue: 0.0)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(timerManager.formattedTime())
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.red) // 使用原来的大红色
                .padding()
            
            // 使用自定义的渐变进度条
            GradientProgressView(
                value: Double(timerManager.currentTime),
                total: Double(timerManager.isWorking ? timerManager.workTime : timerManager.restTime),
                height: 10,
                gradient: Gradient(colors: [.red, .yellow, .green])
            )
            .padding(.horizontal, 40)
            
            HStack {
                Text("工作中")
                    .font(.headline)
            }
            .padding(.bottom, 10)
        }
    }
}