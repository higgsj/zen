import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to AlphaFlow")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: performAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                }
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Authentication"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func performAction() {
        isLoading = true
        Task {
            do {
                if isSignUp {
                    try await supabaseManager.signUp(email: email, password: password)
                    alertMessage = "Sign up successful. You can now sign in."
                } else {
                    try await supabaseManager.signIn(email: email, password: password)
                    alertMessage = "Sign in successful."
                }
            } catch {
                alertMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
            showAlert = true
        }
    }
}
