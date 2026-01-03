//
//  PermissionOnboardingView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct PermissionOnboardingView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var notificationManager: NotificationManager
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var isRequestingPermissions = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                if pages.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        PermissionPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                // Action buttons
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                currentPage += 1
                            }
                            hapticFeedback()
                        }) {
                            HStack {
                                Text("Continue")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(Theme.cornerRadius)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                    } else {
                        Button(action: {
                            requestAllPermissions()
                        }) {
                            HStack {
                                if isRequestingPermissions {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Enable Permissions")
                                        .fontWeight(.semibold)
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isRequestingPermissions ? Color.gray.gradient : Color.blue.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(Theme.cornerRadius)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(isRequestingPermissions)
                    }
                    
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                currentPage -= 1
                            }
                            hapticFeedback()
                        }) {
                            Text("Back")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var pages: [PermissionPage] {
        [
            PermissionPage(
                icon: "car.fill",
                iconColor: .blue,
                title: "Welcome to ParkSafe",
                description: "Never lose track of your parking spot again. ParkSafe helps you remember where you parked and alerts you before your time expires."
            ),
            PermissionPage(
                icon: "location.fill",
                iconColor: .green,
                title: "Location Access",
                description: "We need your location to remember where you parked your car. This helps you find your vehicle quickly when you return.\n\nYour location is only used while parking is active and is never shared."
            ),
            PermissionPage(
                icon: "bell.fill",
                iconColor: .orange,
                title: "Notifications",
                description: "Get timely reminders before your parking expires so you never get a ticket.\n\nYou can customize notification timing in settings."
            )
        ]
    }
    
    private func requestAllPermissions() {
        isRequestingPermissions = true
        hapticFeedback()
        
        // Request location permission
        locationManager.requestAuthorization()
        
        // Request notification permission
        Task {
            _ = await notificationManager.requestAuthorization()
            
            // Update notification status check
            notificationManager.checkAuthorizationStatus()
            
            await MainActor.run {
                // Small delay to show the button state and allow system dialogs to appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isRequestingPermissions = false
                    hasCompletedOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasCompletedPermissionOnboarding")
                }
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct PermissionPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct PermissionPageView: View {
    let page: PermissionPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(page.iconColor.gradient)
            }
            .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionOnboardingView(
        locationManager: LocationManager(),
        notificationManager: NotificationManager.shared,
        hasCompletedOnboarding: .constant(false)
    )
}
