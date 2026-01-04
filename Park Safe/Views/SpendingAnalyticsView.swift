//
//  SpendingAnalyticsView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 04/01/26.
//

import SwiftUI
import Charts

struct SpendingAnalyticsView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    summarySection
                    
                    // Monthly Spending Chart
                    if !monthlySpending.isEmpty {
                        chartSection
                    }
                    
                    // Breakdown by Location
                    locationBreakdownSection
                    
                    // Recent Expensive Sessions
                    topSessionsSection
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Spending Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                SummaryCard(
                    title: "Total Spent",
                    value: viewModel.formattedTotalSpent,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "Avg per Session",
                    value: formattedAveragePerSession,
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Total Hours",
                    value: String(format: "%.1fh", viewModel.totalHoursParked),
                    icon: "clock.fill",
                    color: .purple
                )
                
                SummaryCard(
                    title: "Sessions",
                    value: "\(viewModel.totalSessions)",
                    icon: "car.fill",
                    color: .orange
                )
            }
        }
        .modernCard()
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Spending")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart(monthlySpending) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .modernCard()
    }
    
    // MARK: - Location Breakdown
    
    private var locationBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Locations")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if locationBreakdown.isEmpty {
                Text("No location data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(locationBreakdown.prefix(5), id: \.location) { item in
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.location)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text("\(item.visits) visits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", item.totalSpent))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                    
                    if item.location != locationBreakdown.prefix(5).last?.location {
                        Divider()
                    }
                }
            }
        }
        .modernCard()
    }
    
    // MARK: - Top Sessions
    
    private var topSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Expensive Sessions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            let expensiveSessions = viewModel.sessions
                .filter { $0.totalCost != nil }
                .sorted { ($0.totalCost ?? 0) > ($1.totalCost ?? 0) }
                .prefix(5)
            
            if expensiveSessions.isEmpty {
                Text("No cost data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(expensiveSessions), id: \.id) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.formattedDate)
                                .font(.subheadline)
                            Text(session.truncatedAddress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(session.formattedCost ?? "$0.00")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text(session.formattedDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if session.id != expensiveSessions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .modernCard()
    }
    
    // MARK: - Computed Properties
    
    private var formattedAveragePerSession: String {
        guard viewModel.totalSessions > 0 else { return "$0.00" }
        let sessionsWithCost = viewModel.sessions.filter { $0.totalCost != nil }
        guard !sessionsWithCost.isEmpty else { return "$0.00" }
        let average = viewModel.totalSpent / Double(sessionsWithCost.count)
        return String(format: "$%.2f", average)
    }
    
    private var monthlySpending: [MonthlySpending] {
        let calendar = Calendar.current
        var spending: [String: Double] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        for session in viewModel.sessions {
            if let cost = session.totalCost {
                let month = dateFormatter.string(from: session.startTime)
                spending[month, default: 0] += cost
            }
        }
        
        // Get last 6 months
        let now = Date()
        var months: [MonthlySpending] = []
        
        for i in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                let month = dateFormatter.string(from: date)
                months.append(MonthlySpending(month: month, amount: spending[month] ?? 0))
            }
        }
        
        return months
    }
    
    private var locationBreakdown: [LocationSpending] {
        var breakdown: [String: (visits: Int, spent: Double)] = [:]
        
        for session in viewModel.sessions {
            let location = session.truncatedAddress
            let cost = session.totalCost ?? 0
            
            if var existing = breakdown[location] {
                existing.visits += 1
                existing.spent += cost
                breakdown[location] = existing
            } else {
                breakdown[location] = (visits: 1, spent: cost)
            }
        }
        
        return breakdown.map { LocationSpending(location: $0.key, visits: $0.value.visits, totalSpent: $0.value.spent) }
            .sorted { $0.totalSpent > $1.totalSpent }
    }
}

// MARK: - Supporting Types

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct LocationSpending {
    let location: String
    let visits: Int
    let totalSpent: Double
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SpendingAnalyticsView(viewModel: HistoryViewModel())
}
