import SwiftUI

struct SettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var notificationSettings = NotificationSettings()
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        Text("Traffic Alerts")
                        Spacer()
                        Toggle("", isOn: $notificationSettings.isEnabled)
                    }
                    
                    if notificationSettings.isEnabled {
                        Button("Configure Notifications") {
                            showingNotificationSettings = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Time Slots") {
                    ForEach(notificationSettings.timeSlots) { timeSlot in
                        TimeSlotRowView(timeSlot: timeSlot)
                    }
                }
                
                Section("Privacy") {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Location Access")
                            Text("Required for travel time calculations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Network Access")
                            Text("Required for map data and traffic information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Made with ❤️")
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView(settings: $notificationSettings)
            }
            .onAppear {
                requestNotificationPermissionIfNeeded()
            }
        }
    }
    
    private func requestNotificationPermissionIfNeeded() {
        if notificationService.authorizationStatus == .notDetermined {
            Task {
                await notificationService.requestNotificationPermission()
            }
        }
    }
}

struct TimeSlotRowView: View {
    let timeSlot: TimeSlot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(timeSlot.startHour):00 - \(timeSlot.endHour):00")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                ForEach(Array(timeSlot.days), id: \.self) { day in
                    Text(day.shortName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct NotificationSettingsView: View {
    @Binding var settings: NotificationSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Traffic Threshold") {
                    Picker("Notify when traffic is", selection: $settings.trafficThreshold) {
                        ForEach(TrafficCondition.allCases, id: \.self) { condition in
                            HStack {
                                Image(systemName: condition.icon)
                                Text(condition.rawValue)
                            }
                            .tag(condition)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Time Slots") {
                    ForEach(settings.timeSlots) { timeSlot in
                        TimeSlotEditView(timeSlot: timeSlot)
                    }
                    
                    Button("Add Time Slot") {
                        settings.timeSlots.append(
                            TimeSlot(startHour: 9, endHour: 11, days: [.monday, .tuesday, .wednesday, .thursday, .friday])
                        )
                    }
                }
                
                Section("Monitored Locations") {
                    Text("Select which locations to monitor for traffic conditions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimeSlotEditView: View {
    @State private var timeSlot: TimeSlot
    @State private var selectedDays: Set<Weekday>
    
    init(timeSlot: TimeSlot) {
        self._timeSlot = State(initialValue: timeSlot)
        self._selectedDays = State(initialValue: timeSlot.days)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Start Time")
                Spacer()
                DatePicker("", selection: Binding(
                    get: { createDate(hour: timeSlot.startHour) },
                    set: { timeSlot = TimeSlot(startHour: Calendar.current.component(.hour, from: $0), endHour: timeSlot.endHour, days: selectedDays) }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }
            
            HStack {
                Text("End Time")
                Spacer()
                DatePicker("", selection: Binding(
                    get: { createDate(hour: timeSlot.endHour) },
                    set: { timeSlot = TimeSlot(startHour: timeSlot.startHour, endHour: Calendar.current.component(.hour, from: $0), days: selectedDays) }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Days")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        Button(action: {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }) {
                            Text(day.shortName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedDays) { newDays in
            timeSlot = TimeSlot(startHour: timeSlot.startHour, endHour: timeSlot.endHour, days: newDays)
        }
    }
    
    private func createDate(hour: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

#Preview {
    SettingsView()
}
