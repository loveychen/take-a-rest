//
//  Constants.swift
//  TakeARest
//
//  Created by User on 2026/01/31.
//

import Foundation

// 时间设置常量
enum TimeConstants {
    // 默认工作时间（秒）
    static let defaultWorkTime: Int = 45 * 60
    // 默认休息时间（秒）
    static let defaultRestTime: Int = 5 * 60
    
    // 番茄工作法预设
    static let pomodoroWorkTime: Int = 25 * 60
    static let pomodoroRestTime: Int = 5 * 60
    
    // 长工作周期预设
    static let longWorkTime: Int = 45 * 60
    static let longRestTime: Int = 10 * 60
    
    // 短工作周期预设
    static let shortWorkTime: Int = 15 * 60
    static let shortRestTime: Int = 5 * 60
    
    // 深度工作预设
    static let deepWorkTime: Int = 90 * 60
    static let deepRestTime: Int = 10 * 60
    
    // 测试模式预设
    static let testWorkTime: Int = 10
    static let testRestTime: Int = 10
}
