import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        VStack {
            Text("User Profile")
                .font(.largeTitle)
            
            if let user = supabaseManager.currentUser {
                Text("Email: \(user.email ?? "N/A")")
                // Add more user details as needed
            } else {
                Text("No user logged in")
            }
            
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
