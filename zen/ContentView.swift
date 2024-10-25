//
//  ContentView.swift
//  zen
//
//  Created by Jason Higgins on 9/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                }
                .onAppear { print("Showing loading view") }
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .onAppear { print("Showing error view: \(error.localizedDescription)") }
            } else if supabaseManager.currentUser != nil {
                HomeView()
                    .onAppear { print("Showing HomeView for user: \(supabaseManager.currentUser?.email ?? "Unknown")") }
            } else {
                AuthView()
                    .onAppear { print("Showing AuthView") }
            }
        }
        .onAppear {
            print("ContentView appeared")
            Task {
                do {
                    print("Refreshing session...")
                    try await supabaseManager.refreshSession()
                    print("Session refreshed successfully")
                    isLoading = false
                } catch {
                    print("Error refreshing session: \(error.localizedDescription)")
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
}
