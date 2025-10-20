import Foundation
import CoreData

extension NotificationSettingsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotificationSettingsEntity> {
        return NSFetchRequest<NotificationSettingsEntity>(entityName: "NotificationSettingsEntity")
    }

    @NSManaged public var isEnabled: Bool
    @NSManaged public var monitoredLocations: Set<UUID>?
    @NSManaged public var settingsData: Data?
    @NSManaged public var trafficThreshold: String?

}
