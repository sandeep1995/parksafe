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
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                Form {
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
                    
                    // Default duration section
                    Section {
                        HStack {
                            Label {
                                Text("Default Duration")
                            } icon: {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            
                            HStack {
                                Picker("", selection: $viewModel.defaultDurationHours) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour)h").tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .onChange(of: viewModel.defaultDurationHours) { _, _ in
                                    viewModel.updateDefaultDuration()
                                }
                                
                                Picker("", selection: $viewModel.defaultDurationMinutes) {
                                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                        Text("\(minute)m").tag(minute)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .onChange(of: viewModel.defaultDurationMinutes) { _, _ in
                                    viewModel.updateDefaultDuration()
                                }
                            }
                        }
                    } header: {
                        Text("Defaults")
                    }
                    .listRowBackground(Theme.cardBackground)
                    
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
    
    private func statusBadge(for status: CLAuthorizationStatus) -> some View {
        Text(statusText(status))
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .cornerRadius(6)
    }
    
    private func statusBadge(for status: UNAuthorizationStatus) -> some View {
        Text(notificationStatusText(status))
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(notificationStatusColor(status).opacity(0.15))
            .foregroundColor(notificationStatusColor(status))
            .cornerRadius(6)
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
