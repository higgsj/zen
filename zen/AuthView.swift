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
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: performAction) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
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
                showAlert = true
            } catch {
                alertMessage = "Error: \(error.localizedDescription)"
                showAlert = true
            }
            isLoading = false
        }
    }
}
