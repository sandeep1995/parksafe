//
//  ExportView.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 04/01/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportType: ExportType = .csv
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    enum ExportType: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        
        var icon: String {
            switch self {
            case .csv: return "tablecells"
            case .json: return "curlybraces"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Download your parking history in your preferred format")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Export Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Format")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Button {
                                exportType = type
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.title2)
                                    Text(type.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(exportType == type ? Color.blue : Color(.systemGray6))
                                .foregroundColor(exportType == type ? .white : .primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .modernCard()
                
                // Data Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data to Export")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("\(viewModel.totalSessions) parking sessions")
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                        Text(String(format: "%.1f total hours", viewModel.totalHoursParked))
                        Spacer()
                    }
                    
                    if viewModel.hasSpendingData {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                            Text(viewModel.formattedTotalSpent + " total spent")
                            Spacer()
                        }
                    }
                }
                .modernCard()
                
                Spacer()
                
                // Export Button
                Button {
                    exportData()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export \(exportType.rawValue)")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isExporting || viewModel.allSessionsForExport.isEmpty)
            }
            .padding()
            .background(Theme.background)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let fileURL: URL
                
                switch exportType {
                case .csv:
                    fileURL = try exportToCSV()
                case .json:
                    fileURL = try exportToJSON()
                }
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                }
                print("Export error: \(error)")
            }
        }
    }
    
    private func exportToCSV() throws -> URL {
        var csvString = "Date,Start Time,End Time,Duration (minutes),Location,Address,Floor,Section,Hourly Rate,Total Cost\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for session in viewModel.allSessionsForExport {
            let date = dateFormatter.string(from: session.startTime)
            let startTime = timeFormatter.string(from: session.startTime)
            let endTime = timeFormatter.string(from: session.endTime)
            let duration = Int(session.duration / 60)
            let location = session.location?.address.replacingOccurrences(of: ",", with: ";") ?? "Unknown"
            let address = session.truncatedAddress.replacingOccurrences(of: ",", with: ";")
            let floor = session.floor ?? ""
            let section = session.section ?? ""
            let hourlyRate = session.hourlyRate.map { String(format: "%.2f", $0) } ?? ""
            let totalCost = session.totalCost.map { String(format: "%.2f", $0) } ?? ""
            
            csvString += "\(date),\(startTime),\(endTime),\(duration),\(address),\(location),\(floor),\(section),\(hourlyRate),\(totalCost)\n"
        }
        
        let fileName = "ParkSafe_Export_\(formattedDate()).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func exportToJSON() throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(viewModel.allSessionsForExport)
        
        let fileName = "ParkSafe_Export_\(formattedDate()).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportView(viewModel: HistoryViewModel())
}
