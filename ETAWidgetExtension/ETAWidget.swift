import WidgetKit
import SwiftUI
import CoreLocation

struct ETAWidget: Widget {
    let kind: String = "ETAWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ETAProvider()) { entry in
            ETAWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ETA Tracker")
        .description("View travel times to your favorite destinations")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ETAEntry: TimelineEntry {
    let date: Date
    let locations: [SavedLocation]
    let travelTimes: [String: TravelTimeResult]
    let currentLocation: CLLocation?
    let errorMessage: String?
}

struct ETAProvider: TimelineProvider {
    func placeholder(in context: Context) -> ETAEntry {
        ETAEntry(
            date: Date(),
            locations: [
                SavedLocation(name: "Home", address: "123 Main St", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
                SavedLocation(name: "Work", address: "456 Business Ave", coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094))
            ],
            travelTimes: [:],
            currentLocation: nil,
            errorMessage: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ETAEntry) -> ()) {
        let entry = ETAEntry(
            date: Date(),
            locations: loadSavedLocations(),
            travelTimes: [:],
            currentLocation: nil,
            errorMessage: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ETAEntry>) -> ()) {
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        
        Task {
            let entry = await createEntry(for: entryDate)
            let timeline = Timeline(entries: [entry], policy: .after(entryDate))
            completion(timeline)
        }
    }
    
    private func createEntry(for date: Date) async -> ETAEntry {
        let locations = loadSavedLocations()
        let currentLocation = await getCurrentLocation()
        var travelTimes: [String: TravelTimeResult] = [:]
        
        if let currentLocation = currentLocation {
            let mapService = MapAPIService()
            for location in locations {
                let result = await mapService.getTravelTime(from: currentLocation, to: CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
                travelTimes[location.id.uuidString] = result
            }
        }
        
        return ETAEntry(
            date: date,
            locations: locations,
            travelTimes: travelTimes,
            currentLocation: currentLocation,
            errorMessage: currentLocation == nil ? "Location unavailable" : nil
        )
    }
    
    private func loadSavedLocations() -> [SavedLocation] {
        // Load from UserDefaults or Core Data
        // This is a simplified version
        return []
    }
    
    private func getCurrentLocation() async -> CLLocation? {
        // This would typically use the shared location manager
        // For now, return nil to indicate location unavailable
        return nil
    }
}

struct ETAWidgetEntryView: View {
    var entry: ETAProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            if let errorMessage = entry.errorMessage {
                errorView(message: errorMessage)
            } else if entry.locations.isEmpty {
                emptyStateView
            } else {
                locationsView
            }
        }
        .padding()
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.blue)
            Text("ETA")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            Text(entry.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "location.slash")
                .font(.title2)
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "map")
                .font(.title2)
                .foregroundColor(.blue)
            Text("No locations added")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var locationsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(entry.locations.prefix(3))) { location in
                LocationRowWidgetView(
                    location: location,
                    travelTime: entry.travelTimes[location.id.uuidString]
                )
            }
        }
    }
}

struct LocationRowWidgetView: View {
    let location: SavedLocation
    let travelTime: TravelTimeResult?
    
    var body: some View {
        HStack {
            Image(systemName: location.category.icon)
                .foregroundColor(Color(location.category.color))
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(location.address)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(travelTime?.travelTime ?? "Calculating...")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                if let distance = travelTime?.distance, !distance.isEmpty {
                    Text(distance)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview(as: .systemSmall) {
    ETAWidget()
} timeline: {
    ETAEntry(
        date: .now,
        locations: [
            SavedLocation(name: "Home", address: "123 Main St", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
            SavedLocation(name: "Work", address: "456 Business Ave", coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094))
        ],
        travelTimes: [
            "1": TravelTimeResult(travelTime: "15m", distance: "5.2 mi", duration: 900, distanceInMeters: 8368),
            "2": TravelTimeResult(travelTime: "25m", distance: "8.1 mi", duration: 1500, distanceInMeters: 13035)
        ],
        currentLocation: CLLocation(latitude: 37.7649, longitude: -122.4294),
        errorMessage: nil
    )
}
