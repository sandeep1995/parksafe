//
//  HomeView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: ParkingSessionViewModel
    @State private var customHours = 0
    @State private var customMinutes = 15
    @State private var useCustomDuration = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        if case .idle = viewModel.state {
                            idleView
                        } else {
                            ActiveParkingView(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ParkSafe")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 30) {
            // Time selection card
            VStack(spacing: 20) {
                Text("How long are you parking?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Preset buttons grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(Constants.presetDurations, id: \.self) { duration in
                        PresetDurationButton(
                            duration: duration,
                            isSelected: !useCustomDuration && viewModel.selectedDuration == duration,
                            action: {
                                withAnimation {
                                    useCustomDuration = false
                                    viewModel.selectedDuration = duration
                                }
                                hapticFeedback()
                            }
                        )
                    }
                }
                
                // Custom duration toggle
                Button(action: {
                    withAnimation {
                        useCustomDuration.toggle()
                        if useCustomDuration {
                            updateCustomDuration()
                        }
                    }
                    hapticFeedback()
                }) {
                    HStack {
                        Text("Custom Duration")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(useCustomDuration ? 90 : 0))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
                
                // Custom duration picker
                if useCustomDuration {
                    HStack {
                        Picker("Hours", selection: $customHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        
                        Picker("Minutes", selection: $customMinutes) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .onChange(of: customHours) { _, _ in updateCustomDuration() }
                    .onChange(of: customMinutes) { _, _ in updateCustomDuration() }
                    .padding(.horizontal)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                }
            }
            .modernCard()
            
            // Start button
            Button(action: startParking) {
                HStack {
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.title2)
                    Text("Start Parking")
                        .fontWeight(.bold)
                }
            }
            .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
            .padding(.bottom)
        }
    }
    
    private func updateCustomDuration() {
        viewModel.selectedDuration = TimeInterval(customHours * 3600 + customMinutes * 60)
    }
    
    private func startParking() {
        hapticFeedback()
        viewModel.startParking()
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct PresetDurationButton: View {
    let duration: TimeInterval
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                Text(duration.displayName())
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    HomeView(viewModel: ParkingSessionViewModel(
        locationManager: LocationManager(),
        notificationManager: NotificationManager.shared
    ))
}
