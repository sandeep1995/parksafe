//
//  NotificationManager.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleParkingNotifications(endTime: Date, notificationTiming: NotificationTiming, soundEnabled: Bool) {
        // Cancel any existing notifications
        cancelAllNotifications()
        
        let now = Date()
        
        // Calculate notification times
        let warning10MinTime = endTime.addingTimeInterval(-600) // 10 minutes before
        let warning5MinTime = endTime.addingTimeInterval(-300)  // 5 minutes before
        
        // Schedule 10-minute warning if applicable
        if warning10MinTime > now && notificationTiming.rawValue <= 10 {
            scheduleNotification(
                identifier: Constants.NotificationIdentifiers.warning10Min,
                title: "Parking Reminder",
                body: "Your parking expires in 10 minutes",
                date: warning10MinTime,
                soundEnabled: soundEnabled
            )
        }
        
        // Schedule 5-minute warning if applicable
        if warning5MinTime > now && notificationTiming.rawValue <= 5 {
            scheduleNotification(
                identifier: Constants.NotificationIdentifiers.warning5Min,
                title: "Parking Reminder",
                body: "Your parking expires in 5 minutes",
                date: warning5MinTime,
                soundEnabled: soundEnabled
            )
        }
        
        // Schedule expiry notification
        if endTime > now {
            scheduleNotification(
                identifier: Constants.NotificationIdentifiers.expired,
                title: "Parking Expired",
                body: "Your parking time has expired. Please move your vehicle.",
                date: endTime,
                soundEnabled: soundEnabled
            )
        }
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date, soundEnabled: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil
        content.badge = 1
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelAllNotifications() {
        let identifiers = [
            Constants.NotificationIdentifiers.warning10Min,
            Constants.NotificationIdentifiers.warning5Min,
            Constants.NotificationIdentifiers.expired
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

