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
    @State private var showMapView = false
    
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
                                        if session.location != nil {
                                            selectedSession = session
                                            showMapView = true
                                        }
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
            .sheet(isPresented: $showMapView) {
                if let session = selectedSession, let location = session.location {
                    MapView(location: location)
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
                
                StatItem(
                    value: "\(viewModel.estimatedTicketsAvoided)",
                    label: "Saved",
                    icon: "checkmark.shield.fill",
                    color: .green
                )
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
        HStack {
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
                
                if session.location != nil {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HistoryView(viewModel: HistoryViewModel())
}
