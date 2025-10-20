# ETA Widget App Setup Guide

This guide will help you set up and run the ETA Widget app for iOS and macOS.

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ / macOS 14.0+ deployment target
- Apple Developer Account (for device testing and App Store distribution)

## Project Structure

```
ETA/
├── ETA/                          # Main iOS app
│   ├── ETAApp.swift             # App entry point
│   ├── ContentView.swift        # Main app interface
│   ├── Models/                  # Data models
│   │   ├── LocationModel.swift
│   │   ├── SavedLocationEntity+CoreDataClass.swift
│   │   ├── SavedLocationEntity+CoreDataProperties.swift
│   │   ├── NotificationSettingsEntity+CoreDataClass.swift
│   │   └── NotificationSettingsEntity+CoreDataProperties.swift
│   ├── Services/                # Core services
│   │   ├── LocationManager.swift
│   │   ├── MapAPIService.swift
│   │   ├── NotificationService.swift
│   │   └── PersistenceController.swift
│   ├── Views/                   # UI components
│   │   ├── AddLocationView.swift
│   │   └── SettingsView.swift
│   ├── Assets.xcassets/         # App assets
│   └── ETAModel.xcdatamodeld/   # Core Data model
├── ETAWidgetExtension/          # Widget extension
│   ├── ETAWidget.swift         # Widget implementation
│   ├── ETAWidgetBundle.swift   # Widget bundle
│   ├── ETAWidget.intentdefinition
│   └── InfoPlist.strings/
└── ETA.xcodeproj/              # Xcode project file
```

## Setup Instructions

### 1. Open the Project

1. Open `ETA.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Update the bundle identifier to match your developer account

### 2. Configure Location Services

The app requires location permissions. The following keys are already configured in the project:

- `NSLocationWhenInUseUsageDescription`: "ETA needs access to your location to calculate travel times to your destinations."

### 3. Configure Notifications

The app uses local notifications for traffic alerts. No additional setup is required as it uses the system's notification framework.

### 4. Core Data Setup

The app uses Core Data for persistence. The data model includes:

- `SavedLocationEntity`: Stores user's saved locations
- `NotificationSettingsEntity`: Stores notification preferences

### 5. Widget Configuration

The widget extension is configured to support:
- Small, medium, and large widget sizes
- Timeline updates every 5 minutes
- Location-based travel time calculations

## Key Features

### Core Functionality
- **Real-time Location Access**: Uses Core Location for GPS positioning
- **Travel Time Calculation**: Integrates with MapKit for route calculations
- **Distance Information**: Shows both driving distance and estimated travel time
- **Custom Location Lists**: Manage frequently visited destinations
- **Smart Traffic Notifications**: Receive alerts when traffic is light during optimal time slots

### Widget Capabilities
- **Quick Glance**: View travel times without opening the app
- **Multiple Destinations**: Display up to 3 locations simultaneously
- **Live Updates**: Automatically refreshes every 5 minutes
- **Traffic Alerts**: Shows traffic status indicators

### Notification System
- **Traffic Alerts**: Notifications when traffic conditions are optimal
- **Custom Time Slots**: Configure monitoring periods (e.g., 8-10 AM, 5-7 PM)
- **Location-Specific**: Choose which destinations to monitor

## Usage

### Adding Locations
1. Tap the "+" button in the main app
2. Search for a location using the search bar
3. Select the desired location from results
4. Choose a name and category
5. Save the location

### Configuring Notifications
1. Open Settings in the app
2. Enable "Traffic Alerts"
3. Configure time slots and traffic thresholds
4. Select which locations to monitor

### Using the Widget
1. Long press on the home screen
2. Tap the "+" button to add widgets
3. Search for "ETA" and select the widget
4. Choose your preferred size
5. The widget will automatically show travel times to your saved locations

## Development Notes

### Location Services
- The app requests "When In Use" location permissions
- Location updates are optimized for battery life (10-meter distance filter)
- Location data is not stored or transmitted

### Map Integration
- Uses MapKit for route calculations and search
- Implements caching to reduce API calls
- Supports real-time traffic data

### Data Persistence
- Core Data is used for local storage
- All user data remains on device
- No cloud synchronization (privacy-focused)

### Performance Considerations
- Widget updates are limited to every 5 minutes
- Location updates use distance-based filtering
- Map API calls are cached for 5 minutes

## Testing

### Simulator Testing
- Location services can be simulated in the iOS Simulator
- Use the "Features" menu to set custom locations
- Test different location scenarios

### Device Testing
- Real location services require a physical device
- Test notification permissions and delivery
- Verify widget functionality on home screen

## Troubleshooting

### Common Issues

1. **Location Not Updating**
   - Check location permissions in Settings
   - Ensure location services are enabled
   - Verify the app has "When In Use" permission

2. **Widget Not Showing Data**
   - Check if locations are saved in the main app
   - Verify widget has location permissions
   - Try removing and re-adding the widget

3. **Notifications Not Working**
   - Check notification permissions in Settings
   - Verify notification settings in the app
   - Ensure time slots are properly configured

### Debug Tips
- Use Xcode's location simulation for testing
- Check the console for Core Data errors
- Verify network connectivity for map data

## Privacy & Security

- **Location Data**: Only used for travel time calculations
- **No Tracking**: Location history is not stored
- **Local Storage**: All data remains on device
- **Minimal Permissions**: Only requests necessary permissions

## Future Enhancements

- Apple Watch companion app
- Siri Shortcuts integration
- Multiple transportation modes
- Advanced traffic pattern analysis
- Machine learning-based predictions

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the console logs in Xcode
3. Test on a physical device for location services
4. Verify all permissions are granted

---

**ETA Widget** - Never be late again. Know your travel time before you go.
