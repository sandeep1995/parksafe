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
    
    // Optional features
    let photoFileName: String?      // Photo of parking spot
    let hourlyRate: Double?         // Parking cost per hour
    let floor: String?              // Parking garage floor
    let section: String?            // Parking garage section
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        location: LocationData? = nil,
        photoFileName: String? = nil,
        hourlyRate: Double? = nil,
        floor: String? = nil,
        section: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.duration = endTime.timeIntervalSince(startTime)
        self.photoFileName = photoFileName
        self.hourlyRate = hourlyRate
        self.floor = floor
        self.section = section
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
    
    // Calculate total parking cost
    var totalCost: Double? {
        guard let rate = hourlyRate else { return nil }
        let hours = duration / 3600
        return hours * rate
    }
    
    var formattedCost: String? {
        guard let cost = totalCost else { return nil }
        return String(format: "$%.2f", cost)
    }
    
    // Combined floor and section display
    var parkingSpotInfo: String? {
        let parts = [floor, section].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
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
