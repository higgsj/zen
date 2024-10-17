//
//  zenApp.swift
//  zen
//
//  Created by Jason Higgins on 9/12/24.
//

import SwiftUI
import Supabase

@main
struct zenApp: App {
    @StateObject private var supabaseManager = SupabaseManager()
    @StateObject private var settingsManager: SettingsManager
    @StateObject private var progressManager: ProgressManager

    init() {
        let supabaseManager = SupabaseManager()
        let settingsManager = SettingsManager(supabaseClient: supabaseManager.client)
        let progressManager = ProgressManager(supabaseClient: supabaseManager.client)
        _supabaseManager = StateObject(wrappedValue: supabaseManager)
        _settingsManager = StateObject(wrappedValue: settingsManager)
        _progressManager = StateObject(wrappedValue: progressManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseManager)
                .environmentObject(settingsManager)
                .environmentObject(progressManager)
        }
    }
}

class SupabaseManager: ObservableObject {
    let client: SupabaseClient
    @Published var currentUser: User?
    
    init() {
        client = SupabaseClient(supabaseURL: Config.supabaseURL, supabaseKey: Config.supabaseKey)
        
        // Defer session check
        Task {
            await checkSession()
        }
    }
    
    private func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
            }
        } catch {
            print("Error fetching session: \(error)")
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        await MainActor.run {
            self.currentUser = response.user
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(email: email, password: password)
        await MainActor.run {
            self.currentUser = response.user
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
        }
    }
}
