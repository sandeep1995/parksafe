//
//  ActiveParkingView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import MapKit

struct ActiveParkingView: View {
    @ObservedObject var viewModel: ParkingSessionViewModel
    @State private var showAddTimeMenu = false
    @State private var showMapView = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Timer Card
            VStack(spacing: 30) {
                // Progress Ring
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color(.systemGray6), lineWidth: 20)
                        .frame(width: 260, height: 260)
                    
                    // Shadow for depth
                    Circle()
                        .stroke(viewModel.timeColor.opacity(0.2), lineWidth: 20)
                        .frame(width: 260, height: 260)
                        .blur(radius: 5)
                    
                    // Progress
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [viewModel.timeColor.opacity(0.8), viewModel.timeColor]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 260, height: 260)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.progress)
                        .shadow(color: viewModel.timeColor.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    // Time Text
                    VStack(spacing: 5) {
                        Text(viewModel.remainingTime.formattedDuration())
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText(value: viewModel.remainingTime))
                        
                        Text("REMAINING")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(2)
                    }
                }
                .padding(.top, 10)
                
                // Location Info
                VStack(spacing: 12) {
                    Label {
                        Text(viewModel.parkingLocation?.address ?? viewModel.currentAddress)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                    } icon: {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if viewModel.parkingLocation != nil {
                        Button(action: {
                            showMapView = true
                            hapticFeedback()
                        }) {
                            Text("Find My Car")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $showMapView) {
                            if let location = viewModel.parkingLocation {
                                MapView(location: location)
                            }
                        }
                    }
                }
            }
            .modernCard()
            
            // Actions Grid
            HStack(spacing: 15) {
                Menu {
                    ForEach(Constants.addTimeOptions, id: \.self) { duration in
                        Button(action: {
                            viewModel.addTime(duration)
                            hapticFeedback()
                        }) {
                            Label("+\(duration.displayName())", systemImage: "clock.badge.plus")
                        }
                    }
                } label: {
                    VStack {
                        Image(systemName: "clock.badge.plus.fill")
                            .font(.title2)
                        Text("Add Time")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.orange.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(Theme.cornerRadius)
                    .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                }
                
                Button(action: {
                    withAnimation {
                        viewModel.endParking()
                    }
                    hapticFeedback()
                }) {
                    VStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                        Text("End Session")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.red.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(Theme.cornerRadius)
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    let viewModel = ParkingSessionViewModel(
        locationManager: LocationManager(),
        notificationManager: NotificationManager.shared
    )
    viewModel.state = .active(
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        location: nil
    )
    viewModel.remainingTime = 3600
    return ActiveParkingView(viewModel: viewModel)
        .padding()
        .background(Theme.background)
}
