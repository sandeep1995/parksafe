//
//  Park_SafeApp.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import SwiftUI
import WidgetKit

@main
struct Park_SafeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        if #available(iOS 16.1, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
