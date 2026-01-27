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
    @State private var showPhotoFullScreen = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }
    
    private var timerFontSize: CGFloat {
        if isCompactHeight {
            return 48
        }
        return horizontalSizeClass == .compact ? 56 : 72
    }
    
    private var contentSpacing: CGFloat {
        isCompactHeight ? 12 : 16
    }
    
    private var buttonSpacing: CGFloat {
        horizontalSizeClass == .compact ? 12 : 20
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.width < 375
            let dynamicSpacing = isSmallScreen ? 12.0 : 16.0
            
            VStack(spacing: dynamicSpacing) {
                // Timer Display
                VStack(spacing: 8) {
                    // Time Display - uses ViewThatFits to auto-scale
                    Text(viewModel.remainingTime.formattedDuration())
                        .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.timeColor)
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: viewModel.remainingTime))
                    
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .padding(.vertical, isSmallScreen ? 12 : 16)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .modernCard()
                
                // Location
                if let location = viewModel.parkingLocation {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(location.address)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            Spacer()
                        }
                        
                        Button(action: {
                            showMapView = true
                            hapticFeedback()
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Show on Map")
                            }
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.accentColor)
                        }
                    }
                    .padding(isSmallScreen ? 10 : 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Optional Details (simplified)
                if hasOptionalDetails {
                    VStack(spacing: 8) {
                        if let photo = viewModel.parkingPhoto {
                            Button(action: {
                                showPhotoFullScreen = true
                            }) {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: isSmallScreen ? 80 : 100)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            if !viewModel.floor.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.fill")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                    Text(viewModel.floor)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            if !viewModel.section.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.grid.2x2.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text(viewModel.section)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            if let cost = viewModel.formattedCurrentCost {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(cost)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(isSmallScreen ? 10 : 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer(minLength: 8)
                
                // Actions
                HStack(spacing: buttonSpacing) {
                    Menu {
                        ForEach(Constants.addTimeOptions, id: \.self) { duration in
                            Button(action: {
                                viewModel.addTime(duration)
                                hapticFeedback()
                            }) {
                                Label("+\(duration.displayName())", systemImage: "plus.circle")
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Time")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isSmallScreen ? 12 : 14)
                        .padding(.horizontal, 8)
                        .background(Color.orange.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    
                    Button(action: {
                        withAnimation {
                            viewModel.endParking()
                        }
                        hapticFeedback()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                            Text("End")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isSmallScreen ? 12 : 14)
                        .padding(.horizontal, 8)
                        .background(Color.red.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal, isSmallScreen ? 12 : 16)
            .padding(.vertical, isSmallScreen ? 8 : 12)
        }
        .sheet(isPresented: $showMapView) {
            if let location = viewModel.parkingLocation {
                MapView(location: location)
            }
        }
        .fullScreenCover(isPresented: $showPhotoFullScreen) {
            if let photo = viewModel.parkingPhoto {
                PhotoFullScreenView(image: photo)
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - Optional Details
    
    private var hasOptionalDetails: Bool {
        viewModel.parkingPhoto != nil ||
        viewModel.hourlyRate != nil ||
        !viewModel.floor.isEmpty ||
        !viewModel.section.isEmpty
    }
}

// MARK: - Photo Full Screen View

struct PhotoFullScreenView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
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
