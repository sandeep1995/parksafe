//
//  SettingsView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var parkingViewModel: ParkingSessionViewModel
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                Form {
                    // Subscription section
                    Section {
                        if subscriptionManager.subscriptionStatus == .subscribed {
                            HStack {
                                Label {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("ParkSafe Pro")
                                                .fontWeight(.semibold)
                                            ProBadge()
                                        }
                                        Text("Active subscription")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Button("Manage Subscription") {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(.blue)
                        } else {
                            HStack {
                                Label {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if subscriptionManager.isTrialExpired {
                                            Text("Trial Expired")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text("Subscribe to continue using ParkSafe")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Trial Active")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text("\(subscriptionManager.trialDaysRemaining) days remaining")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } icon: {
                                    Image(systemName: subscriptionManager.isTrialExpired ? "clock.badge.exclamationmark" : "clock.fill")
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                if subscriptionManager.isTrialExpired {
                                    Text("Subscribe")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Text(subscriptionManager.isTrialExpired ? "Subscribe Now" : "View Subscription")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                            
                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    } header: {
                        Text("Subscription")
                    }
                    .listRowBackground(Theme.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Notifications section
                    Section {
                        Picker("Warning Time", selection: Binding(
                            get: { viewModel.settings.notificationTiming },
                            set: { viewModel.updateNotificationTiming($0) }
                        )) {
                            ForEach(NotificationTiming.allCases, id: \.self) { timing in
                                Text(timing.displayName).tag(timing)
                            }
                        }
                        
                        Toggle(isOn: Binding(
                            get: { viewModel.settings.soundEnabled },
                            set: { _ in viewModel.toggleSound() }
                        )) {
                            Label {
                                Text("Sound")
                            } icon: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Custom notification sound
                        Picker("Notification Sound", selection: Binding(
                            get: { viewModel.settings.notificationSound },
                            set: { viewModel.updateNotificationSound($0) }
                        )) {
                            ForEach(NotificationSound.allCases, id: \.self) { sound in
                                Text(sound.displayName).tag(sound)
                            }
                        }
                        
                        Toggle(isOn: Binding(
                            get: { viewModel.settings.hapticsEnabled },
                            set: { _ in viewModel.toggleHaptics() }
                        )) {
                            Label {
                                Text("Haptic Feedback")
                            } icon: {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                    } header: {
                        Text("Notifications")
                    } footer: {
                        Text("Get notified before your parking expires")
                    }
                    .listRowBackground(Theme.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Location section
                    Section {
                        HStack {
                            Label {
                                Text("Location Access")
                            } icon: {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            statusBadge(for: locationManager.authorizationStatus)
                        }
                        
                        if locationManager.authorizationStatus != .authorizedWhenInUse &&
                           locationManager.authorizationStatus != .authorizedAlways {
                            Button("Request Access") {
                                locationManager.requestAuthorization()
                            }
                            .foregroundColor(.blue)
                        }
                    } header: {
                        Text("Location")
                    } footer: {
                        Text("Location is used to remember where you parked")
                    }
                    .listRowBackground(Theme.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Notification Permissions
                    Section {
                        HStack {
                            Label {
                                Text("Notification Access")
                            } icon: {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            statusBadge(for: notificationManager.authorizationStatus)
                        }
                        
                        if notificationManager.authorizationStatus != .authorized {
                            Button("Request Access") {
                                Task {
                                    await notificationManager.requestAuthorization()
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    } header: {
                        Text("Permissions")
                    }
                    .listRowBackground(Theme.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // About section
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle.fill")
                            Spacer()
                            Text("1.0")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Build", systemImage: "hammer.fill")
                            Spacer()
                            Text("1")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("About")
                    }
                    .listRowBackground(Theme.cardBackground)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .scrollContentBackground(.hidden)
                .formStyle(.grouped)
                .environment(\.horizontalSizeClass, .compact)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private func statusBadge(for status: CLAuthorizationStatus) -> some View {
        Text(statusText(status))
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .cornerRadius(5)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    
    private func statusBadge(for status: UNAuthorizationStatus) -> some View {
        Text(notificationStatusText(status))
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(notificationStatusColor(status).opacity(0.15))
            .foregroundColor(notificationStatusColor(status))
            .cornerRadius(5)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    
    private func statusText(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }
    
    private func statusColor(_ status: CLAuthorizationStatus) -> Color {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
    
    private func notificationStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Set"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func notificationStatusColor(_ status: UNAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .provisional, .ephemeral: return .blue
        @unknown default: return .gray
        }
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(),
        locationManager: LocationManager(),
        notificationManager: NotificationManager.shared,
        parkingViewModel: ParkingSessionViewModel(
            locationManager: LocationManager(),
            notificationManager: NotificationManager.shared
        )
    )
}
