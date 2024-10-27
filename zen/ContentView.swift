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
            } else if supabaseManager.currentUser != nil {
                HomeView()
                    .onAppear { print("Showing HomeView for user: \(supabaseManager.currentUser?.email ?? "Unknown")") }
            } else if let error = error, !isSecItemNotFoundError(error) {
                // Only show error view for non-keychain errors
                Text("Error: \(error.localizedDescription)")
                    .onAppear { print("Showing error view: \(error.localizedDescription)") }
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
                } catch {
                    print("Session refresh result: \(error.localizedDescription)")
                    self.error = error
                }
                isLoading = false
            }
        }
    }
    
    private func isSecItemNotFoundError(_ error: Error) -> Bool {
        let nsError = error as NSError
        // Check both the error description and the underlying error code
        return nsError.localizedDescription.contains("errSecItemNotFound") ||
               (nsError.domain == "Security" && nsError.code == -25300)
    }
}
