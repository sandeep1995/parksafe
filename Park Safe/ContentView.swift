//
//  ContentView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var parkingViewModel: ParkingSessionViewModel
    @StateObject private var historyViewModel = HistoryViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedPermissionOnboarding")
    
    init() {
        let locationMgr = LocationManager()
        let notificationMgr = NotificationManager.shared
        _locationManager = StateObject(wrappedValue: locationMgr)
        _notificationManager = StateObject(wrappedValue: notificationMgr)
        _parkingViewModel = StateObject(wrappedValue: ParkingSessionViewModel(
            locationManager: locationMgr,
            notificationManager: notificationMgr
        ))
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainAppView
            } else {
                PermissionOnboardingView(
                    locationManager: locationManager,
                    notificationManager: notificationManager,
                    hasCompletedOnboarding: $hasCompletedOnboarding
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
    
    private var mainAppView: some View {
        TabView {
            HomeView(viewModel: parkingViewModel)
                .tabItem {
                    Label("Home", systemImage: "car.fill")
                }
                .accessibilityLabel("Home tab")
            
            HistoryView(viewModel: historyViewModel)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .accessibilityLabel("History tab")
            
            SettingsView(
                viewModel: settingsViewModel,
                locationManager: locationManager,
                notificationManager: notificationManager,
                parkingViewModel: parkingViewModel
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .accessibilityLabel("Settings tab")
        }
        .onAppear {
            // Refresh settings when settings change
            parkingViewModel.refreshSettings()
        }
        .onChange(of: settingsViewModel.settings) { _, _ in
            parkingViewModel.refreshSettings()
        }
        .onChange(of: parkingViewModel.state) { _, newState in
            // Reload history when parking session ends
            if case .idle = newState {
                historyViewModel.loadSessions()
            }
        }
    }
}

#Preview {
    ContentView()
}
