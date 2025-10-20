import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mapAPIService = MapAPIService()
    @State private var showingAddLocation = false
    @State private var locations: [SavedLocation] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if locationManager.authorizationStatus == .denied {
                    LocationPermissionView()
                } else if locations.isEmpty {
                    EmptyStateView(showingAddLocation: $showingAddLocation)
                } else {
                    LocationListView(
                        locations: $locations,
                        currentLocation: locationManager.currentLocation,
                        mapAPIService: mapAPIService
                    )
                }
            }
            .navigationTitle("ETA")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddLocation = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newLocation in
                    locations.append(newLocation)
                }
            }
            .onAppear {
                loadLocations()
            }
        }
    }
    
    private func loadLocations() {
        // Load saved locations from Core Data
        // This will be implemented with Core Data integration
        locations = []
    }
}

struct LocationPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Location Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("ETA needs access to your location to calculate travel times to your destinations.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct EmptyStateView: View {
    @Binding var showingAddLocation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Locations Added")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your frequently visited destinations to get started with ETA tracking.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Add Your First Location") {
                showingAddLocation = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct LocationListView: View {
    @Binding var locations: [SavedLocation]
    let currentLocation: CLLocation?
    let mapAPIService: MapAPIService
    
    var body: some View {
        List {
            ForEach(locations) { location in
                LocationRowView(
                    location: location,
                    currentLocation: currentLocation,
                    mapAPIService: mapAPIService
                )
            }
            .onDelete(perform: deleteLocations)
        }
        .refreshable {
            await refreshTravelTimes()
        }
    }
    
    private func deleteLocations(offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
    }
    
    private func refreshTravelTimes() async {
        guard let currentLocation = currentLocation else { return }
        
        for location in locations {
            await mapAPIService.updateTravelTime(
                from: currentLocation,
                to: location.coordinate
            )
        }
    }
}

struct LocationRowView: View {
    let location: SavedLocation
    let currentLocation: CLLocation?
    let mapAPIService: MapAPIService
    
    @State private var travelTime: String = "Calculating..."
    @State private var distance: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.headline)
                    Text(location.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(travelTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if !distance.isEmpty {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let currentLocation = currentLocation {
                Button("Get Directions") {
                    openInMaps(from: currentLocation, to: location.coordinate)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            calculateTravelTime()
        }
    }
    
    private func calculateTravelTime() {
        guard let currentLocation = currentLocation else {
            travelTime = "Location unavailable"
            return
        }
        
        Task {
            let result = await mapAPIService.getTravelTime(
                from: currentLocation,
                to: location.coordinate
            )
            
            await MainActor.run {
                travelTime = result.travelTime
                distance = result.distance
            }
        }
    }
    
    private func openInMaps(from: CLLocation, to: CLLocationCoordinate2D) {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: from.coordinate))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let response = response {
                let route = response.routes[0]
                destination.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            }
        }
    }
}

#Preview {
    ContentView()
}
