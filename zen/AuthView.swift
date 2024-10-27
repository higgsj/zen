import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 50)
                
                Text("Welcome to AlphaFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                }
                .padding(.horizontal)
                
                Button(action: performAction) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .padding()
                .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Authentication"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                performAction()
            case .none:
                break
            }
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
