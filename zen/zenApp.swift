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
    
    init() {
        client = SupabaseClient(supabaseURL: Config.supabaseURL, supabaseKey: Config.supabaseKey)
    }
    
    func refreshSession() async throws {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
            }
        } catch {
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
