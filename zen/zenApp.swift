//
//  zenApp.swift
//  zen
//
//  Created by Jason Higgins on 9/12/24.
//

import SwiftUI

@main
struct zenApp: App {
    @StateObject private var settings = SettingsManager()
    @StateObject private var progressManager = ProgressManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                    .environmentObject(settings)
                .environmentObject(progressManager)
        }
    }
}
