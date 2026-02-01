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

// 数据库管理类
final class SettingsManager: @unchecked Sendable {
    static let shared = SettingsManager()

    private let persistentContainer: NSPersistentContainer
    private var managedObjectContext: NSManagedObjectContext?

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

    private init() {
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

        // 创建 persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(
            managedObjectModel: managedObjectModel)

        // 配置存储位置
        let fileManager = FileManager.default
        let appSupportDir = try? fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let storeURL = appSupportDir?.appendingPathComponent("TakeARest.sqlite")

        if let storeURL = storeURL {
            do {
                try persistentStoreCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL,
                    options: nil)
            } catch {
                print("Failed to add persistent store: \(error)")
            }
        }

        // 创建 managed object context
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = persistentStoreCoordinator
        self.managedObjectContext = moc

        // 创建 NSPersistentContainer（这个主要用于兼容性）
        persistentContainer = NSPersistentContainer(
            name: "TakeARest", managedObjectModel: managedObjectModel)

        setupDatabase()
    }

    var context: NSManagedObjectContext {
        return managedObjectContext ?? persistentContainer.viewContext
    }

    private func setupDatabase() {
        let context = self.context

        // 删除现有数据
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AppSettingEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)

            // 插入所有系统预设
            for preset in presetSettings {
                let entity = NSEntityDescription.insertNewObject(
                    forEntityName: "AppSettingEntity", into: context)
                entity.setValue(UUID().hashValue, forKey: "id")
                entity.setValue(preset.name, forKey: "name")
                entity.setValue(Int32(preset.workTime), forKey: "workTime")
                entity.setValue(Int32(preset.restTime), forKey: "restTime")
                entity.setValue(true, forKey: "isSystemPreset")
                entity.setValue(Date(), forKey: "createdAt")
                entity.setValue(Date(), forKey: "updatedAt")
            }

            // 创建默认用户配置
            let defaultEntity = NSEntityDescription.insertNewObject(
                forEntityName: "AppSettingEntity", into: context)
            defaultEntity.setValue(UUID().hashValue, forKey: "id")
            defaultEntity.setValue("我的默认配置", forKey: "name")
            defaultEntity.setValue(Int32(TimeConstants.defaultWorkTime), forKey: "workTime")
            defaultEntity.setValue(Int32(TimeConstants.defaultRestTime), forKey: "restTime")
            defaultEntity.setValue(false, forKey: "isSystemPreset")
            defaultEntity.setValue(Date(), forKey: "createdAt")
            defaultEntity.setValue(Date(), forKey: "updatedAt")

            try context.save()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    // 获取所有设置
    func getAllSettings() throws -> [AppSetting] {
        let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
        let entities = try context.fetch(fetchRequest)
        return entities.map { AppSetting(from: $0) }
    }

    // 获取当前设置（最新更新的）
    func getCurrentSettings() throws -> AppSetting? {
        let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \AppSettingEntity.updatedAt, ascending: false)
        ]
        fetchRequest.fetchLimit = 1

        if let entity = try context.fetch(fetchRequest).first {
            return AppSetting(from: entity)
        }
        return nil
    }

    // 根据名称获取设置
    func getSettingByName(_ name: String) throws -> AppSetting? {
        let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        if let entity = try context.fetch(fetchRequest).first {
            return AppSetting(from: entity)
        }
        return nil
    }

    // 保存设置
    func saveSettings(id: Int64?, name: String, workTime: Int, restTime: Int, isSystemPreset: Bool)
        throws
    {
        let context = self.context

        if let id = id {
            // 更新现有设置
            let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %lld", id)

            if let entity = try context.fetch(fetchRequest).first {
                entity.name = name
                entity.workTime = Int32(workTime)
                entity.restTime = Int32(restTime)
                entity.isSystemPreset = isSystemPreset
                entity.updatedAt = Date()
            }
        } else {
            // 创建新设置
            let entity = NSEntityDescription.insertNewObject(
                forEntityName: "AppSettingEntity", into: context)
            entity.setValue(UUID().hashValue, forKey: "id")
            entity.setValue(name, forKey: "name")
            entity.setValue(Int32(workTime), forKey: "workTime")
            entity.setValue(Int32(restTime), forKey: "restTime")
            entity.setValue(isSystemPreset, forKey: "isSystemPreset")
            entity.setValue(Date(), forKey: "createdAt")
            entity.setValue(Date(), forKey: "updatedAt")
        }

        try context.save()
    }

    // 应用预设设置
    func applyPreset(_ preset: PresetSetting) throws {
        if let systemSetting = try getSettingByName(preset.name) {
            // 创建用户配置
            let entity = NSEntityDescription.insertNewObject(
                forEntityName: "AppSettingEntity", into: context)
            entity.setValue(UUID().hashValue, forKey: "id")
            entity.setValue("我的默认配置", forKey: "name")
            entity.setValue(Int32(systemSetting.workTime), forKey: "workTime")
            entity.setValue(Int32(systemSetting.restTime), forKey: "restTime")
            entity.setValue(false, forKey: "isSystemPreset")
            entity.setValue(Date(), forKey: "createdAt")
            entity.setValue(Date(), forKey: "updatedAt")

            try context.save()
        }
    }

    // 保存当前设置
    func saveCurrentSetting(workTime: Int, restTime: Int) throws {
        let context = self.context
        let fetchRequest = NSFetchRequest<AppSettingEntity>(entityName: "AppSettingEntity")
        fetchRequest.predicate = NSPredicate(format: "name == %@", "当前设置")

        if let existingEntity = try context.fetch(fetchRequest).first {
            existingEntity.workTime = Int32(workTime)
            existingEntity.restTime = Int32(restTime)
            existingEntity.updatedAt = Date()
        } else {
            let entity = NSEntityDescription.insertNewObject(
                forEntityName: "AppSettingEntity", into: context)
            entity.setValue(UUID().hashValue, forKey: "id")
            entity.setValue("当前设置", forKey: "name")
            entity.setValue(Int32(workTime), forKey: "workTime")
            entity.setValue(Int32(restTime), forKey: "restTime")
            entity.setValue(false, forKey: "isSystemPreset")
            entity.setValue(Date(), forKey: "createdAt")
            entity.setValue(Date(), forKey: "updatedAt")
        }

        try context.save()
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
            let restTime = UserDefaults.standard.object(forKey: "currentRestTime") as? Int
        else {
            return nil
        }
        return (workTime, restTime)
    }

    // 重置数据库
    func resetDatabase() throws {
        let context = self.context
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AppSettingEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try context.execute(deleteRequest)
        try context.save()

        // 重新初始化
        setupDatabase()
    }
}
