import Foundation
import CoreData

@objc(NotificationSettingsEntity)
public class NotificationSettingsEntity: NSManagedObject {
    
    // MARK: - Conversion Methods
    
    func toNotificationSettings() -> NotificationSettings {
        var settings = NotificationSettings()
        
        if let settingsData = self.settingsData {
            do {
                let decodedSettings = try JSONDecoder().decode(NotificationSettings.self, from: settingsData)
                settings = decodedSettings
            } catch {
                print("Failed to decode notification settings: \(error)")
            }
        }
        
        settings.isEnabled = self.isEnabled
        settings.monitoredLocations = self.monitoredLocations ?? []
        settings.trafficThreshold = TrafficCondition(rawValue: self.trafficThreshold ?? "Light") ?? .light
        
        return settings
    }
    
    static func fromNotificationSettings(_ settings: NotificationSettings, context: NSManagedObjectContext) -> NotificationSettingsEntity {
        let entity = NotificationSettingsEntity(context: context)
        
        entity.isEnabled = settings.isEnabled
        entity.monitoredLocations = settings.monitoredLocations
        entity.trafficThreshold = settings.trafficThreshold.rawValue
        
        do {
            let settingsData = try JSONEncoder().encode(settings)
            entity.settingsData = settingsData
        } catch {
            print("Failed to encode notification settings: \(error)")
        }
        
        return entity
    }
}
