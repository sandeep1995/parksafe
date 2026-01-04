//
//  AppSettings.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation

enum NotificationTiming: Int, CaseIterable, Codable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case thirtyMinutes = 30
    
    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .twentyMinutes: return "20 minutes"
        case .thirtyMinutes: return "30 minutes"
        }
    }
    
    // Free tier only gets first 3 options
    static var freeOptions: [NotificationTiming] {
        [.fiveMinutes, .tenMinutes, .fifteenMinutes]
    }
    
    // Pro gets all options
    static var proOptions: [NotificationTiming] {
        allCases
    }
}

enum NotificationSound: String, CaseIterable, Codable {
    case defaultSound = "default"
    case chime = "chime"
    case bell = "bell"
    case alert = "alert"
    case gentle = "gentle"
    
    var displayName: String {
        switch self {
        case .defaultSound: return "Default"
        case .chime: return "Chime"
        case .bell: return "Bell"
        case .alert: return "Alert"
        case .gentle: return "Gentle"
        }
    }
    
    var systemSoundName: String {
        switch self {
        case .defaultSound: return "default"
        case .chime: return "chime"
        case .bell: return "bell"
        case .alert: return "alert"
        case .gentle: return "gentle"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var notificationTiming: NotificationTiming
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var notificationSound: NotificationSound
    var additionalReminders: [Int] // Minutes before expiry for additional reminders (Pro only)
    
    static let `default` = AppSettings(
        notificationTiming: .tenMinutes,
        soundEnabled: true,
        hapticsEnabled: true,
        notificationSound: .defaultSound,
        additionalReminders: []
    )
}
