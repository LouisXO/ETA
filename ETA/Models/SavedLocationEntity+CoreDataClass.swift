import Foundation
import CoreData
import CoreLocation

@objc(SavedLocationEntity)
public class SavedLocationEntity: NSManagedObject {
    
    // MARK: - Computed Properties
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    var locationCategory: LocationCategory {
        get {
            return LocationCategory(rawValue: category ?? "Other") ?? .other
        }
        set {
            category = newValue.rawValue
        }
    }
    
    // MARK: - Conversion Methods
    
    func toSavedLocation() -> SavedLocation {
        return SavedLocation(
            name: name ?? "Unknown",
            address: address ?? "",
            coordinate: coordinate,
            category: locationCategory,
            isFavorite: isFavorite
        )
    }
    
    static func fromSavedLocation(_ savedLocation: SavedLocation, context: NSManagedObjectContext) -> SavedLocationEntity {
        let entity = SavedLocationEntity(context: context)
        entity.id = savedLocation.id
        entity.name = savedLocation.name
        entity.address = savedLocation.address
        entity.latitude = savedLocation.coordinate.latitude
        entity.longitude = savedLocation.coordinate.longitude
        entity.category = savedLocation.category.rawValue
        entity.isFavorite = savedLocation.isFavorite
        entity.dateAdded = savedLocation.dateAdded
        return entity
    }
}
