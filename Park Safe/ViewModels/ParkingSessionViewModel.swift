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
import ActivityKit

enum ParkingState: Equatable {
    case idle
    case active(startTime: Date, endTime: Date, location: LocationData?)
    
    static func == (lhs: ParkingState, rhs: ParkingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.active(let lStart, let lEnd, _), .active(let rStart, let rEnd, _)):
            return lStart == rStart && lEnd == rEnd
        default:
            return false
        }
    }
}

class ParkingSessionViewModel: ObservableObject {
    @Published var state: ParkingState = .idle
    @Published var selectedDuration: TimeInterval = 3600 // Default 1 hour
    @Published var remainingTime: TimeInterval = 0
    @Published var currentAddress: String = "Locating..."
    @Published var parkingLocation: LocationData?
    
    // Optional parking details
    @Published var parkingPhoto: UIImage?
    @Published var hourlyRate: Double?
    @Published var floor: String = ""
    @Published var section: String = ""
    
    private var timer: AnyCancellable?
    private var photoFileName: String?
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
            
            // Restore optional details
            hourlyRate = UserDefaults.standard.object(forKey: "activeParkingHourlyRate") as? Double
            floor = UserDefaults.standard.string(forKey: "activeParkingFloor") ?? ""
            section = UserDefaults.standard.string(forKey: "activeParkingSection") ?? ""
            photoFileName = UserDefaults.standard.string(forKey: "activeParkingPhotoFileName")
            
            // Load photo if exists
            if let fileName = photoFileName {
                parkingPhoto = loadPhoto(fileName: fileName)
            }
            
            startParking(startTime: storedStartTime, endTime: storedEndTime, location: location)
            
            // Restore Live Activity if available
            if #available(iOS 16.1, *) {
                // Check for existing activity, if not found start a new one
                let activities = Activity<ParkingActivityAttributes>.activities
                if activities.isEmpty {
                    startLiveActivity(startTime: storedStartTime, endTime: storedEndTime, location: location)
                }
            }
        }
    }
    
    // MARK: - Photo Management
    
    private func savePhoto(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }
    
    func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Calculate current cost based on elapsed time
    var currentCost: Double? {
        guard let rate = hourlyRate,
              case .active(let startTime, _, _) = state else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = elapsed / 3600
        return hours * rate
    }
    
    var formattedCurrentCost: String? {
        guard let cost = currentCost else { return nil }
        return String(format: "$%.2f", cost)
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
        
        // Save photo if provided
        if let photo = parkingPhoto {
            photoFileName = savePhoto(photo)
        }
        
        // Store active session
        UserDefaults.standard.set(start, forKey: "activeParkingStartTime")
        UserDefaults.standard.set(end, forKey: "activeParkingEndTime")
        if let loc = parkingLocation {
            UserDefaults.standard.set(loc.latitude, forKey: "activeParkingLat")
            UserDefaults.standard.set(loc.longitude, forKey: "activeParkingLon")
            UserDefaults.standard.set(loc.address, forKey: "activeParkingAddress")
        }
        
        // Store optional details
        if let rate = hourlyRate {
            UserDefaults.standard.set(rate, forKey: "activeParkingHourlyRate")
        }
        if !floor.isEmpty {
            UserDefaults.standard.set(floor, forKey: "activeParkingFloor")
        }
        if !section.isEmpty {
            UserDefaults.standard.set(section, forKey: "activeParkingSection")
        }
        if let fileName = photoFileName {
            UserDefaults.standard.set(fileName, forKey: "activeParkingPhotoFileName")
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
        
        // Start Live Activity for Dynamic Island
        if #available(iOS 16.1, *) {
            startLiveActivity(startTime: start, endTime: end, location: parkingLocation)
        }
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
        
        // Update Live Activity
        if #available(iOS 16.1, *) {
            updateLiveActivity(endTime: newEndTime)
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
            location: location,
            photoFileName: photoFileName,
            hourlyRate: hourlyRate,
            floor: floor.isEmpty ? nil : floor,
            section: section.isEmpty ? nil : section
        )
        persistenceManager.addParkingSession(session)
        
        // Clear stored active session
        UserDefaults.standard.removeObject(forKey: "activeParkingStartTime")
        UserDefaults.standard.removeObject(forKey: "activeParkingEndTime")
        UserDefaults.standard.removeObject(forKey: "activeParkingLat")
        UserDefaults.standard.removeObject(forKey: "activeParkingLon")
        UserDefaults.standard.removeObject(forKey: "activeParkingAddress")
        UserDefaults.standard.removeObject(forKey: "activeParkingHourlyRate")
        UserDefaults.standard.removeObject(forKey: "activeParkingFloor")
        UserDefaults.standard.removeObject(forKey: "activeParkingSection")
        UserDefaults.standard.removeObject(forKey: "activeParkingPhotoFileName")
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }
        
        // Reset state
        state = .idle
        remainingTime = 0
        parkingLocation = nil
        
        // Reset optional details
        parkingPhoto = nil
        photoFileName = nil
        hourlyRate = nil
        floor = ""
        section = ""
        
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
            
            // Update Live Activity periodically (every 30 seconds) for color changes
            // The timer countdown uses Text(.timer) which updates automatically
            if #available(iOS 16.1, *) {
                let secondsRemaining = Int(remaining)
                // Update at color transition points (10 min, 5 min) or every 30 seconds
                if secondsRemaining == 600 || secondsRemaining == 300 || secondsRemaining % 30 == 0 {
                    updateLiveActivityRemainingTime(remaining)
                }
            }
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
    
    // MARK: - Live Activity Management
    
    @available(iOS 16.1, *)
    private func startLiveActivity(startTime: Date, endTime: Date, location: LocationData?) {
        // End any existing activities first
        for activity in Activity<ParkingActivityAttributes>.activities {
            Task {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        
        let attributes = ParkingActivityAttributes(
            startTime: startTime,
            location: location?.address
        )
        
        let initialContentState = ParkingActivityAttributes.ContentState(
            remainingTime: endTime.timeIntervalSince(Date()),
            endTime: endTime
        )
        
        // Configure activity content with stale date (when timer expires)
        let activityContent = ActivityContent(
            state: initialContentState,
            staleDate: endTime,  // Mark as stale when parking expires
            relevanceScore: 100  // High relevance to keep it visible
        )
        
        do {
            _ = try Activity<ParkingActivityAttributes>.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivity(endTime: Date) {
        let activities = Activity<ParkingActivityAttributes>.activities
        guard let activity = activities.first else { return }
        
        let updatedContentState = ParkingActivityAttributes.ContentState(
            remainingTime: endTime.timeIntervalSince(Date()),
            endTime: endTime
        )
        
        let activityContent = ActivityContent(
            state: updatedContentState,
            staleDate: endTime,
            relevanceScore: 100
        )
        
        Task {
            await activity.update(activityContent)
        }
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivityRemainingTime(_ remaining: TimeInterval) {
        let activities = Activity<ParkingActivityAttributes>.activities
        guard let activity = activities.first,
              case .active(_, let endTime, _) = state else { return }
        
        let updatedContentState = ParkingActivityAttributes.ContentState(
            remainingTime: remaining,
            endTime: endTime
        )
        
        // Use higher relevance when time is running low to keep it prominent
        let relevanceScore: Double = remaining < 300 ? 100 : 75
        
        let activityContent = ActivityContent(
            state: updatedContentState,
            staleDate: endTime,
            relevanceScore: relevanceScore
        )
        
        Task {
            await activity.update(activityContent)
        }
    }
    
    @available(iOS 16.1, *)
    private func endLiveActivity() {
        let activities = Activity<ParkingActivityAttributes>.activities
        guard let activity = activities.first else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
    }
}
