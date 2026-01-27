//
//  HomeView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @ObservedObject var viewModel: ParkingSessionViewModel
    @State private var customHours = 0
    @State private var customMinutes = 15
    @State private var useCustomDuration = false
    
    // Optional details
    @State private var showOptionalDetails = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var hourlyRateText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if case .idle = viewModel.state {
                    ScrollView {
                        VStack(spacing: 25) {
                            idleView
                        }
                        .padding()
                    }
                } else {
                    ActiveParkingView(viewModel: viewModel)
                }
            }
            .navigationTitle("ParkSafe")
            .navigationBarTitleDisplayMode(.inline)
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
            
            // Optional Details Card
            VStack(spacing: 15) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showOptionalDetails.toggle()
                    }
                    hapticFeedback()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.accentColor)
                        Text("Add Details")
                            .fontWeight(.medium)
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(showOptionalDetails ? 90 : 0))
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                
                if showOptionalDetails {
                    VStack(spacing: 16) {
                        // Photo Section
                        photoSection
                        
                        Divider()
                        
                        // Parking Cost Section
                        costSection
                        
                        Divider()
                        
                        // Floor & Section
                        floorSectionInputs
                    }
                    .padding(.top, 8)
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
            .buttonStyle(ModernButtonStyle())
            .padding(.bottom)
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Photo of Parking Spot", systemImage: "camera.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if let photo = viewModel.parkingPhoto {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button(action: {
                        withAnimation {
                            viewModel.parkingPhoto = nil
                        }
                        hapticFeedback()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .red)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: {
                        showCamera = true
                        hapticFeedback()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Camera")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                            Text("Library")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.parkingPhoto = image
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $viewModel.parkingPhoto)
        }
    }
    
    // MARK: - Cost Section
    
    private var costSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hourly Rate", systemImage: "dollarsign.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Text("$")
                    .foregroundColor(.secondary)
                TextField("0.00", text: $hourlyRateText)
                    .keyboardType(.decimalPad)
                    .onChange(of: hourlyRateText) { _, newValue in
                        viewModel.hourlyRate = Double(newValue)
                    }
                Text("/ hour")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Floor & Section Inputs
    
    private var floorSectionInputs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Parking Location", systemImage: "building.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Floor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. P2", text: $viewModel.floor)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Section")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g. A", text: $viewModel.section)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
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
            .background(isSelected ? Theme.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Theme.accentColor : Color.clear, lineWidth: 2)
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
