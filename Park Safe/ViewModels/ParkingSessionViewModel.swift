//
//  ParkingSessionViewModel.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

enum ParkingState {
    case idle
    case active(startTime: Date, endTime: Date, location: LocationData?)
}

class ParkingSessionViewModel: ObservableObject {
    @Published var state: ParkingState = .idle
    @Published var selectedDuration: TimeInterval = 3600 // Default 1 hour
    @Published var remainingTime: TimeInterval = 0
    @Published var currentAddress: String = "Locating..."
    @Published var parkingLocation: LocationData?
    
    private var timer: AnyCancellable?
    private let locationManager: LocationManager
    private let notificationManager: NotificationManager
    private let persistenceManager = PersistenceManager.shared
    private var settings: AppSettings
    
    init(locationManager: LocationManager, notificationManager: NotificationManager) {
        self.locationManager = locationManager
        self.notificationManager = notificationManager
        self.settings = persistenceManager.loadAppSettings()
        
        // Load default duration from settings
        self.selectedDuration = settings.defaultDuration
        
        // Observe location updates
        locationManager.$currentAddress
            .assign(to: &$currentAddress)
        
        // Check for active parking session on init
        checkForActiveParking()
    }
    
    private func checkForActiveParking() {
        // Check if there's a stored active session
        if let storedEndTime = UserDefaults.standard.object(forKey: "activeParkingEndTime") as? Date,
           storedEndTime > Date() {
            // Restore active session
            let storedStartTime = UserDefaults.standard.object(forKey: "activeParkingStartTime") as? Date ?? Date()
            
            // Try to restore location
            var location: LocationData? = nil
            if let lat = UserDefaults.standard.object(forKey: "activeParkingLat") as? Double,
               let lon = UserDefaults.standard.object(forKey: "activeParkingLon") as? Double,
               let address = UserDefaults.standard.object(forKey: "activeParkingAddress") as? String {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                location = LocationData(coordinate: coordinate, address: address)
            }
            
            startParking(startTime: storedStartTime, endTime: storedEndTime, location: location)
        }
    }
    
    func startParking(duration: TimeInterval? = nil, startTime: Date? = nil, endTime: Date? = nil, location: LocationData? = nil) {
        let durationToUse = duration ?? selectedDuration
        let start = startTime ?? Date()
        let end = endTime ?? start.addingTimeInterval(durationToUse)
        
        // Get current location if not provided
        var parkingLocation = location
        if parkingLocation == nil, let coordinate = locationManager.getCurrentLocation() {
            let address = locationManager.currentAddress
            parkingLocation = LocationData(coordinate: coordinate, address: address)
        }
        
        self.parkingLocation = parkingLocation
        state = .active(startTime: start, endTime: end, location: parkingLocation)
        
        // Store active session
        UserDefaults.standard.set(start, forKey: "activeParkingStartTime")
        UserDefaults.standard.set(end, forKey: "activeParkingEndTime")
        if let loc = parkingLocation {
            UserDefaults.standard.set(loc.latitude, forKey: "activeParkingLat")
            UserDefaults.standard.set(loc.longitude, forKey: "activeParkingLon")
            UserDefaults.standard.set(loc.address, forKey: "activeParkingAddress")
        }
        
        // Start location updates
        locationManager.startLocationUpdates()
        
        // Schedule notifications
        Task {
            _ = await notificationManager.requestAuthorization()
            notificationManager.scheduleParkingNotifications(
                endTime: end,
                notificationTiming: settings.notificationTiming,
                soundEnabled: settings.soundEnabled
            )
        }
        
        // Start timer
        startTimer()
    }
    
    func addTime(_ additionalTime: TimeInterval) {
        guard case .active(let startTime, let currentEndTime, let location) = state else { return }
        
        let newEndTime = currentEndTime.addingTimeInterval(additionalTime)
        state = .active(startTime: startTime, endTime: newEndTime, location: location)
        
        // Update stored end time
        UserDefaults.standard.set(newEndTime, forKey: "activeParkingEndTime")
        
        // Reschedule notifications
        notificationManager.cancelAllNotifications()
        Task {
            notificationManager.scheduleParkingNotifications(
                endTime: newEndTime,
                notificationTiming: settings.notificationTiming,
                soundEnabled: settings.soundEnabled
            )
        }
        
        // Provide haptic feedback
        if settings.hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    func endParking() {
        guard case .active(let startTime, _, let location) = state else { return }
        
        // Stop timer
        timer?.cancel()
        timer = nil
        
        // Stop location updates
        locationManager.stopLocationUpdates()
        
        // Cancel notifications
        notificationManager.cancelAllNotifications()
        
        // Create and save session
        let session = ParkingSession(
            startTime: startTime,
            endTime: Date(),
            location: location
        )
        persistenceManager.addParkingSession(session)
        
        // Clear stored active session
        UserDefaults.standard.removeObject(forKey: "activeParkingStartTime")
        UserDefaults.standard.removeObject(forKey: "activeParkingEndTime")
        UserDefaults.standard.removeObject(forKey: "activeParkingLat")
        UserDefaults.standard.removeObject(forKey: "activeParkingLon")
        UserDefaults.standard.removeObject(forKey: "activeParkingAddress")
        
        // Reset state
        state = .idle
        remainingTime = 0
        parkingLocation = nil
        
        // Provide haptic feedback
        if settings.hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func startTimer() {
        timer?.cancel()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func updateTimer() {
        guard case .active(_, let endTime, _) = state else { return }
        
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        
        if remaining <= 0 {
            // Parking expired
            endParking()
        } else {
            remainingTime = remaining
            objectWillChange.send()
        }
    }
    
    var progress: Double {
        guard case .active(let startTime, let endTime, _) = state else { return 0 }
        let totalDuration = endTime.timeIntervalSince(startTime)
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingTime / totalDuration)
    }
    
    var timeColor: Color {
        if remainingTime > 600 { // More than 10 minutes
            return .green
        } else if remainingTime > 300 { // More than 5 minutes
            return .yellow
        } else {
            return .red
        }
    }
    
    func refreshSettings() {
        settings = persistenceManager.loadAppSettings()
    }
}
