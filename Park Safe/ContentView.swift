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
            // Request permissions on first launch
            requestPermissions()
            
            // Refresh settings when settings change
            parkingViewModel.refreshSettings()
        }
        .onChange(of: settingsViewModel.settings) { _, _ in
            parkingViewModel.refreshSettings()
        }
    }
    
    private func requestPermissions() {
        // Request location authorization
        locationManager.requestAuthorization()
        
        // Request notification authorization
        Task {
            await notificationManager.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
