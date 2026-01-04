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
    
    private let persistenceManager = PersistenceManager.shared
    
    init() {
        self.settings = persistenceManager.loadAppSettings()
    }
    
    func saveSettings() {
        persistenceManager.saveAppSettings(settings)
    }
    
    func updateNotificationTiming(_ timing: NotificationTiming) {
        settings.notificationTiming = timing
        saveSettings()
    }
    
    func updateNotificationSound(_ sound: NotificationSound) {
        settings.notificationSound = sound
        saveSettings()
    }
    
    func updateAdditionalReminders(_ reminders: [Int]) {
        settings.additionalReminders = reminders
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
