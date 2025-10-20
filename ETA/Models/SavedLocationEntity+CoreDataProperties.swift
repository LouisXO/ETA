import Foundation
import CoreData

extension SavedLocationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedLocationEntity> {
        return NSFetchRequest<SavedLocationEntity>(entityName: "SavedLocationEntity")
    }

    @NSManaged public var address: String?
    @NSManaged public var category: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?

}
