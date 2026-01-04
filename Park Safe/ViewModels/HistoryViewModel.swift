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
    @Published var displayedSessions: [ParkingSession] = [] // Currently displayed sessions
    @Published var sections: [HistorySection] = []
    @Published var isLoadingMore = false
    @Published var hasMoreSessions = true
    
    private let persistenceManager = PersistenceManager.shared
    private let batchSize = 20 // Load 20 sessions at a time
    private var allSessions: [ParkingSession] = [] // All sessions from storage
    
    init() {
        loadInitialSessions()
    }
    
    func loadSessions() {
        // Reload all sessions and reset pagination
        allSessions = persistenceManager.loadParkingSessions()
        displayedSessions = []
        hasMoreSessions = true
        loadMoreSessions()
    }
    
    func loadInitialSessions() {
        allSessions = persistenceManager.loadParkingSessions()
        displayedSessions = []
        hasMoreSessions = !allSessions.isEmpty
        loadMoreSessions()
    }
    
    func loadMoreSessions() {
        guard !isLoadingMore && hasMoreSessions else { return }
        
        isLoadingMore = true
        
        // Calculate how many more sessions to load
        let currentCount = displayedSessions.count
        let nextBatch = Array(allSessions.dropFirst(currentCount).prefix(batchSize))
        
        if nextBatch.isEmpty {
            hasMoreSessions = false
            isLoadingMore = false
            return
        }
        
        // Add new batch to displayed sessions
        displayedSessions.append(contentsOf: nextBatch)
        
        // Update sections with new sessions
        updateSections()
        
        // Check if there are more sessions to load
        hasMoreSessions = displayedSessions.count < allSessions.count
        
        isLoadingMore = false
    }
    
    func deleteSession(_ session: ParkingSession) {
        persistenceManager.deleteParkingSession(session)
        // Reload all sessions
        loadSessions()
    }
    
    private func updateSections() {
        var todaySessions: [ParkingSession] = []
        var thisWeekSessions: [ParkingSession] = []
        var olderSessions: [ParkingSession] = []
        
        for session in displayedSessions {
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
        allSessions.count
    }
    
    var totalHoursParked: Double {
        allSessions.reduce(0) { $0 + $1.duration } / 3600
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
        allSessions.compactMap { $0.totalCost }.reduce(0, +)
    }
    
    var formattedTotalSpent: String {
        String(format: "$%.2f", totalSpent)
    }
    
    var hasSpendingData: Bool {
        allSessions.contains { $0.hourlyRate != nil }
    }
    
    // Expose all sessions for export and analytics (not just displayed ones)
    var allSessionsForExport: [ParkingSession] {
        allSessions
    }
}
