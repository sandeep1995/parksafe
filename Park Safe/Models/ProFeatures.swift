//
//  ProFeatures.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 04/01/26.
//

import Foundation

/// Defines which features require Pro subscription
enum ProFeature: String, CaseIterable {
    case unlimitedHistory = "Unlimited History"
    case photoStorage = "Photo Storage"
    case costTracking = "Cost Tracking"
    case spendingAnalytics = "Spending Analytics"
    case exportData = "Export Data"
    case multipleVehicles = "Multiple Vehicles"
    case customNotifications = "Custom Notifications"
    
    var description: String {
        switch self {
        case .unlimitedHistory:
            return "Access your complete parking history"
        case .photoStorage:
            return "Save photos of your parking spot"
        case .costTracking:
            return "Track hourly rates and total costs"
        case .spendingAnalytics:
            return "View detailed spending reports"
        case .exportData:
            return "Export history to CSV or PDF"
        case .multipleVehicles:
            return "Track parking for multiple vehicles"
        case .customNotifications:
            return "Customize notification sounds and timing"
        }
    }
    
    var iconName: String {
        switch self {
        case .unlimitedHistory:
            return "clock.arrow.circlepath"
        case .photoStorage:
            return "camera.fill"
        case .costTracking:
            return "dollarsign.circle.fill"
        case .spendingAnalytics:
            return "chart.bar.fill"
        case .exportData:
            return "square.and.arrow.up.fill"
        case .multipleVehicles:
            return "car.2.fill"
        case .customNotifications:
            return "bell.badge.fill"
        }
    }
}

/// Free tier limits
enum FreeTierLimits {
    static let maxHistoryItems = 10
    static let maxPhotos = 3
}
