import Foundation
import UserNotifications
import CoreLocation

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Traffic Notifications
    
    func scheduleTrafficNotification(
        for location: SavedLocation,
        timeSlot: TimeSlot,
        trafficCondition: TrafficCondition
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Traffic Alert"
        content.body = "Traffic is \(trafficCondition.rawValue.lowercased()) to \(location.name). Good time to leave!"
        content.sound = .default
        content.categoryIdentifier = "TRAFFIC_ALERT"
        
        // Create date components for the notification
        var dateComponents = DateComponents()
        dateComponents.hour = timeSlot.startHour
        dateComponents.minute = 0
        
        // Schedule for each day in the time slot
        for weekday in timeSlot.days {
            dateComponents.weekday = weekdayToCalendarWeekday(weekday)
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "traffic_\(location.id.uuidString)_\(weekday.rawValue)_\(timeSlot.startHour)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
    
    func cancelTrafficNotifications(for location: SavedLocation) {
        let identifiers = Weekday.allCases.map { weekday in
            TimeSlot.allTimeSlots.flatMap { timeSlot in
                ["traffic_\(location.id.uuidString)_\(weekday.rawValue)_\(timeSlot.startHour)"]
            }
        }.flatMap { $0 }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func scheduleOptimalDepartureNotification(
        for location: SavedLocation,
        optimalDepartureTime: Date,
        travelTime: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Optimal Departure Time"
        content.body = "Leave now for \(location.name) - \(travelTime) travel time"
        content.sound = .default
        content.categoryIdentifier = "DEPARTURE_ALERT"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: optimalDepartureTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "departure_\(location.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule departure notification: \(error)")
            }
        }
    }
    
    // MARK: - Smart Traffic Monitoring
    
    func startTrafficMonitoring(
        for locations: [SavedLocation],
        settings: NotificationSettings
    ) {
        guard settings.isEnabled else { return }
        
        // Cancel existing notifications
        cancelAllTrafficNotifications()
        
        // Schedule new notifications for each location and time slot
        for location in locations {
            guard settings.monitoredLocations.contains(location.id) else { continue }
            
            for timeSlot in settings.timeSlots {
                // This would typically involve checking current traffic conditions
                // and scheduling notifications when conditions are optimal
                scheduleTrafficNotification(
                    for: location,
                    timeSlot: timeSlot,
                    trafficCondition: settings.trafficThreshold
                )
            }
        }
    }
    
    func cancelAllTrafficNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Helper Methods
    
    private func weekdayToCalendarWeekday(_ weekday: Weekday) -> Int {
        switch weekday {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
    
    private func calendarWeekdayToWeekday(_ weekday: Int) -> Weekday {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

// MARK: - Notification Categories
extension NotificationService {
    func setupNotificationCategories() {
        let trafficAlertCategory = UNNotificationCategory(
            identifier: "TRAFFIC_ALERT",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_APP",
                    title: "Open ETA",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "GET_DIRECTIONS",
                    title: "Get Directions",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let departureAlertCategory = UNNotificationCategory(
            identifier: "DEPARTURE_ALERT",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_APP",
                    title: "Open ETA",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "Snooze 10 min",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            trafficAlertCategory,
            departureAlertCategory
        ])
    }
}

// MARK: - TimeSlot Extensions
extension TimeSlot {
    static let allTimeSlots: [TimeSlot] = [
        TimeSlot(startHour: 8, endHour: 10, days: [.monday, .tuesday, .wednesday, .thursday, .friday]),
        TimeSlot(startHour: 17, endHour: 19, days: [.monday, .tuesday, .wednesday, .thursday, .friday])
    ]
}
