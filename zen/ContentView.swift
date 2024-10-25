//
//  ContentView.swift
//  zen
//
//  Created by Jason Higgins on 9/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        Group {
            if supabaseManager.currentUser != nil {
                HomeView()
            } else {
                AuthView()
            }
        }
    }
}
