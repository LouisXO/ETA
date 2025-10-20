import SwiftUI
import MapKit
import CoreLocation

struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: MKMapItem?
    @State private var locationName = ""
    @State private var selectedCategory: LocationCategory = .other
    @State private var isSearching = false
    
    let onLocationAdded: (SavedLocation) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                searchSection
                
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No locations found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    resultsSection
                }
                
                Spacer()
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(selectedLocation == nil || locationName.isEmpty)
                }
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        searchForLocation()
                    }
            }
            
            if let selectedLocation = selectedLocation {
                selectedLocationView(selectedLocation)
            }
        }
        .padding()
    }
    
    private func selectedLocationView(_ location: MKMapItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Selected Location")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name ?? "Unknown Location")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let address = location.placemark.title {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                TextField("Location name", text: $locationName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(LocationCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var resultsSection: some View {
        List(searchResults, id: \.self) { mapItem in
            LocationSearchResultRow(
                mapItem: mapItem,
                isSelected: selectedLocation == mapItem
            ) {
                selectLocation(mapItem)
            }
        }
    }
    
    private func searchForLocation() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        Task {
            let mapService = MapAPIService()
            let results = await mapService.searchForLocation(query: searchText)
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
    
    private func selectLocation(_ mapItem: MKMapItem) {
        selectedLocation = mapItem
        locationName = mapItem.name ?? "Unknown Location"
    }
    
    private func saveLocation() {
        guard let selectedLocation = selectedLocation else { return }
        
        let coordinate = selectedLocation.placemark.coordinate
        let address = selectedLocation.placemark.title ?? "Unknown Address"
        
        let savedLocation = SavedLocation(
            name: locationName,
            address: address,
            coordinate: coordinate,
            category: selectedCategory
        )
        
        onLocationAdded(savedLocation)
        dismiss()
    }
}

struct LocationSearchResultRow: View {
    let mapItem: MKMapItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = mapItem.placemark.title {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddLocationView { _ in }
}
