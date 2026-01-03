//
//  HistoryViewModel.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import Combine

struct HistorySection: Identifiable {
    let id: String
    let title: String
    let sessions: [ParkingSession]
}

class HistoryViewModel: ObservableObject {
    @Published var sessions: [ParkingSession] = []
    @Published var sections: [HistorySection] = []
    
    private let persistenceManager = PersistenceManager.shared
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        sessions = persistenceManager.loadParkingSessions()
        updateSections()
    }
    
    func deleteSession(_ session: ParkingSession) {
        persistenceManager.deleteParkingSession(session)
        loadSessions()
    }
    
    private func updateSections() {
        var todaySessions: [ParkingSession] = []
        var thisWeekSessions: [ParkingSession] = []
        var olderSessions: [ParkingSession] = []
        
        for session in sessions {
            if session.startTime.isToday() {
                todaySessions.append(session)
            } else if session.startTime.isThisWeek() {
                thisWeekSessions.append(session)
            } else {
                olderSessions.append(session)
            }
        }
        
        var newSections: [HistorySection] = []
        
        if !todaySessions.isEmpty {
            newSections.append(HistorySection(id: "today", title: "Today", sessions: todaySessions))
        }
        if !thisWeekSessions.isEmpty {
            newSections.append(HistorySection(id: "thisWeek", title: "This Week", sessions: thisWeekSessions))
        }
        if !olderSessions.isEmpty {
            newSections.append(HistorySection(id: "older", title: "Older", sessions: olderSessions))
        }
        
        sections = newSections
    }
    
    var totalSessions: Int {
        sessions.count
    }
    
    var totalHoursParked: Double {
        sessions.reduce(0) { $0 + $1.duration } / 3600
    }
    
    var estimatedTicketsAvoided: Int {
        // Estimate: assume average parking ticket is $50 and average parking cost is $2/hour
        // This is a rough estimate - can be adjusted
        let totalCost = totalHoursParked * 2.0
        let estimatedTickets = Int(totalCost / 50.0)
        return max(0, estimatedTickets)
    }
    
    // Total money spent on parking (only for sessions with cost tracking)
    var totalSpent: Double {
        sessions.compactMap { $0.totalCost }.reduce(0, +)
    }
    
    var formattedTotalSpent: String {
        String(format: "$%.2f", totalSpent)
    }
    
    var hasSpendingData: Bool {
        sessions.contains { $0.hourlyRate != nil }
    }
}
