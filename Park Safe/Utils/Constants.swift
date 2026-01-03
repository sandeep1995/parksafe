//
//  Constants.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation

enum Constants {
    static let parkingSessionsKey = "parkingSessions"
    static let appSettingsKey = "appSettings"
    
    static let presetDurations: [TimeInterval] = [
        900,      // 15 minutes
        1800,     // 30 minutes
        3600,     // 1 hour
        7200      // 2 hours
    ]
    
    static let addTimeOptions: [TimeInterval] = [
        900,      // +15 minutes
        1800,     // +30 minutes
        3600      // +1 hour
    ]
    
    enum NotificationIdentifiers {
        static let warning10Min = "parkingWarning10Min"
        static let warning5Min = "parkingWarning5Min"
        static let expired = "parkingExpired"
    }
}
