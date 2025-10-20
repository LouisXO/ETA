import Foundation
import CoreLocation
import MapKit

// MARK: - Saved Location Model
struct SavedLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: LocationCategory
    let isFavorite: Bool
    let dateAdded: Date
    
    init(name: String, address: String, coordinate: CLLocationCoordinate2D, category: LocationCategory = .other, isFavorite: Bool = false) {
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.category = category
        self.isFavorite = isFavorite
        self.dateAdded = Date()
    }
}

// MARK: - Location Category
enum LocationCategory: String, CaseIterable, Codable {
    case home = "Home"
    case work = "Work"
    case school = "School"
    case gym = "Gym"
    case grocery = "Grocery"
    case restaurant = "Restaurant"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .school: return "graduationcap.fill"
        case .gym: return "figure.strengthtraining.traditional"
        case .grocery: return "cart.fill"
        case .restaurant: return "fork.knife"
        case .other: return "mappin.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .home: return "blue"
        case .work: return "orange"
        case .school: return "green"
        case .gym: return "red"
        case .grocery: return "purple"
        case .restaurant: return "pink"
        case .other: return "gray"
        }
    }
}

// MARK: - Travel Time Result
struct TravelTimeResult {
    let travelTime: String
    let distance: String
    let duration: TimeInterval
    let distanceInMeters: Double
    let trafficCondition: TrafficCondition
    let lastUpdated: Date
    
    init(travelTime: String, distance: String, duration: TimeInterval, distanceInMeters: Double, trafficCondition: TrafficCondition = .unknown) {
        self.travelTime = travelTime
        self.distance = distance
        self.duration = duration
        self.distanceInMeters = distanceInMeters
        self.trafficCondition = trafficCondition
        self.lastUpdated = Date()
    }
}

// MARK: - Traffic Condition
enum TrafficCondition: String, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case heavy = "Heavy"
    case unknown = "Unknown"
    
    var color: String {
        switch self {
        case .light: return "green"
        case .moderate: return "yellow"
        case .heavy: return "red"
        case .unknown: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "car.fill"
        case .moderate: return "car.2.fill"
        case .heavy: return "car.3.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var isEnabled: Bool
    var timeSlots: [TimeSlot]
    var monitoredLocations: Set<UUID>
    var trafficThreshold: TrafficCondition
    
    init() {
        self.isEnabled = true
        self.timeSlots = [
            TimeSlot(startHour: 8, endHour: 10, days: [.monday, .tuesday, .wednesday, .thursday, .friday]),
            TimeSlot(startHour: 17, endHour: 19, days: [.monday, .tuesday, .wednesday, .thursday, .friday])
        ]
        self.monitoredLocations = []
        self.trafficThreshold = .light
    }
}

// MARK: - Time Slot
struct TimeSlot: Codable, Identifiable {
    let id = UUID()
    let startHour: Int
    let endHour: Int
    let days: Set<Weekday>
    
    init(startHour: Int, endHour: Int, days: Set<Weekday>) {
        self.startHour = startHour
        self.endHour = endHour
        self.days = days
    }
}

// MARK: - Weekday
enum Weekday: String, CaseIterable, Codable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - CLLocationCoordinate2D Codable Extension
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}
