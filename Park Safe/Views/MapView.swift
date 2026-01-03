//
//  MapView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    let location: LocationData
    @Environment(\.dismiss) var dismiss
    
    @State private var position: MapCameraPosition
    
    init(location: LocationData) {
        self.location = location
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    
    var body: some View {
        NavigationView {
            Map(position: $position) {
                Marker("Your Car", coordinate: location.coordinate)
                    .tint(.red)
            }
            .navigationTitle("Find My Car")
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

#Preview {
    MapView(location: LocationData(
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        address: "123 Main St, San Francisco, CA"
    ))
}
