//
//  ContentView.swift
//  zen
//
//  Created by Jason Higgins on 9/12/24.
//

import SwiftUI
import AVFoundation
import Combine
import QuartzCore
import os.log
import CoreHaptics
import Supabase

// Remove HomeView import as it's not needed if HomeView is in the same module

enum Tab {
    case home, exercises, progress, settings
}

enum Exercise {
    case kegel, boxBreathing, meditation
    
    var title: String {
        switch self {
        case .kegel: return "Kegel Exercise"
        case .boxBreathing: return "Box Breathing"
        case .meditation: return "Meditation"
        }
    }
}

// Remove SoundManager class

// Add HapticFeedback class
class HapticFeedback {
    static let shared = HapticFeedback()
    private var engine: CHHapticEngine?
    
    // Add this property
    var isEnabled: Bool = true
    
    private init() {
        setupHapticEngine()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    func playHapticFeedback() {
        // Only play haptic feedback if it's enabled
        guard isEnabled, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription)")
        }
    }
}

// Add SettingsManager to handle customizable settings
class SettingsManager: ObservableObject {
    @Published var kegelContractDuration: Int = 5
    @Published var kegelRelaxDuration: Int = 5
    @Published var kegelRounds: Int = 10
    @Published var inhaleDuration: Int = 4
    @Published var hold1Duration: Int = 4
    @Published var exhaleDuration: Int = 4
    @Published var hold2Duration: Int = 4
    @Published var boxBreathingRounds: Int = 7
    @Published var meditationDuration: Int = 600
    @Published var meditationSoundFile: String = "meditation1"
    
    private var supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
        loadSettings()
    }
    
    func loadSettings() {
        Task {
            do {
                let response = try await supabaseClient
                    .from("user_settings")
                    .select()
                    .single()
                    .execute()
                
                let jsonData = response.data
                let decoder = JSONDecoder()
                let settings = try decoder.decode(UserSettings.self, from: jsonData)
                DispatchQueue.main.async {
                    self.kegelContractDuration = settings.kegelContractDuration
                    self.kegelRelaxDuration = settings.kegelRelaxDuration
                    self.kegelRounds = settings.kegelRounds
                    self.inhaleDuration = settings.inhaleDuration
                    self.hold1Duration = settings.hold1Duration
                    self.exhaleDuration = settings.exhaleDuration
                    self.hold2Duration = settings.hold2Duration
                    self.boxBreathingRounds = settings.boxBreathingRounds
                    self.meditationDuration = settings.meditationDuration
                    self.meditationSoundFile = settings.meditationSoundFile
                }
            } catch {
                print("Error loading settings: \(error)")
            }
        }
    }
    
    func saveSettings() {
        let settings = UserSettings(
            kegelContractDuration: kegelContractDuration,
            kegelRelaxDuration: kegelRelaxDuration,
            kegelRounds: kegelRounds,
            inhaleDuration: inhaleDuration,
            hold1Duration: hold1Duration,
            exhaleDuration: exhaleDuration,
            hold2Duration: hold2Duration,
            boxBreathingRounds: boxBreathingRounds,
            meditationDuration: meditationDuration,
            meditationSoundFile: meditationSoundFile
        )
        
        Task {
            do {
                try await supabaseClient
                    .from("user_settings")
                    .upsert(settings)
                    .execute()
            } catch {
                print("Error saving settings: \(error)")
            }
        }
    }
    
    func friendlyNameForSoundFile(_ soundFile: String) -> String {
        // Implement the logic to return a friendly name for the sound file
        return soundFile // For now, just return the sound file name
    }
}

struct UserSettings: Codable {
    let kegelContractDuration: Int
    let kegelRelaxDuration: Int
    let kegelRounds: Int
    let inhaleDuration: Int
    let hold1Duration: Int
    let exhaleDuration: Int
    let hold2Duration: Int
    let boxBreathingRounds: Int
    let meditationDuration: Int
    let meditationSoundFile: String
}

struct DailyProgress: Codable {
    var date: Date
    var status: ProgressStatus
    var kegelPercentage: Double
    var boxBreathingPercentage: Double
    var meditationPercentage: Double
    
    enum ProgressStatus: Int, Codable {
        case notCompleted = 0
        case partiallyCompleted = 1
        case fullyCompleted = 2
    }
}

// Add this near the top of the file, after the import statements
class ProgressManager: ObservableObject {
    @Published var dailyProgress: [DailyProgress] = []
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
        loadProgress()
    }
    
    func loadProgress() {
        Task {
            do {
                let response = try await supabaseClient
                    .from("daily_progress")
                    .select()
                    .order("date", ascending: false)
                    .execute()
                
                let jsonData = response.data
                let decoder = JSONDecoder()
                let progress = try decoder.decode([DailyProgress].self, from: jsonData)
                DispatchQueue.main.async {
                    self.dailyProgress = progress
                }
            } catch {
                print("Error loading progress: \(error)")
            }
        }
    }
    
    func saveProgress(_ progress: DailyProgress) {
        Task {
            do {
                try await supabaseClient
                    .from("daily_progress")
                    .upsert(progress)
                    .execute()
                
                loadProgress() // Reload progress after saving
            } catch {
                print("Error saving progress: \(error)")
            }
        }
    }
    
    func updateProgress(date: Date, kegelPercentage: Double, boxBreathingPercentage: Double, meditationPercentage: Double) {
        // Implement the logic to update progress
    }
}

// Add these structs at the top of the file, after the import statements
struct TutorialScreen {
    let title: String
    let content: String
    let bulletPoints: [String]
    let proTip: String?
}

struct TutorialContent {
    static let screens: [TutorialScreen] = [
        TutorialScreen(
            title: "Why AlphaFlow?",
            content: "Welcome to AlphaFlow, your science-backed path to peak masculinity. Our unique combination of exercises is designed to enhance your physical and mental strength, giving you the edge in all areas of life.",
            bulletPoints: [
                "Improved sexual health and performance",
                "Enhanced stress resilience and focus",
                "Better overall physical and mental well-being"
            ],
            proTip: "AlphaFlow integrates three powerful practices: Kegel exercises, box breathing, and meditation. Together, they form a comprehensive approach to male health that you won't find anywhere else. Ready to optimize your body and mind? Let's dive in."
        ),
        TutorialScreen(
            title: "Kegel Exercises",
            content: "Kegel exercises strengthen your pelvic floor muscles – a crucial but often neglected part of male fitness and sexual health.",
            bulletPoints: [
                "Enhance Sexual Function: Improve blood flow for stronger erections and more intense orgasms.",
                "Prevent Urinary Incontinence: Maintain urinary control, especially important as men age.",
                "Support Core Stability: Contribute to better posture and reduced lower back pain."
            ],
            proTip: "The Science: Kegels work by increasing the strength and endurance of the pubococcygeus (PC) muscle, which supports the pelvic organs and plays a crucial role in sexual function.\n\nHow to perform:\n1. Identify the right muscles by stopping urination midstream.\n2. Tighten these muscles for 5 seconds.\n3. Relax for 5 seconds.\n\nPro Tip: Practice Kegels discreetly anytime, anywhere. No one will know you're doing them!"
        ),
        TutorialScreen(
            title: "Box Breathing",
            content: "Box breathing is a powerful technique used by elite athletes and Navy SEALs to maintain calm and focus under pressure.",
            bulletPoints: [
                "Activate the Parasympathetic Nervous System: Trigger your body's relaxation response, reducing cortisol levels.",
                "Improve CO2 Tolerance: Enhance your body's ability to tolerate CO2, potentially improving athletic performance and reducing anxiety.",
                "Enhance Heart Rate Variability: Increase heart rate variability, a key indicator of cardiovascular health and stress resilience."
            ],
            proTip: "The Science: Box breathing works by regulating the autonomic nervous system, balancing the ratio of oxygen to carbon dioxide in your bloodstream, which can reduce stress and improve focus.\n\nHow to perform:\n1. Inhale slowly for 4 seconds\n2. Hold your breath for 4 seconds\n3. Exhale slowly for 4 seconds\n4. Hold your breath for 4 seconds\n\nPro Tip: Use box breathing before important meetings, workouts, or whenever you need to perform at your best."
        ),
        TutorialScreen(
            title: "Meditation",
            content: "Meditation is mental training that sharpens your mind and builds emotional resilience. It's not just for monks – it's for warriors who want to conquer their inner battlefield.",
            bulletPoints: [
                "Neuroplasticity: Increase gray matter density in areas associated with learning, memory, and emotional regulation.",
                "Telomere Preservation: Potentially slow cellular aging by preserving telomere length, extending lifespan.",
                "Enhanced Emotional Intelligence: Improve self-awareness and empathy, crucial for leadership and relationships."
            ],
            proTip: "The Science: Meditation alters brain wave patterns, increasing alpha and theta waves associated with relaxation and deep focus. It also reduces activity in the brain's default mode network, responsible for mind-wandering.\n\nHow to begin:\n1. Find a quiet place and sit comfortably\n2. Close your eyes and focus on your breath\n3. When your mind wanders, gently bring attention back to your breath\n4. Start with 5 minutes and gradually increase\n\nPro Tip: Consistency is key. Even 5 minutes daily can make a significant impact on your brain structure and function."
        ),
        TutorialScreen(
            title: "You're Ready to Start!",
            content: "Congratulations, you're now equipped with the AlphaFlow toolkit for male excellence!",
            bulletPoints: [
                "Kegel exercises for pelvic strength and sexual health",
                "Box breathing for autonomic nervous system regulation",
                "Meditation for cognitive enhancement and emotional mastery"
            ],
            proTip: "Remember, true alphas commit to daily practice. Your journey to peak performance starts now. Ready to optimize your body and mind? Start your first AlphaFlow session today!"
        )
    ]
}

// Add this struct after the existing structs and before the ContentView struct

struct ExercisePreviewCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(width: 80, height: 80)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ContentView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var selectedTab: Tab = .home

    var body: some View {
        Group {
            if supabaseManager.currentUser != nil {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(Tab.home)
                    
                    Text("Exercises")
                        .tabItem {
                            Label("Exercises", systemImage: "figure.walk")
                        }
                        .tag(Tab.exercises)
                    
                    Text("Progress")
                        .tabItem {
                            Label("Progress", systemImage: "chart.bar.fill")
                        }
                        .tag(Tab.progress)
                    
                    UserProfileView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(Tab.settings)
                }
            } else {
                AuthView()
            }
        }
    }
}

// MARK: - Exercise Extensions
extension Exercise {
    // Remove duplicate declarations of title, iconName, description, benefits, howTo, scienceInfo, and proTip
    
    // Add any additional properties or methods specific to the extension here
    
    var emoji: String {
        switch self {
        case .kegel: return "🌵"
        case .boxBreathing: return "🧘‍♂️"
        case .meditation: return "🧠"
        }
    }
    
    var color: Color {
        switch self {
        case .kegel: return .blue
        case .boxBreathing: return .green
        case .meditation: return .purple
        }
    }
}

// MARK: - ExerciseView
struct ExerciseView: View {
    @EnvironmentObject var settings: SettingsManager
    @Binding var exerciseQueue: [Exercise]
    @Binding var isPresented: Bool
    @ObservedObject var progressManager: ProgressManager
    
    @State private var currentExercise: Exercise?
    @State private var kegelPercentage: Double = 0
    @State private var boxBreathingPercentage: Double = 0
    @State private var meditationPercentage: Double = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if let exercise = currentExercise {
                    exerciseContent(for: exercise)
                } else {
                    Text("Preparing next exercise...")
                        .onAppear(perform: startNextExercise)
                }
            }
            .navigationBarItems(
                leading: leadingBarItem,
                trailing: trailingBarItem
            )
        }
        .onAppear(perform: startNextExercise)
    }
    
    private var leadingBarItem: some View {
        if currentExercise != .meditation {
            return AnyView(Button("Skip") {
                handleExerciseComplete()
            })
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private var trailingBarItem: some View {
        Button("End Session") {
            endSession()
        }
    }
    
    private func startNextExercise() {
        if let nextExercise = exerciseQueue.first {
            currentExercise = nextExercise
            exerciseQueue.removeFirst()
        } else {
            endSession()
        }
    }
    
    @ViewBuilder
    private func exerciseContent(for exercise: Exercise) -> some View {
        switch exercise {
        case .kegel:
            KegelView(onComplete: handleExerciseComplete, progressPercentage: $kegelPercentage)
                .environmentObject(settings)
        case .boxBreathing:
            BoxBreathingView(onComplete: handleExerciseComplete, progressPercentage: $boxBreathingPercentage)
                .environmentObject(settings)
        case .meditation:
            MeditationView(onComplete: handleExerciseComplete, progressPercentage: $meditationPercentage)
                .environmentObject(settings)
        }
    }
    
    private func handleExerciseComplete() {
        startNextExercise()
    }
    
    private func endSession() {
        progressManager.updateProgress(
            date: Date(),
            kegelPercentage: kegelPercentage,
            boxBreathingPercentage: boxBreathingPercentage,
            meditationPercentage: meditationPercentage
        )
        isPresented = false
    }
}

// MARK: - DynamicBackgroundView
struct DynamicBackgroundView: View {
    let exercise: Exercise

    var body: some View {
        switch exercise {
        case .kegel:
            Color.white // Changed to white background for Kegel exercise
        case .boxBreathing:
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.3), Color.yellow.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .meditation:
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.3), Color.indigo.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Updated KegelView
struct KegelView: View {
    @EnvironmentObject var settings: SettingsManager
    let onComplete: () -> Void
    @Binding var progressPercentage: Double
    
    @State private var isContracting: Bool = true
    @State private var roundsRemaining: Int = 0
    @State private var currentPhase: String = "Contract"
    @State private var progress: CGFloat = 0.0
    @State private var animationScale: CGFloat = 1.0
    @State private var textOpacity: Double = 1.0
    @State private var phaseTimeRemaining: Int = 0
    @State private var timer: Timer?
    
    @State private var completedRounds: Int = 0
    
    let kegelTips = [
        "To identify the correct muscles, try to stop the flow of urine when you're urinating. The muscles you use are your pelvic floor muscles.",
        "Focus on isolating the pelvic floor muscles. Avoid tensing your abs, buttocks, or thighs.",
        "Breathe normally throughout the exercise. Don't hold your breath.",
        "For best results, do Kegels in various positions: sitting, standing, and lying down.",
        "Gradually increase the duration and number of contractions as your muscles get stronger.",
        "Consistency is key. Aim to do Kegel exercises at least 3 times a day.",
        "Remember, stronger pelvic floor muscles can lead to improved sexual performance and bladder control."
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(currentPhase == "Contract" ? Color.blue : Color.green, lineWidth: 15)
                    .frame(width: 250, height: 250)
                    .rotationEffect(Angle(degrees: -90))
                
                VStack {
                    Text(currentPhase)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(currentPhase == "Contract" ? .blue : .green)
                        .opacity(textOpacity)
                    
                    Text("\(phaseTimeRemaining)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(currentPhase == "Contract" ? .blue : .green)
                        .opacity(textOpacity)
                }
                .scaleEffect(animationScale)
            }
            
            Text("Rounds Remaining: \(roundsRemaining)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            TipView(tips: kegelTips)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(Color.white) // Set the background to white
        .onAppear {
            startExercise()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startExercise() {
        roundsRemaining = settings.kegelRounds
        isContracting = true
        currentPhase = "Contract"
        phaseTimeRemaining = settings.kegelContractDuration
        startPhase()
        updateProgress()
    }
    
    private func startPhase() {
        progress = 0.0
        withAnimation {
            textOpacity = 1.0
            animationScale = isContracting ? 0.95 : 1.05
        }
        
        withAnimation(.linear(duration: Double(getCurrentDuration()))) {
            progress = 1.0
        }
        
        phaseTimeRemaining = getCurrentDuration()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if phaseTimeRemaining > 1 {
                phaseTimeRemaining -= 1
            } else {
                timer.invalidate()
                transitionToNextPhase()
            }
        }
    }
    
    private func transitionToNextPhase() {
        // Play haptic feedback when transitioning phases
        HapticFeedback.shared.playHapticFeedback()
        
        if isContracting {
            isContracting = false
            currentPhase = "Relax"
            startPhase()
        } else {
            roundsRemaining -= 1
            completedRounds += 1
            updateProgress()
            if roundsRemaining > 0 {
                isContracting = true
                currentPhase = "Contract"
                startPhase()
            } else {
                updateProgress() // Ensure final progress is captured
                onComplete()
            }
        }
    }
    
    private func getCurrentDuration() -> Int {
        return isContracting ? settings.kegelContractDuration : settings.kegelRelaxDuration
    }
    
    private func updateProgress() {
        let rawProgress = Double(completedRounds) / Double(settings.kegelRounds)
        progressPercentage = rawProgress
        print("Kegel Progress: \(progressPercentage)")
    }
}

// MARK: - Updated BoxBreathingView
struct BoxBreathingView: View {
    @EnvironmentObject var settings: SettingsManager
    let onComplete: () -> Void
    @Binding var progressPercentage: Double
    
    @StateObject private var viewModel: BoxBreathingViewModel
    
    let boxBreathingTips = [
        "Sit in a comfortable position with your back straight.",
        "Focus on the rhythm of your breath.",
        "Try to clear your mind and concentrate only on your breathing.",
        "This technique can help reduce stress and improve focus."
    ]
    
    init(onComplete: @escaping () -> Void, progressPercentage: Binding<Double>) {
        self.onComplete = onComplete
        self._progressPercentage = progressPercentage
        self._viewModel = StateObject(wrappedValue: BoxBreathingViewModel(progressPercentage: progressPercentage))
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 250, height: 250)
                
                BreathingProgressShape(progress: viewModel.progress, phase: viewModel.currentPhase)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                    .frame(width: 250, height: 250)
                
                VStack {
                    Text(viewModel.currentPhase.rawValue)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                    
                    if viewModel.isReady {
                        Text(String(format: "%.0f", max(ceil(viewModel.phaseTimeRemaining), 0)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    } else {
                        Text("Get Ready")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text("Round \(viewModel.currentRound) of \(settings.boxBreathingRounds)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            TipView(tips: boxBreathingTips)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .onAppear {
            viewModel.updateSettings(settings)
            viewModel.startExercise()
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                onComplete()
            }
        }
    }
}

// Add this struct for the TutorialView
struct TutorialView: View {
    let screens: [TutorialScreen]
    @State private var currentScreenIndex = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            TabView(selection: $currentScreenIndex) {
                ForEach(0..<screens.count, id: \.self) { index in
                    TutorialScreenView(screen: screens[index])
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            Button(action: {
                if currentScreenIndex < screens.count - 1 {
                    currentScreenIndex += 1
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text(currentScreenIndex < screens.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct TutorialScreenView: View {
    let screen: TutorialScreen
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(screen.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(screen.content)
                .font(.body)
            
            ForEach(screen.bulletPoints, id: \.self) { point in
                HStack(alignment: .top) {
                    Text("")
                    Text(point)
                }
            }
            
            if let proTip = screen.proTip {
                Text("Pro Tip:")
                    .font(.headline)
                Text(proTip)
                    .font(.body)
                    .italic()
            }
            
            Spacer()
        }
        .padding()
    }
}

// Add this struct for UserProfileView
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
        .onChange(of: settings.kegelContractDuration) { _, _ in settings.saveSettings() }
        .onChange(of: settings.kegelRelaxDuration) { _, _ in settings.saveSettings() }
        .onChange(of: settings.kegelRounds) { _, _ in settings.saveSettings() }
        .onChange(of: settings.inhaleDuration) { _, _ in settings.saveSettings() }
        .onChange(of: settings.hold1Duration) { _, _ in settings.saveSettings() }
        .onChange(of: settings.exhaleDuration) { _, _ in settings.saveSettings() }
        .onChange(of: settings.hold2Duration) { _, _ in settings.saveSettings() }
        .onChange(of: settings.boxBreathingRounds) { _, _ in settings.saveSettings() }
        .onChange(of: settings.meditationDuration) { _, _ in settings.saveSettings() }
    }
    
    private func loadUserProfile() {
        guard let userId = supabaseManager.currentUser?.id else { return }
        
        Task {
            do {
                let response = try await supabaseManager.client.from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                
                let jsonData = response.data
                let decoder = JSONDecoder()
                let profile = try decoder.decode(Profile.self, from: jsonData)
                DispatchQueue.main.async {
                    self.name = profile.name ?? ""
                }
            } catch {
                print("Error loading profile: \(error)")
            }
        }
    }
    
    private func updateProfile() {
        guard let userId = supabaseManager.currentUser?.id else { return }
        isLoading = true
        
        Task {
            do {
                let profile = Profile(id: userId, name: name)
                try await supabaseManager.client.from("profiles")
                    .upsert(profile)
                    .execute()
                
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
        Task {
            do {
                try await supabaseManager.signOut()
                DispatchQueue.main.async {
                    self.alertMessage = "Signed out successfully"
                    self.showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Error signing out: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}

struct Profile: Codable {
    let id: UUID
    let name: String?
}

// Add this struct for the AuthView
struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Updated background gradient
            LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.7), Color.orange.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo or App Icon
                Image(systemName: "leaf.fill") // Replace with your app's icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                
                Text("Welcome to AlphaFlow")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
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
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.white)
                            .underline()
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(20)
                .padding()
            }
        }
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

// Replace the ContentView_Previews struct with:

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(supabaseClient: SupabaseClient(supabaseURL: Config.supabaseURL, supabaseKey: Config.supabaseKey))
    }
}

struct MeditationView: View {
    @EnvironmentObject var settings: SettingsManager
    let onComplete: () -> Void
    @Binding var progressPercentage: Double
    
    @State private var timeRemaining: Int
    @State private var progress: CGFloat = 0.0
    @State private var timer: Timer?
    
    init(onComplete: @escaping () -> Void, progressPercentage: Binding<Double>) {
        self.onComplete = onComplete
        self._progressPercentage = progressPercentage
        self._timeRemaining = State(initialValue: 0)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Meditation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.purple, lineWidth: 15)
                    .frame(width: 250, height: 250)
                    .rotationEffect(Angle(degrees: -90))
                
                VStack {
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.purple)
                }
            }
            
            Button(action: {
                timer?.invalidate()
                onComplete()
            }) {
                Text("End Meditation")
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 2)
                    )
            }
        }
        .padding()
        .onAppear {
            startMeditation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startMeditation() {
        timeRemaining = settings.meditationDuration
        progress = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                progress = CGFloat(settings.meditationDuration - timeRemaining) / CGFloat(settings.meditationDuration)
                progressPercentage = Double(progress)
            } else {
                timer?.invalidate()
                onComplete()
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct TipView: View {
    let tips: [String]
    @State private var currentTipIndex = 0
    
    var body: some View {
        VStack {
            Text("Tip:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(tips[currentTipIndex])
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(height: 100)
        }
        .onAppear {
            startTipRotation()
        }
    }
    
    private func startTipRotation() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % tips.count
            }
        }
    }
}

struct BreathingProgressShape: Shape {
    var progress: CGFloat
    var phase: BreathingPhase
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        switch phase {
        case .inhale:
            path.addLine(to: CGPoint(x: rect.minX + rect.width * progress, y: rect.minY))
        case .hold1:
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * progress))
        case .exhale:
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * progress, y: rect.maxY))
        case .hold2:
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * progress))
        }
        
        return path
    }
}

class BoxBreathingViewModel: ObservableObject {
    @Published var currentPhase: BreathingPhase = .inhale
    @Published var progress: CGFloat = 0.0
    @Published var phaseTimeRemaining: Double = 0.0
    @Published var currentRound: Int = 1
    @Published var isComplete: Bool = false
    @Published var isReady: Bool = false
    
    @Binding var progressPercentage: Double
    
    private var settings: SettingsManager?
    private var timer: Timer?
    
    init(progressPercentage: Binding<Double>) {
        self._progressPercentage = progressPercentage
    }
    
    func updateSettings(_ settings: SettingsManager) {
        self.settings = settings
    }
    
    func startExercise() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isReady = true
            self.startPhase()
        }
    }
    
    private func startPhase() {
        phaseTimeRemaining = Double(getDuration(for: currentPhase))
        progress = 0.0
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.phaseTimeRemaining > 0.1 {
                self.phaseTimeRemaining -= 0.1
                self.updateProgress()
            } else {
                self.moveToNextPhase()
            }
        }
    }
    
    private func updateProgress() {
        let totalPhaseDuration = Double(getDuration(for: currentPhase))
        progress = CGFloat(1 - (phaseTimeRemaining / totalPhaseDuration))
        
        let totalDuration = Double(settings!.inhaleDuration + settings!.hold1Duration + settings!.exhaleDuration + settings!.hold2Duration)
        let completedDuration = Double((currentRound - 1) * Int(totalDuration)) + 
                                (totalDuration - phaseTimeRemaining - 
                                 Double(getDuration(for: currentPhase.next())) - 
                                 Double(getDuration(for: currentPhase.next().next())) - 
                                 Double(getDuration(for: currentPhase.next().next().next())))
        progressPercentage = completedDuration / Double(settings!.boxBreathingRounds * Int(totalDuration))
    }
    
    private func moveToNextPhase() {
        currentPhase = currentPhase.next()
        
        if currentPhase == .inhale {
            currentRound += 1
            if currentRound > settings!.boxBreathingRounds {
                completeExercise()
                return
            }
        }
        
        startPhase()
    }
    
    private func completeExercise() {
        timer?.invalidate()
        isComplete = true
        progressPercentage = 1.0
    }
    
    private func getDuration(for phase: BreathingPhase) -> Int {
        guard let settings = settings else { return 0 }
        
        switch phase {
        case .inhale:
            return settings.inhaleDuration
        case .hold1:
            return settings.hold1Duration
        case .exhale:
            return settings.exhaleDuration
        case .hold2:
            return settings.hold2Duration
        }
    }
}

enum BreathingPhase: String {
    case inhale = "Inhale"
    case hold1 = "Hold 1"
    case exhale = "Exhale"
    case hold2 = "Hold 2"
    
    func next() -> BreathingPhase {
        switch self {
        case .inhale: return .hold1
        case .hold1: return .exhale
        case .exhale: return .hold2
        case .hold2: return .inhale
        }
    }
}

struct ProgressCircle: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}

struct ProgressRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 100)
        }
    }
}

struct DayProgressSquare: View {
    let progress: Double
    let isCurrentDay: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorForProgress(progress))
                .frame(width: 35, height: 35)
            
            if isCurrentDay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 35, height: 35)
            }
        }
    }
    
    private func colorForProgress(_ progress: Double) -> Color {
        switch progress {
        case 0:
            return Color(UIColor.systemGray5)
        case 0.01...0.5:
            return .blue.opacity(0.3)
        case 0.5...0.9:
            return .blue.opacity(0.6)
        case 0.9...1:
            return .blue
        default:
            return Color(UIColor.systemGray5)
        }
    }
}

private func getDayProgress(for index: Int) -> Double {
    // Implement logic to get progress for each day
    // This is a placeholder implementation
    return Double.random(in: 0...1)
}

private func getCurrentDayIndex() -> Int {
    // Get the current day of the week (0 = Sunday, 6 = Saturday)
    let calendar = Calendar.current
    return calendar.component(.weekday, from: Date()) - 1
}

private func calculateStreak() -> Int {
    // Implement logic to calculate the streak
    // Only count days with over 50% progress
    // This is a placeholder implementation
    let weekProgress = (0..<7).map { getDayProgress(for: $0) }
    let streakDays = weekProgress.prefix(while: { $0 > 0.5 }).count
    return streakDays
}