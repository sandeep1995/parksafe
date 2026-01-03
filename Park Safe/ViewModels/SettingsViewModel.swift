//
//  SettingsViewModel.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var defaultDurationHours: Int = 1
    @Published var defaultDurationMinutes: Int = 0
    
    private let persistenceManager = PersistenceManager.shared
    
    init() {
        self.settings = persistenceManager.loadAppSettings()
        updateDurationComponents()
    }
    
    private func updateDurationComponents() {
        let totalSeconds = Int(settings.defaultDuration)
        defaultDurationHours = totalSeconds / 3600
        defaultDurationMinutes = (totalSeconds % 3600) / 60
    }
    
    func saveSettings() {
        persistenceManager.saveAppSettings(settings)
    }
    
    func updateDefaultDuration() {
        settings.defaultDuration = TimeInterval(defaultDurationHours * 3600 + defaultDurationMinutes * 60)
        saveSettings()
    }
    
    func updateNotificationTiming(_ timing: NotificationTiming) {
        settings.notificationTiming = timing
        saveSettings()
    }
    
    func toggleSound() {
        settings.soundEnabled.toggle()
        saveSettings()
    }
    
    func toggleHaptics() {
        settings.hapticsEnabled.toggle()
        saveSettings()
    }
}
