//
//  ParkingSessionDetailView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import MapKit

struct ParkingSessionDetailView: View {
    let session: ParkingSession
    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoFullScreen = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo
                    if let photoFileName = session.photoFileName,
                       let photo = loadPhoto(fileName: photoFileName) {
                        Button(action: {
                            showPhotoFullScreen = true
                        }) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .fullScreenCover(isPresented: $showPhotoFullScreen) {
                            PhotoFullScreenView(image: photo)
                        }
                    }
                    
                    // Map
                    if let location = session.location {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Location")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            Map(position: .constant(.region(MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )))) {
                                Marker("Parking Spot", coordinate: location.coordinate)
                                    .tint(.red)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                            
                            Text(location.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .modernCard()
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Location")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "mappin.slash")
                                    .foregroundColor(.secondary)
                                Text("No location data")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .modernCard()
                    }
                    
                    // Details
                    VStack(spacing: 16) {
                        DetailRow(icon: "clock.fill", iconColor: .blue, title: "Duration", value: session.formattedDuration)
                        
                        DetailRow(icon: "calendar.fill", iconColor: .purple, title: "Date", value: session.formattedDate)
                        
                        if let spotInfo = session.parkingSpotInfo {
                            DetailRow(icon: "building.fill", iconColor: .orange, title: "Location", value: spotInfo)
                        }
                        
                        if let cost = session.formattedCost {
                            DetailRow(icon: "dollarsign.circle.fill", iconColor: .green, title: "Cost", value: cost)
                        }
                    }
                    .modernCard()
                }
                .padding()
            }
            .navigationTitle("Parking Details")
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
    
    private func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ParkingSessionDetailView(session: ParkingSession(
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date(),
        location: LocationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Main St, San Francisco, CA"
        ),
        floor: "P2",
        section: "A"
    ))
}
