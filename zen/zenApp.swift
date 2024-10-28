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
    
    init() {
        // Suppress keyboard layout constraint warnings
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseManager)
        }
    }
}

class SupabaseManager: ObservableObject {
    let client: SupabaseClient
    @Published var currentUser: User?
    @Published var isInitializing = true
    
    init() {
        client = SupabaseClient(supabaseURL: Config.supabaseURL, supabaseKey: Config.supabaseKey)
    }
    
    func refreshSession() async throws {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
                self.isInitializing = false
            }
        } catch {
            // If there's no session, this is not necessarily an error
            if (error as NSError).localizedDescription.contains("Refresh Token Not Found") {
                await MainActor.run {
                    self.currentUser = nil
                    self.isInitializing = false
                }
                return
            }
            print("Error fetching session: \(error)")
            throw error
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
