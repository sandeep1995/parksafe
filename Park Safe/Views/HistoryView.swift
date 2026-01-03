//
//  HistoryView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @State private var selectedSession: ParkingSession?
    @State private var showDetailView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    // Stats card
                    Section {
                        statsCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.bottom, 10)
                    }
                    
                    // History sections
                    ForEach(viewModel.sections) { section in
                        Section(header: Text(section.title)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .textCase(nil)
                        ) {
                            ForEach(section.sessions) { session in
                                ParkingSessionRow(session: session)
                                    .listRowBackground(Theme.cardBackground)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedSession = session
                                        showDetailView = true
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                viewModel.deleteSession(session)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.loadSessions()
            }
            .refreshable {
                viewModel.loadSessions()
            }
            .sheet(isPresented: $showDetailView) {
                if let session = selectedSession {
                    ParkingSessionDetailView(session: session)
                }
            }
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(spacing: 0) {
                StatItem(
                    value: "\(viewModel.totalSessions)",
                    label: "Sessions",
                    icon: "car.fill",
                    color: .blue
                )
                
                Divider()
                    .padding(.vertical, 10)
                
                StatItem(
                    value: String(format: "%.1f", viewModel.totalHoursParked),
                    label: "Hours",
                    icon: "clock.fill",
                    color: .purple
                )
                
                Divider()
                    .padding(.vertical, 10)
                
                if viewModel.hasSpendingData {
                    StatItem(
                        value: viewModel.formattedTotalSpent,
                        label: "Spent",
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                } else {
                    StatItem(
                        value: "\(viewModel.estimatedTicketsAvoided)",
                        label: "Saved",
                        icon: "checkmark.shield.fill",
                        color: .green
                    )
                }
            }
        }
        .modernCard()
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ParkingSessionRow: View {
    let session: ParkingSession
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.formattedDate)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(session.truncatedAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Optional details row
                if session.parkingSpotInfo != nil || session.formattedCost != nil {
                    HStack(spacing: 8) {
                        if let spotInfo = session.parkingSpotInfo {
                            HStack(spacing: 2) {
                                Image(systemName: "building.fill")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                Text(spotInfo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let cost = session.formattedCost {
                            HStack(spacing: 2) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(cost)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(session.formattedDuration)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                HStack(spacing: 4) {
                    if session.photoFileName != nil {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    if session.location != nil {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HistoryView(viewModel: HistoryViewModel())
}
