import SwiftUI

struct HomeView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        VStack {
            Text("Welcome to AlphaFlow")
                .font(.largeTitle)
            
            // Add your main app content here
            
            Button("Sign Out") {
                Task {
                    do {
                        try await supabaseManager.signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }
        }
    }
}
