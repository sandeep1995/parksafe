//
//  ParkingActivity.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import ActivityKit

struct ParkingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var endTime: Date
    }
    
    var startTime: Date
    var location: String?
}
