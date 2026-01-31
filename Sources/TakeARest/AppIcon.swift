import SwiftUI

// 应用图标视图
struct AppIcon: View {
    var body: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom))
                
            // 时钟图案
            VStack {
                Circle()
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 80, height: 80)
                
                // 时针
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 6, height: 30)
                    .offset(y: -15)
                
                // 分针
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 40)
                    .offset(y: -20)
            }
            .opacity(0.9)
            
            // 装饰元素
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 30, height: 30)
                .offset(x: -30, y: -30)
            
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 20, height: 20)
                .offset(x: 25, y: -25)
            
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 25, height: 25)
                .offset(x: -20, y: 20)
        }
        .frame(width: 128, height: 128)
    }
}

// 预览
struct AppIcon_Previews: PreviewProvider {
    static var previews: some View {
        AppIcon()
    }
}
