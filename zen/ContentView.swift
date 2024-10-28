//
//  ContentView.swift
//  zen
//
//  Created by Jason Higgins on 9/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var error: Error?
    
    var body: some View {
        Group {
            if supabaseManager.isInitializing {
                VStack {
                    ProgressView()
                    Text("Loading...")
                }
                .onAppear { print("Showing loading view") }
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
                    print("Session refresh completed")
                } catch {
                    print("Session refresh error: \(error.localizedDescription)")
                    self.error = error
                }
            }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") {
                error = nil
            }
        }, message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        })
    }
}
