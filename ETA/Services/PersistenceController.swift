import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleLocation = SavedLocationEntity(context: viewContext)
        sampleLocation.id = UUID()
        sampleLocation.name = "Home"
        sampleLocation.address = "123 Main St, San Francisco, CA"
        sampleLocation.latitude = 37.7749
        sampleLocation.longitude = -122.4194
        sampleLocation.category = "Home"
        sampleLocation.isFavorite = true
        sampleLocation.dateAdded = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ETAModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Core Data Extensions
extension PersistenceController {
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteLocation(_ location: SavedLocationEntity) {
        container.viewContext.delete(location)
        save()
    }
    
    func fetchLocations() -> [SavedLocationEntity] {
        let request: NSFetchRequest<SavedLocationEntity> = SavedLocationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocationEntity.isFavorite, ascending: false),
                                  NSSortDescriptor(keyPath: \SavedLocationEntity.name, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch locations: \(error)")
            return []
        }
    }
    
    func fetchFavoriteLocations() -> [SavedLocationEntity] {
        let request: NSFetchRequest<SavedLocationEntity> = SavedLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocationEntity.name, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch favorite locations: \(error)")
            return []
        }
    }
}

// MARK: - SavedLocation to Core Data Conversion
extension PersistenceController {
    func createLocation(from savedLocation: SavedLocation) -> SavedLocationEntity {
        let entity = SavedLocationEntity(context: container.viewContext)
        entity.id = savedLocation.id
        entity.name = savedLocation.name
        entity.address = savedLocation.address
        entity.latitude = savedLocation.coordinate.latitude
        entity.longitude = savedLocation.coordinate.longitude
        entity.category = savedLocation.category.rawValue
        entity.isFavorite = savedLocation.isFavorite
        entity.dateAdded = savedLocation.dateAdded
        
        save()
        return entity
    }
    
    func updateLocation(_ entity: SavedLocationEntity, with savedLocation: SavedLocation) {
        entity.name = savedLocation.name
        entity.address = savedLocation.address
        entity.latitude = savedLocation.coordinate.latitude
        entity.longitude = savedLocation.coordinate.longitude
        entity.category = savedLocation.category.rawValue
        entity.isFavorite = savedLocation.isFavorite
        
        save()
    }
}
