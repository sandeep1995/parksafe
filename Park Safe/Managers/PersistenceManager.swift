//
//  PersistenceManager.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Parking Sessions
    
    func saveParkingSessions(_ sessions: [ParkingSession]) {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: Constants.parkingSessionsKey)
        }
    }
    
    func loadParkingSessions() -> [ParkingSession] {
        guard let data = userDefaults.data(forKey: Constants.parkingSessionsKey),
              let sessions = try? JSONDecoder().decode([ParkingSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.startTime > $1.startTime } // Most recent first
    }
    
    func addParkingSession(_ session: ParkingSession) {
        var sessions = loadParkingSessions()
        sessions.insert(session, at: 0) // Add to beginning
        saveParkingSessions(sessions)
    }
    
    func deleteParkingSession(_ session: ParkingSession) {
        var sessions = loadParkingSessions()
        sessions.removeAll { $0.id == session.id }
        saveParkingSessions(sessions)
    }
    
    // MARK: - App Settings
    
    func saveAppSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Constants.appSettingsKey)
        }
    }
    
    func loadAppSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: Constants.appSettingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings.default
        }
        return settings
    }
}
