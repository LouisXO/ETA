import Foundation
import CoreLocation
import MapKit

class MapAPIService: ObservableObject {
    private let directions = MKDirections()
    private var cache: [String: TravelTimeResult] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // MARK: - Public Methods
    
    func getTravelTime(from startLocation: CLLocation, to endLocation: CLLocation) async -> TravelTimeResult {
        let cacheKey = generateCacheKey(from: startLocation, to: endLocation)
        
        // Check cache first
        if let cachedResult = cache[cacheKey],
           Date().timeIntervalSince(cachedResult.lastUpdated) < cacheExpirationTime {
            return cachedResult
        }
        
        // Fetch new data
        let result = await fetchTravelTime(from: startLocation, to: endLocation)
        cache[cacheKey] = result
        
        return result
    }
    
    func updateTravelTime(from startLocation: CLLocation, to endLocation: CLLocation) async {
        let result = await getTravelTime(from: startLocation, to: endLocation)
        let cacheKey = generateCacheKey(from: startLocation, to: endLocation)
        cache[cacheKey] = result
    }
    
    func getMultipleTravelTimes(from startLocation: CLLocation, to destinations: [CLLocation]) async -> [TravelTimeResult] {
        return await withTaskGroup(of: TravelTimeResult.self) { group in
            for destination in destinations {
                group.addTask {
                    await self.getTravelTime(from: startLocation, to: destination)
                }
            }
            
            var results: [TravelTimeResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    func searchForLocation(query: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            return response.mapItems
        } catch {
            print("Search error: \(error.localizedDescription)")
            return []
        }
    }
    
    func getTrafficCondition(for route: MKRoute) -> TrafficCondition {
        // Analyze route to determine traffic condition
        let expectedDuration = route.expectedTravelTime
        let distance = route.distance
        
        // Calculate expected speed without traffic
        let expectedSpeed = distance / expectedDuration // m/s
        
        // Convert to mph
        let expectedSpeedMPH = expectedSpeed * 2.237
        
        // Determine traffic condition based on speed
        if expectedSpeedMPH > 45 {
            return .light
        } else if expectedSpeedMPH > 25 {
            return .moderate
        } else {
            return .heavy
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchTravelTime(from startLocation: CLLocation, to endLocation: CLLocation) async -> TravelTimeResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        do {
            let response = try await directions.calculate(request)
            
            guard let route = response.routes.first else {
                return createErrorResult()
            }
            
            let travelTime = formatTravelTime(route.expectedTravelTime)
            let distance = formatDistance(route.distance)
            let trafficCondition = getTrafficCondition(for: route)
            
            return TravelTimeResult(
                travelTime: travelTime,
                distance: distance,
                duration: route.expectedTravelTime,
                distanceInMeters: route.distance,
                trafficCondition: trafficCondition
            )
            
        } catch {
            print("Directions error: \(error.localizedDescription)")
            return createErrorResult()
        }
    }
    
    private func generateCacheKey(from startLocation: CLLocation, to endLocation: CLLocation) -> String {
        let startLat = String(format: "%.4f", startLocation.coordinate.latitude)
        let startLon = String(format: "%.4f", startLocation.coordinate.longitude)
        let endLat = String(format: "%.4f", endLocation.coordinate.latitude)
        let endLon = String(format: "%.4f", endLocation.coordinate.longitude)
        
        return "\(startLat),\(startLon)->\(endLat),\(endLon)"
    }
    
    private func formatTravelTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    private func createErrorResult() -> TravelTimeResult {
        return TravelTimeResult(
            travelTime: "Error",
            distance: "",
            duration: 0,
            distanceInMeters: 0,
            trafficCondition: .unknown
        )
    }
}

// MARK: - Traffic Analysis
extension MapAPIService {
    func analyzeTrafficPatterns(for location: CLLocation, timeSlots: [TimeSlot]) async -> [TrafficCondition] {
        var conditions: [TrafficCondition] = []
        
        for slot in timeSlots {
            // This would typically involve historical data analysis
            // For now, we'll simulate based on common traffic patterns
            let condition = simulateTrafficCondition(for: slot)
            conditions.append(condition)
        }
        
        return conditions
    }
    
    private func simulateTrafficCondition(for timeSlot: TimeSlot) -> TrafficCondition {
        // Simulate traffic conditions based on time of day
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if timeSlot.startHour <= currentHour && currentHour <= timeSlot.endHour {
            // Rush hour simulation
            if (7...9).contains(currentHour) || (17...19).contains(currentHour) {
                return .heavy
            } else {
                return .moderate
            }
        } else {
            return .light
        }
    }
}

// MARK: - Notification Support
extension MapAPIService {
    func shouldSendTrafficNotification(
        currentCondition: TrafficCondition,
        threshold: TrafficCondition,
        timeSlot: TimeSlot
    ) -> Bool {
        // Check if current time is within the time slot
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentWeekday = Calendar.current.component(.weekday, from: Date())
        
        let isWithinTimeSlot = timeSlot.startHour <= currentHour && currentHour <= timeSlot.endHour
        let isCorrectDay = timeSlot.days.contains(Weekday.allCases[currentWeekday - 1])
        
        // Check if traffic condition meets threshold
        let conditionMet = currentCondition.rawValue == threshold.rawValue
        
        return isWithinTimeSlot && isCorrectDay && conditionMet
    }
}
