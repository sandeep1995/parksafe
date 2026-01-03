//
//  ParkingSession.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import CoreLocation

struct ParkingSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let location: LocationData?
    let duration: TimeInterval
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date, location: LocationData? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.duration = endTime.timeIntervalSince(startTime)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var truncatedAddress: String {
        guard let location = location else { return "Unknown Location" }
        let components = location.address.components(separatedBy: ",")
        if components.count > 0 {
            return components[0].trimmingCharacters(in: .whitespaces)
        }
        return location.address
    }
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D, address: String) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
    }
}
