import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var settings: SettingsManager
    @State private var name = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Profile Information")) {
                TextField("Name", text: $name)
            }
            
            Section(header: Text("Kegel Exercise Settings")) {
                Stepper("Contract Duration: \(settings.kegelContractDuration)s", value: $settings.kegelContractDuration, in: 1...10)
                Stepper("Relax Duration: \(settings.kegelRelaxDuration)s", value: $settings.kegelRelaxDuration, in: 1...10)
                Stepper("Rounds: \(settings.kegelRounds)", value: $settings.kegelRounds, in: 1...20)
            }
            
            Section(header: Text("Box Breathing Settings")) {
                Stepper("Inhale Duration: \(settings.inhaleDuration)s", value: $settings.inhaleDuration, in: 1...10)
                Stepper("Hold 1 Duration: \(settings.hold1Duration)s", value: $settings.hold1Duration, in: 1...10)
                Stepper("Exhale Duration: \(settings.exhaleDuration)s", value: $settings.exhaleDuration, in: 1...10)
                Stepper("Hold 2 Duration: \(settings.hold2Duration)s", value: $settings.hold2Duration, in: 1...10)
                Stepper("Rounds: \(settings.boxBreathingRounds)", value: $settings.boxBreathingRounds, in: 1...20)
            }
            
            Section(header: Text("Meditation Settings")) {
                Stepper("Duration: \(settings.meditationDuration / 60) minutes", value: $settings.meditationDuration, in: 60...3600, step: 60)
            }
            
            Section {
                Button(action: updateProfile) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Update Profile")
                    }
                }
                .disabled(isLoading)
            }
            
            Section {
                Button(action: signOut) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadUserProfile)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Profile"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onChange(of: settings.kegelContractDuration) { _ in settings.saveSettings() }
        .onChange(of: settings.kegelRelaxDuration) { _ in settings.saveSettings() }
        .onChange(of: settings.kegelRounds) { _ in settings.saveSettings() }
        .onChange(of: settings.inhaleDuration) { _ in settings.saveSettings() }
        .onChange(of: settings.hold1Duration) { _ in settings.saveSettings() }
        .onChange(of: settings.exhaleDuration) { _ in settings.saveSettings() }
        .onChange(of: settings.hold2Duration) { _ in settings.saveSettings() }
        .onChange(of: settings.boxBreathingRounds) { _ in settings.saveSettings() }
        .onChange(of: settings.meditationDuration) { _ in settings.saveSettings() }
    }
    
    private func loadUserProfile() {
        guard let userId = supabaseManager.currentUser?.id else { return }
        isLoading = true
        
        Task {
            do {
                let response = try await supabaseManager.client.database
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                if let profile = try? response.decoded(to: Profile.self) {
                    DispatchQueue.main.async {
                        self.name = profile.name ?? ""
                        self.isLoading = false
                    }
                } else {
                    // If no profile exists, create a new one
                    let newProfile = Profile(id: userId, name: "")
                    try await supabaseManager.client.database
                        .from("profiles")
                        .insert(newProfile)
                        .execute()
                    
                    DispatchQueue.main.async {
                        self.name = ""
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error loading profile: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Error loading profile: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func updateProfile() {
        guard let userId = supabaseManager.currentUser?.id else { return }
        isLoading = true
        
        Task {
            do {
                let profile = Profile(id: userId, name: name)
                try await supabaseManager.client.database
                    .from("profiles")
                    .upsert(profile)
                    .execute()
                
                // Update user metadata
                try await supabaseManager.client.auth.updateUser(
                    UserAttributes(
                        data: ["name": name]
                    )
                )
                
                DispatchQueue.main.async {
                    self.alertMessage = "Profile updated successfully"
                    self.showAlert = true
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Error updating profile: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func signOut() {
        isLoading = true
        Task {
            do {
                try await supabaseManager.signOut()
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Error signing out: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

struct Profile: Codable {
    let id: UUID
    let name: String?
}
