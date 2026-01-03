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
    
    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var notificationTiming: NotificationTiming
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var defaultDuration: TimeInterval
    
    static let `default` = AppSettings(
        notificationTiming: .tenMinutes,
        soundEnabled: true,
        hapticsEnabled: true,
        defaultDuration: 3600 // 1 hour
    )
}
