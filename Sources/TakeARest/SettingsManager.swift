import GRDB
import Foundation

// 预设设置结构体
struct PresetSetting: Identifiable {
    let id: Int
    let name: String
    let workTime: Int
    let restTime: Int
}

// 设置模型
struct AppSetting: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var name: String
    var workTime: Int
    var restTime: Int
    var isSystemPreset: Bool
    var createdAt: Date
    var updatedAt: Date
}

// 数据库配置
extension AppSetting {
    static let databaseTableName = "settings"
}

// 数据库管理类
final class SettingsManager: @unchecked Sendable {
    @MainActor static let shared = SettingsManager()
    
    private var dbQueue: DatabaseQueue?
    
    // 常用预设设置（所有时间以秒为单位存储）
    let presetSettings: [PresetSetting] = [
        PresetSetting(id: 1, name: "标准番茄工作法", workTime: 25 * 60, restTime: 5 * 60),
        PresetSetting(id: 2, name: "长工作周期", workTime: 45 * 60, restTime: 10 * 60), // 休息时间调整为10分钟（原15分钟）
        PresetSetting(id: 3, name: "短工作周期", workTime: 15 * 60, restTime: 5 * 60),
        PresetSetting(id: 4, name: "深度工作", workTime: 90 * 60, restTime: 10 * 60), // 休息时间调整为10分钟（原30分钟）
        PresetSetting(id: 5, name: "测试模式", workTime: 10, restTime: 10) // 测试模式保持10秒不变
    ]
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            // 获取应用程序支持目录
            let fileManager = FileManager.default
            let appSupportDir = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = appSupportDir.appendingPathComponent("TakeARest.sqlite")
            
            // 创建数据库队列
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            // 创建表（直接创建，不检查是否存在）
            try dbQueue?.write {
                db in
                // 删除现有表（如果存在）
                if try db.tableExists(AppSetting.databaseTableName) {
                    try db.drop(table: AppSetting.databaseTableName)
                }
                
                // 创建新表
                try db.create(table: AppSetting.databaseTableName) {
                    t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull()
                    t.column("workTime", .integer).notNull()
                    t.column("restTime", .integer).notNull()
                    t.column("isSystemPreset", .boolean).notNull()
                    t.column("createdAt", .datetime).notNull()
                    t.column("updatedAt", .datetime).notNull()
                }
            }
            
            // 插入所有系统预设
            try self.dbQueue?.write {
                db in
                for preset in presetSettings {
                    let systemSetting = AppSetting(
                        id: nil,
                        name: preset.name,
                        workTime: preset.workTime,
                        restTime: preset.restTime,
                        isSystemPreset: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try systemSetting.insert(db)
                }
            }
            
            // 创建默认用户配置
            try self.dbQueue?.write {
                db in
                let defaultSetting = AppSetting(
                    id: nil,
                    name: "我的默认配置",
                    workTime: 45 * 60,
                    restTime: 5 * 60,
                    isSystemPreset: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try defaultSetting.insert(db)
            }
        } catch {
            print("Database setup error: \(error)")
        }
    }
    
    // 获取所有设置
    func getAllSettings() throws -> [AppSetting] {
        guard let dbQueue = dbQueue else {
            return []
        }
        
        return try dbQueue.read {
            db in
            try AppSetting.all().fetchAll(db)
        }
    }
    
    // 获取当前设置
    func getCurrentSettings() throws -> AppSetting? {
        guard let dbQueue = dbQueue else {
            return nil
        }
        
        return try dbQueue.read {
            db in
            try AppSetting.order(Column("updatedAt").desc).fetchOne(db)
        }
    }
    
    // 根据名称获取设置
    func getSettingByName(_ name: String) throws -> AppSetting? {
        guard let dbQueue = dbQueue else {
            return nil
        }
        
        return try dbQueue.read {
            db in
            try AppSetting.filter(Column("name") == name).fetchOne(db)
        }
    }
    
    // 保存设置
    func saveSettings(id: Int64?, name: String, workTime: Int, restTime: Int, isSystemPreset: Bool) throws {
        guard let dbQueue = dbQueue else {
            return
        }
        
        let currentDate = Date()
        
        if let id = id {
            // 更新现有设置
            let updatedSetting = AppSetting(
                id: id,
                name: name,
                workTime: workTime,
                restTime: restTime,
                isSystemPreset: isSystemPreset,
                createdAt: currentDate,
                updatedAt: currentDate
            )
            
            try dbQueue.write {
                db in
                try updatedSetting.update(db)
            }
        } else {
            // 创建新设置
            let newSetting = AppSetting(
                id: nil,
                name: name,
                workTime: workTime,
                restTime: restTime,
                isSystemPreset: isSystemPreset,
                createdAt: currentDate,
                updatedAt: currentDate
            )
            
            try dbQueue.write {
                db in
                try newSetting.insert(db)
            }
        }
    }
    
    // 应用预设设置
    func applyPreset(_ preset: PresetSetting) throws {
        guard let dbQueue = dbQueue else {
            return
        }
        
        // 查找预设对应的系统配置
        if let systemSetting = try getSettingByName(preset.name) {
            // 创建用户配置
            let userSetting = AppSetting(
                id: nil,
                name: "我的默认配置",
                workTime: systemSetting.workTime,
                restTime: systemSetting.restTime,
                isSystemPreset: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try dbQueue.write {
                db in
                try userSetting.insert(db)
            }
        }
    }
    
    // 保存当前设置
    func saveCurrentSetting(workTime: Int, restTime: Int) throws {
        guard let dbQueue = dbQueue else {
            return
        }
        
        try dbQueue.write { 
            db in
            // 查找是否已存在当前设置
            if let existingSetting = try AppSetting.filter(Column("name") == "当前设置").fetchOne(db) {
                // 更新现有记录
                var updatedSetting = existingSetting
                updatedSetting.workTime = workTime
                updatedSetting.restTime = restTime
                updatedSetting.updatedAt = Date()
                try updatedSetting.update(db)
            } else {
                // 创建新记录
                let currentSetting = AppSetting(
                    id: nil,
                    name: "当前设置",
                    workTime: workTime,
                    restTime: restTime,
                    isSystemPreset: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try currentSetting.insert(db)
            }
        }
    }
    
    // 保存上次选择的设置ID
    func saveLastSelectedSettingId(_ id: Int64?) {
        UserDefaults.standard.set(id, forKey: "lastSelectedSettingId")
    }
    
    // 获取上次选择的设置ID
    func getLastSelectedSettingId() -> Int64? {
        return UserDefaults.standard.object(forKey: "lastSelectedSettingId") as? Int64
    }
    
    // 保存当前的工作时间和休息时间
    func saveCurrentTimeSettings(workTime: Int, restTime: Int) {
        UserDefaults.standard.set(workTime, forKey: "currentWorkTime")
        UserDefaults.standard.set(restTime, forKey: "currentRestTime")
    }
    
    // 获取当前的工作时间和休息时间
    func getCurrentTimeSettings() -> (workTime: Int, restTime: Int)? {
        guard let workTime = UserDefaults.standard.object(forKey: "currentWorkTime") as? Int,
              let restTime = UserDefaults.standard.object(forKey: "currentRestTime") as? Int else {
            return nil
        }
        return (workTime, restTime)
    }
    
    // 重置数据库（删除现有表并重新创建）
    func resetDatabase() throws {
        guard let dbQueue = dbQueue else {
            return
        }
        
        try dbQueue.write {
                db in
                // 删除现有表（如果存在）
                if try db.tableExists(AppSetting.databaseTableName) {
                    try db.drop(table: AppSetting.databaseTableName)
                }
                
                // 创建新表
                try db.create(table: AppSetting.databaseTableName) {
                t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("workTime", .integer).notNull()
                t.column("restTime", .integer).notNull()
                t.column("isSystemPreset", .boolean).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // 插入所有系统预设
            for preset in presetSettings {
                let systemSetting = AppSetting(
                    id: nil,
                    name: preset.name,
                    workTime: preset.workTime,
                    restTime: preset.restTime,
                    isSystemPreset: true,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try systemSetting.insert(db)
            }
            
            // 创建默认用户配置
            let defaultSetting = AppSetting(
                id: nil,
                name: "我的默认配置",
                workTime: 45 * 60,
                restTime: 5 * 60,
                isSystemPreset: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try defaultSetting.insert(db)
        }
    }
}
