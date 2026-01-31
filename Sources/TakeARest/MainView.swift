import SwiftUI

struct MainView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(timerManager.formattedTime())
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.red)
                .padding()
            
            ProgressView(value: Double(timerManager.currentTime), total: Double(timerManager.isWorking ? timerManager.workTime : timerManager.restTime))
                .frame(height: 10)
                .padding(.horizontal, 40)
                .progressViewStyle(LinearProgressViewStyle(tint: timerManager.isWorking ? .red : .green))
            
            HStack {
                Text("工作中")
                    .font(.headline)
            }
            .padding(.bottom, 10)
        }
    }
}