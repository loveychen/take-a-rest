import CoreData
import Foundation

// 预设设置结构体
struct PresetSetting: Identifiable {
    let id: Int
    let name: String
    let workTime: Int
    let restTime: Int
}

// CoreData Entity
@objc(AppSettingEntity)
public class AppSettingEntity: NSManagedObject {
    @NSManaged public var id: Int64
    @NSManaged public var name: String
    @NSManaged public var workTime: Int32
    @NSManaged public var restTime: Int32
    @NSManaged public var isSystemPreset: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

// 设置模型（用于 UI 和业务逻辑）
struct AppSetting: Codable, Identifiable {
    var id: Int64?
    var name: String
    var workTime: Int
    var restTime: Int
    var isSystemPreset: Bool
    var createdAt: Date
    var updatedAt: Date

    // 从 CoreData Entity 转换
    init(from entity: AppSettingEntity) {
        self.id = entity.id
        self.name = entity.name
        self.workTime = Int(entity.workTime)
        self.restTime = Int(entity.restTime)
        self.isSystemPreset = entity.isSystemPreset
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }

    // 标准初始化
    init(
        id: Int64?, name: String, workTime: Int, restTime: Int, isSystemPreset: Bool,
        createdAt: Date, updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.workTime = workTime
        self.restTime = restTime
        self.isSystemPreset = isSystemPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Core Data 管理类 - 处理应用设置的持久化存储
/// 通过在后台队列进行 Core Data 操作来确保线程安全
final class SettingsStorage: Sendable {
    static let shared = SettingsStorage()

    private let persistentContainer: NSPersistentContainer
    private let backgroundQueue = DispatchQueue(
        label: "com.takearest.coredata", attributes: .concurrent)

    // 常用预设设置（所有时间以秒为单位存储）
    let presetSettings: [PresetSetting] = [
        PresetSetting(
            id: 1, name: "标准番茄工作法", workTime: TimeConstants.pomodoroWorkTime,
            restTime: TimeConstants.pomodoroRestTime),
        PresetSetting(
            id: 2, name: "长工作周期", workTime: TimeConstants.longWorkTime,
            restTime: TimeConstants.longRestTime),
        PresetSetting(
            id: 3, name: "短工作周期", workTime: TimeConstants.shortWorkTime,
            restTime: TimeConstants.shortRestTime),
        PresetSetting(
            id: 4, name: "深度工作", workTime: TimeConstants.deepWorkTime,
            restTime: TimeConstants.deepRestTime),
        PresetSetting(
            id: 5, name: "测试模式", workTime: TimeConstants.testWorkTime,
            restTime: TimeConstants.testRestTime),
    ]

    nonisolated private init() {
        // 创建 Core Data 数据模型（编程方式）
        let managedObjectModel = NSManagedObjectModel()

        // 创建 AppSettingEntity 实体
        let appSettingEntity = NSEntityDescription()
        appSettingEntity.name = "AppSettingEntity"
        appSettingEntity.managedObjectClassName = "AppSettingEntity"

        // 添加属性
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .integer64AttributeType
        idAttribute.isOptional = false

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false

        let workTimeAttribute = NSAttributeDescription()
        workTimeAttribute.name = "workTime"
        workTimeAttribute.attributeType = .integer32AttributeType
        workTimeAttribute.isOptional = false

        let restTimeAttribute = NSAttributeDescription()
        restTimeAttribute.name = "restTime"
        restTimeAttribute.attributeType = .integer32AttributeType
        restTimeAttribute.isOptional = false

        let isSystemPresetAttribute = NSAttributeDescription()
        isSystemPresetAttribute.name = "isSystemPreset"
        isSystemPresetAttribute.attributeType = .booleanAttributeType
        isSystemPresetAttribute.isOptional = false

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = false

        // 设置属性
        appSettingEntity.properties = [
            idAttribute, nameAttribute, workTimeAttribute, restTimeAttribute,
            isSystemPresetAttribute, createdAtAttribute, updatedAtAttribute,
        ]

        // 添加实体到模型
        managedObjectModel.entities = [appSettingEntity]

        // 创建持久化容器
        self.persistentContainer = NSPersistentContainer(
            name: "TakeARest", managedObjectModel: managedObjectModel)

        // 在后台线程加载持久化存储
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                print("⚠️ Failed to load persistent store: \(error)")
            }
        }
    }

    /// 获取主线程 MOC（用于 UI 更新）
    nonisolated var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// 创建后台 MOC（用于后台操作）
    nonisolated func createBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    // MARK: - 初始化数据库
    nonisolated func setupDatabase() {
        let bgContext = createBackgroundContext()
        bgContext.perform {
            // 检查是否已经初始化过（检查预设配置是否存在）
            let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
            fetchRequest.predicate = NSPredicate(format: "isSystemPreset == YES")

            do {
                let existingPresets = try bgContext.fetch(fetchRequest)
                // 如果预设已存在，不再重新初始化
                if !existingPresets.isEmpty {
                    return
                }

                // 插入所有系统预设
                for preset in self.presetSettings {
                    let entity = NSEntityDescription.insertNewObject(
                        forEntityName: "AppSettingEntity", into: bgContext)
                    entity.setValue(Int64(preset.id), forKey: "id")
                    entity.setValue(preset.name, forKey: "name")
                    entity.setValue(Int32(preset.workTime), forKey: "workTime")
                    entity.setValue(Int32(preset.restTime), forKey: "restTime")
                    entity.setValue(true, forKey: "isSystemPreset")
                    entity.setValue(Date(), forKey: "createdAt")
                    entity.setValue(Date(), forKey: "updatedAt")
                }

                try bgContext.save()

                // 同步到主线程上下文
                DispatchQueue.main.async {
                    do {
                        try self.mainContext.save()
                    } catch {
                        print("⚠️ Failed to save to main context: \(error)")
                    }
                }
            } catch {
                print("⚠️ Database setup error: \(error)")
            }
        }
    }

    // MARK: - 获取设置
    nonisolated func getAllSettings() throws -> [AppSetting] {
        try mainContext.performAndWait {
            let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
            let entities = try mainContext.fetch(fetchRequest)
            return entities.map { AppSetting(from: $0) }
        }
    }

    nonisolated func getCurrentSettings() throws -> AppSetting? {
        try mainContext.performAndWait {
            let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \AppSettingEntity.updatedAt, ascending: false)
            ]
            fetchRequest.fetchLimit = 1

            if let entity = try mainContext.fetch(fetchRequest).first {
                return AppSetting(from: entity)
            }
            return nil
        }
    }

    nonisolated func getSettingByName(_ name: String) throws -> AppSetting? {
        try mainContext.performAndWait {
            let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
            fetchRequest.predicate = NSPredicate(format: "name == %@", name)

            if let entity = try mainContext.fetch(fetchRequest).first {
                return AppSetting(from: entity)
            }
            return nil
        }
    }

    // MARK: - 保存设置
    nonisolated func saveSettings(
        id: Int64?, name: String, workTime: Int, restTime: Int, isSystemPreset: Bool
    ) throws {
        let bgContext = createBackgroundContext()
        try bgContext.performAndWait {
            if let id = id {
                // 更新现有设置
                let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
                fetchRequest.predicate = NSPredicate(format: "id == %lld", id)

                if let entity = try bgContext.fetch(fetchRequest).first {
                    entity.name = name
                    entity.workTime = Int32(workTime)
                    entity.restTime = Int32(restTime)
                    entity.isSystemPreset = isSystemPreset
                    entity.updatedAt = Date()
                }
            } else {
                // 创建新设置
                let entity = NSEntityDescription.insertNewObject(
                    forEntityName: "AppSettingEntity", into: bgContext)
                entity.setValue(UUID().hashValue, forKey: "id")
                entity.setValue(name, forKey: "name")
                entity.setValue(Int32(workTime), forKey: "workTime")
                entity.setValue(Int32(restTime), forKey: "restTime")
                entity.setValue(isSystemPreset, forKey: "isSystemPreset")
                entity.setValue(Date(), forKey: "createdAt")
                entity.setValue(Date(), forKey: "updatedAt")
            }

            try bgContext.save()
            // 同步到主线程上下文
            try mainContext.save()
        }
    }

    nonisolated func resetDatabase() throws {
        let bgContext = createBackgroundContext()
        try bgContext.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AppSettingEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            try bgContext.execute(deleteRequest)
            try bgContext.save()

            // 重新初始化
            setupDatabase()
        }
    }

    // MARK: - UserDefaults 操作
    nonisolated func saveLastSelectedSettingId(_ id: Int64?) {
        UserDefaults.standard.set(id, forKey: "lastSelectedSettingId")
    }

    nonisolated func getLastSelectedSettingId() -> Int64? {
        return UserDefaults.standard.object(forKey: "lastSelectedSettingId") as? Int64
    }

    nonisolated func saveCurrentTimeSettings(workTime: Int, restTime: Int) {
        UserDefaults.standard.set(workTime, forKey: "currentWorkTime")
        UserDefaults.standard.set(restTime, forKey: "currentRestTime")
    }

    nonisolated func getCurrentTimeSettings() -> (workTime: Int, restTime: Int)? {
        guard let workTime = UserDefaults.standard.object(forKey: "currentWorkTime") as? Int,
            let restTime = UserDefaults.standard.object(forKey: "currentRestTime") as? Int
        else {
            return nil
        }
        return (workTime, restTime)
    }
}
