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
    @State private var showAnalytics = false
    @State private var showExport = false
    
    // All features available - no limits
    private var displaySections: [HistorySection] {
        return viewModel.sections
    }
    
    private var hiddenSessionsCount: Int {
        return 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if viewModel.displayedSessions.isEmpty && !viewModel.isLoadingMore {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Parking History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Your parking sessions will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        // Stats card
                        Section {
                            statsCard
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .padding(.bottom, 10)
                        }
                        
                        // Analytics & Export Actions
                        Section {
                            proActionsRow
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                        
                        // History sections
                        ForEach(displaySections) { section in
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
                                            // Store the session directly - it's already loaded and displayed
                                            selectedSession = session
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
                                        .onAppear {
                                            // Load more when reaching the last 5 items of all displayed sessions
                                            if let index = viewModel.displayedSessions.firstIndex(where: { $0.id == session.id }) {
                                                let totalDisplayed = viewModel.displayedSessions.count
                                                if totalDisplayed > 0 && index >= totalDisplayed - 5 {
                                                    viewModel.loadMoreSessions()
                                                }
                                            }
                                        }
                                }
                            }
                        }
                        
                        // Loading indicator at bottom
                        if viewModel.isLoadingMore {
                            Section {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        
                        // End of list indicator
                        if !viewModel.hasMoreSessions && !viewModel.displayedSessions.isEmpty {
                            Section {
                                HStack {
                                    Spacer()
                                    Text("All sessions loaded")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .onAppear {
                // Reload sessions when view appears
                viewModel.loadSessions()
            }
            .refreshable {
                viewModel.loadSessions()
            }
            .sheet(item: $selectedSession) { session in
                ParkingSessionDetailView(session: session)
            }
            .sheet(isPresented: $showAnalytics) {
                SpendingAnalyticsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showExport) {
                ExportView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Analytics & Export Actions Row
    
    private var proActionsRow: some View {
        HStack(spacing: 12) {
            // Analytics Button
            Button {
                showAnalytics = true
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.purple)
                    Text("Analytics")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .foregroundColor(.primary)
            
            // Export Button
            Button {
                showExport = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(Theme.accentColor)
                    Text("Export")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .foregroundColor(.primary)
        }
        .padding(.horizontal)
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
                    color: Theme.accentColor
                )
                
                Divider()
                    .padding(.vertical, 10)
                
                StatItem(
                    value: String(format: "%.1f", viewModel.totalHoursParked),
                    label: "Hours",
                    icon: "clock.fill",
                    color: Theme.accentColor
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
                    .background(Theme.accentColor.opacity(0.1))
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
                            .foregroundColor(Theme.accentColor)
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
