//
//  ParkingActivityWidget.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import WidgetKit
import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct ParkingActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(urgencyColor(for: context.state.remainingTime).opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "car.fill")
                                .foregroundStyle(urgencyColor(for: context.state.remainingTime))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Parking Timer")
                                .font(.caption)
                                .fontWeight(.medium)
                            if let location = context.attributes.location {
                                Text(location)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Use system timer for automatic countdown
                        Text(context.state.endTime, style: .timer)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(urgencyColor(for: context.state.remainingTime))
                            .multilineTextAlignment(.trailing)
                        Text("remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(urgencyGradient(for: context.state.remainingTime))
                                    .frame(width: max(0, geo.size.width * progress(for: context)), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        HStack {
                            Text("Started \(context.attributes.startTime, style: .time)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Ends \(context.state.endTime, style: .time)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(urgencyColor(for: context.state.remainingTime).opacity(0.3))
                        .frame(width: 24, height: 24)
                    Image(systemName: "car.fill")
                        .foregroundStyle(urgencyColor(for: context.state.remainingTime))
                        .font(.system(size: 12, weight: .semibold))
                }
            } compactTrailing: {
                Text(context.state.endTime, style: .timer)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(urgencyColor(for: context.state.remainingTime))
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)
            } minimal: {
                ZStack {
                    Circle()
                        .strokeBorder(urgencyColor(for: context.state.remainingTime), lineWidth: 2)
                    Image(systemName: "car.fill")
                        .foregroundStyle(urgencyColor(for: context.state.remainingTime))
                        .font(.system(size: 10, weight: .semibold))
                }
            }
        }
    }
    
    // Calculate urgency color based on remaining time
    private func urgencyColor(for remainingTime: TimeInterval) -> Color {
        if remainingTime > 600 { // More than 10 minutes
            return .green
        } else if remainingTime > 300 { // More than 5 minutes
            return .orange
        } else {
            return .red
        }
    }
    
    // Gradient for progress bar
    private func urgencyGradient(for remainingTime: TimeInterval) -> LinearGradient {
        let color = urgencyColor(for: remainingTime)
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Calculate progress (time elapsed / total duration)
    private func progress(for context: ActivityViewContext<ParkingActivityAttributes>) -> CGFloat {
        let totalDuration = context.state.endTime.timeIntervalSince(context.attributes.startTime)
        guard totalDuration > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(context.attributes.startTime)
        return min(1.0, max(0, CGFloat(elapsed / totalDuration)))
    }
}

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<ParkingActivityAttributes>
    
    private var urgencyColor: Color {
        if context.state.remainingTime > 600 {
            return .green
        } else if context.state.remainingTime > 300 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Car icon with urgency indicator
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "car.fill")
                    .foregroundStyle(urgencyColor)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Parking Timer")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let location = context.attributes.location {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Use system timer for automatic countdown
                Text(context.state.endTime, style: .timer)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(urgencyColor)
                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            // Gradient background based on urgency
            LinearGradient(
                colors: [urgencyColor.opacity(0.1), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
