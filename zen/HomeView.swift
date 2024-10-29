import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var selectedTab = 0
    @State private var isSessionActive = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(isSessionActive: $isSessionActive)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            // Pass selectedTab binding to TutorialTabView
            TutorialTabView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Tutorial")
                }
                .tag(1)
            
            ProgressTabView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Progress")
                }
                .tag(2)
            
            SettingsTabView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .fullScreenCover(isPresented: $isSessionActive) {
            SessionView(isSessionActive: $isSessionActive)
        }
    }
}

// Add new TutorialTabView
struct TutorialTabView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showTutorial = true
    @Binding var selectedTab: Int  // Add this binding
    
    var body: some View {
        NavigationView {
            if !showTutorial {
                Color.clear.onAppear {
                    // Switch back to home tab when tutorial is dismissed
                    selectedTab = 0
                }
            } else {
                TutorialView(screens: TutorialContent.screens, isPresented: $showTutorial)
                    .navigationTitle("Tutorial")
            }
        }
    }
}

struct HomeTabView: View {
    @Binding var isSessionActive: Bool
    @State private var showingTutorial = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Title
                HStack(spacing: 0) {
                    Text("ALPHA")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("flow")
                        .font(.largeTitle)
                        .italic()
                }
                .padding(.top, 40)
                
                // Hero Box with Exercise Types
                VStack(spacing: 16) {
                    Text("Daily Practices")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        ExerciseIconView(
                            icon: "🌵",  // Using cactus emoji
                            title: "Kegel",
                            color: .green,
                            isSystemIcon: false
                        )
                        
                        ExerciseIconView(
                            icon: "wind",  // Using wind as placeholder for lungs
                            title: "Breathing",
                            color: .blue
                        )
                        
                        ExerciseIconView(
                            icon: "brain.head.profile",  // Using brain icon
                            title: "Meditation",
                            color: .purple
                        )
                    }
                    
                    Button(action: {
                        isSessionActive = true
                    }) {
                        Text("Start Today's Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                // Weekly Progress Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Progress")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    WeeklyProgressView()
                }
                .padding(.vertical)
                
                // Tutorial Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tutorial")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TutorialCardView(
                        title: "Learn More About These Practices",
                        showingTutorial: $showingTutorial
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                Spacer(minLength: 50)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ExerciseIconView: View {
    let icon: String
    let title: String
    let color: Color
    var isSystemIcon: Bool = true
    
    var body: some View {
        VStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if isSystemIcon {
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundColor(color)
                        } else {
                            Text(icon)
                                .font(.system(size: 30))
                        }
                    }
                )
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct WeeklyProgressView: View {
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    // Mock data - replace with actual progress data
    let progress: [Bool] = [true, true, false, true, false, false, false]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<7) { index in
                VStack(spacing: 8) {
                    Circle()
                        .fill(progress[index] ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                    
                    Text(daysOfWeek[index])
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)  // Make it full width
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)  // Add shadow
        .padding(.horizontal)
    }
}

struct TutorialCardView: View {
    let title: String
    @Binding var showingTutorial: Bool
    
    var body: some View {
        Button(action: {
            showingTutorial = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 5)
        }
        .sheet(isPresented: $showingTutorial) {
            TutorialView(screens: TutorialContent.screens, isPresented: $showingTutorial)
        }
    }
}

struct ProgressTabView: View {
    var body: some View {
        Text("Progress View")
    }
}

struct SettingsTabView: View {
    @AppStorage("exerciseSettings") private var exerciseSettingsData: Data = Data()
    @State private var settings = ExerciseSettings()
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var audioHapticManager: AudioHapticManager
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kegel Exercise")) {
                    Stepper("Contract Duration: \(Int(settings.kegelContractDuration))s", value: $settings.kegelContractDuration, in: 1...30)
                    Stepper("Relax Duration: \(Int(settings.kegelRelaxDuration))s", value: $settings.kegelRelaxDuration, in: 1...30)
                    Stepper("Rounds: \(settings.kegelRounds)", value: $settings.kegelRounds, in: 1...50)
                }
                
                Section(header: Text("Box Breathing")) {
                    Stepper("Inhale Duration: \(Int(settings.boxBreathingInhaleDuration))s", value: $settings.boxBreathingInhaleDuration, in: 1...10)
                    Stepper("Hold Inhale Duration: \(Int(settings.boxBreathingHoldInhaleDuration))s", value: $settings.boxBreathingHoldInhaleDuration, in: 1...10)
                    Stepper("Exhale Duration: \(Int(settings.boxBreathingExhaleDuration))s", value: $settings.boxBreathingExhaleDuration, in: 1...10)
                    Stepper("Hold Exhale Duration: \(Int(settings.boxBreathingHoldExhaleDuration))s", value: $settings.boxBreathingHoldExhaleDuration, in: 1...10)
                    Stepper("Rounds: \(settings.boxBreathingRounds)", value: $settings.boxBreathingRounds, in: 1...20)
                }
                
                Section(header: Text("Meditation")) {
                    Stepper("Duration: \(Int(settings.meditationDuration)) minutes", value: $settings.meditationDuration, in: 1...60)
                }
                
                Section(header: Text("Audio & Haptics")) {
                    Toggle("Meditation Music", isOn: $audioHapticManager.isMeditationMusicEnabled)
                    
                    if audioHapticManager.isMeditationMusicEnabled {
                        Picker("Meditation Track", selection: $audioHapticManager.meditationTrack) {
                            ForEach(AudioHapticManager.MeditationTrack.allCases, id: \.self) { track in
                                Text(track.rawValue).tag(track)
                            }
                        }
                        
                        HStack {
                            Text("Music Volume")
                            Slider(value: $audioHapticManager.meditationVolume, in: 0...1)
                        }
                    }
                    
                    Toggle("Voice Prompts", isOn: $audioHapticManager.isVoicePromptsEnabled)
                    
                    if audioHapticManager.isVoicePromptsEnabled {
                        HStack {
                            Text("Voice Volume")
                            Slider(value: $audioHapticManager.voicePromptVolume, in: 0...1)
                        }
                    }
                    
                    Toggle("Haptic Feedback", isOn: $audioHapticManager.isHapticsEnabled)
                }
                
                Section {
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await supabaseManager.signOut()
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onChange(of: audioHapticManager.isMeditationMusicEnabled) { _, _ in
                audioHapticManager.saveSettings()
            }
            .onChange(of: audioHapticManager.meditationTrack) { _, _ in
                audioHapticManager.saveSettings()
            }
            .onChange(of: audioHapticManager.meditationVolume) { _, _ in
                audioHapticManager.saveSettings()
            }
            .onChange(of: audioHapticManager.isVoicePromptsEnabled) { _, _ in
                audioHapticManager.saveSettings()
            }
            .onChange(of: audioHapticManager.voicePromptVolume) { _, _ in
                audioHapticManager.saveSettings()
            }
            .onChange(of: audioHapticManager.isHapticsEnabled) { _, _ in
                audioHapticManager.saveSettings()
            }
        }
        .onAppear(perform: loadSettings)
        .onChange(of: settings) { _, _ in
            saveSettings()
        }
    }
    
    func loadSettings() {
        if let decodedSettings = try? JSONDecoder().decode(ExerciseSettings.self, from: exerciseSettingsData) {
            settings = decodedSettings
        }
    }
    
    func saveSettings() {
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            exerciseSettingsData = encodedSettings
        }
    }
}

struct SessionView: View {
    @Binding var isSessionActive: Bool
    @State private var currentExercise: ExerciseType = .kegel
    @StateObject private var exerciseTimer: ExerciseTimer
    @EnvironmentObject var audioHapticManager: AudioHapticManager
    @AppStorage("exerciseSettings") private var exerciseSettingsData: Data = Data()
    @State private var settings = ExerciseSettings()
    @State private var sessionStart: Date?
    @State private var exerciseDurations: [ExerciseType: TimeInterval] = [:]
    
    init(isSessionActive: Binding<Bool>) {
        self._isSessionActive = isSessionActive
        let settings = ExerciseSettings()
        _exerciseTimer = StateObject(wrappedValue: ExerciseTimer(
            type: .kegel,
            settings: settings,
            audioHapticManager: AudioHapticManager()
        ))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Replace generic title with exercise-specific title and benefit
                VStack(spacing: 8) {
                    Text(currentExercise.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(benefitText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 50)
                
                Spacer()
                
                ExerciseView(exerciseType: currentExercise, timer: exerciseTimer)
                
                Spacer()
                
                HStack(spacing: 20) {
                    // End Session Button
                    Button(action: {
                        exerciseTimer.stop()
                        isSessionActive = false
                    }) {
                        Text("End Session")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                    
                    // Next Exercise Button - Only show if not on last exercise
                    if currentExercise != .meditation {
                        Button(action: moveToNextExercise) {
                            Text("Next Exercise")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear(perform: startSession)
        .onDisappear(perform: endSession)
        .onReceive(NotificationCenter.default.publisher(for: .exerciseComplete)) { notification in
            if let exerciseType = notification.userInfo?["exerciseType"] as? ExerciseType {
                handleExerciseCompletion(exerciseType)
            }
        }
        .onAppear {
            exerciseTimer.audioHapticManager = audioHapticManager
        }
    }
    
    private var benefitText: String {
        switch currentExercise {
        case .kegel:
            return "Building pelvic floor strength for improved sexual performance"
        case .boxBreathing:
            return "Optimizing your oxygen-CO2 balance for maximum calm and focus"
        case .meditation:
            return "Rewiring your neural pathways for better emotional control"
        }
    }
    
    private func startSession() {
        sessionStart = Date()
        loadSettings()
        startExercise()
    }
    
    private func loadSettings() {
        if let decodedSettings = try? JSONDecoder().decode(ExerciseSettings.self, from: exerciseSettingsData) {
            settings = decodedSettings
        }
    }
    
    private func startExercise() {
        exerciseTimer.reset()
        exerciseTimer.updateSettings(type: currentExercise, settings: settings)
        exerciseTimer.start()
    }
    
    private func moveToNextExercise() {
        // Store current exercise duration
        exerciseDurations[currentExercise] = exerciseTimer.totalDuration - exerciseTimer.timeRemaining
        
        // Determine next exercise
        switch currentExercise {
        case .kegel:
            currentExercise = .boxBreathing
        case .boxBreathing:
            currentExercise = .meditation
        case .meditation:
            endSession()
            return
        }
        
        // Start the next exercise
        startExercise()
    }
    
    private func handleExerciseCompletion(_ completedExercise: ExerciseType) {
        print("Exercise completed: \(completedExercise)")
        exerciseDurations[completedExercise] = exerciseTimer.totalDuration
        
        // Automatically move to next exercise if available
        switch completedExercise {
        case .kegel:
            currentExercise = .boxBreathing
            startExercise()
        case .boxBreathing:
            currentExercise = .meditation
            startExercise()
        case .meditation:
            endSession()
        }
    }
    
    private func endSession() {
        // Store final exercise duration if not already stored
        exerciseDurations[currentExercise] = exerciseTimer.totalDuration - exerciseTimer.timeRemaining
        
        let session = ExerciseSession(
            date: sessionStart ?? Date(),
            kegelDuration: exerciseDurations[.kegel] ?? 0,
            boxBreathingDuration: exerciseDurations[.boxBreathing] ?? 0,
            meditationDuration: exerciseDurations[.meditation] ?? 0
        )
        
        print("Session completed: \(session)")
    }
}

// Add this new struct for managing tips
struct ExerciseTips {
    static let kegelTips = [
        "Identify correct muscles by stopping urine flow - but only for practice, not during regular urination",
        "If you're doing it right, no one should be able to tell you're exercising",
        "Focus on only tightening pelvic muscles, not abs, thighs, or buttocks",
        "Keep breathing normally throughout the exercise",
        "For best results, practice consistently at the same times each day"
    ]
    
    static let boxBreathingTips = [
        "Keep your shoulders relaxed and spine straight",
        "Breathe from your diaphragm - place a hand on your belly to check",
        "If 4 seconds is too long, start with 2-3 seconds and build up",
        "Practice in a quiet place until it becomes natural",
        "Use this technique before stressful situations for instant calm"
    ]
    
    static let meditationTips = [
        "It's normal for your mind to wander - just gently return focus to your breath",
        "Start with short sessions and gradually increase duration",
        "Keep your spine straight but not rigid - comfort is key",
        "Don't try to stop thoughts - observe them without judgment",
        "Consistency matters more than duration - daily practice is key"
    ]
    
    static func tipsFor(_ exerciseType: ExerciseType) -> [String] {
        switch exerciseType {
        case .kegel:
            return kegelTips
        case .boxBreathing:
            return boxBreathingTips
        case .meditation:
            return meditationTips
        }
    }
}

// Update ExerciseView to remove exerciseInstructions
struct ExerciseView: View {
    let exerciseType: ExerciseType
    @ObservedObject var timer: ExerciseTimer
    
    var body: some View {
        VStack(spacing: 40) { // Increased spacing from 20 to 40
            switch exerciseType {
            case .kegel:
                KegelExerciseView(timer: timer)
            case .boxBreathing:
                BoxBreathingView(timer: timer)
            case .meditation:
                DefaultExerciseView(timer: timer)
            }
            
            RotatingTipView(exerciseType: exerciseType)
        }
    }
}

// Update RotatingTipView to properly handle the timer
struct RotatingTipView: View {
    let exerciseType: ExerciseType
    @State private var currentTipIndex = 0
    @State private var tipTimer: AnyCancellable?
    
    var body: some View {
        Text(ExerciseTips.tipsFor(exerciseType)[currentTipIndex])
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .transition(.opacity)
            .id(currentTipIndex)
            .animation(.easeInOut(duration: 0.5), value: currentTipIndex)
            .onAppear {
                // Start the timer when view appears
                tipTimer = Timer.publish(every: 7, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        withAnimation {
                            currentTipIndex = (currentTipIndex + 1) % ExerciseTips.tipsFor(exerciseType).count
                        }
                    }
            }
            .onDisappear {
                // Cancel the timer when view disappears
                tipTimer?.cancel()
                tipTimer = nil
            }
    }
}

struct KegelExerciseView: View {
    @ObservedObject var timer: ExerciseTimer
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rounds Remaining: \(timer.roundsRemaining)")
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(timer.phaseProgress))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: 270.0))
                    // Remove the animation modifier here since the animation is handled
                    // by the ExerciseTimer's phaseProgress updates
                
                VStack {
                    Text(timer.currentPhase)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(timer.displayTimeRemaining)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 250, height: 250)
        }
    }
}

struct DefaultExerciseView: View {
    @ObservedObject var timer: ExerciseTimer
    
    var body: some View {
        VStack(spacing: 20) {
            Text(timer.currentPhase)
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(timer.progress))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: timer.progress)
                
                VStack {
                    Text(timer.currentPhase)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(String(format: "%02d:%02d", Int(timer.timeRemaining) / 60, Int(timer.timeRemaining) % 60))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 250, height: 250)
        }
    }
}

// Update BoxBreathingView to include accumulated progress
struct BoxBreathingView: View {
    @ObservedObject var timer: ExerciseTimer
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rounds Remaining: \(timer.roundsRemaining)")
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack {
                // Static square outline
                SquareOutline()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                // Accumulated progress lines
                AccumulatedBoxProgress(currentPhase: timer.currentPhase, 
                                    phaseProgress: timer.phaseProgress,
                                    currentPhaseIndex: getPhaseIndex(timer.currentPhase))
                    .stroke(Color.white, lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                // Center text
                VStack {
                    Text(timer.currentPhase)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(timer.displayTimeRemaining)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 250, height: 250)
        }
    }
    
    // Helper function to get phase index since we can't access timer.phases directly
    private func getPhaseIndex(_ phase: String) -> Int {
        let phases = ["Inhale", "Hold Inhale", "Exhale", "Hold Exhale"]
        return phases.firstIndex(of: phase) ?? 0
    }
}

// Square outline shape
struct SquareOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        return path
    }
}

// New shape to handle accumulated progress
struct AccumulatedBoxProgress: Shape {
    let currentPhase: String
    let phaseProgress: Double
    let currentPhaseIndex: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw completed phases
        for phase in 0..<currentPhaseIndex {
            drawCompletedPhase(phase: phase, in: rect, path: &path)
        }
        
        // Draw current phase progress
        drawCurrentPhase(in: rect, path: &path)
        
        return path
    }
    
    private func drawCompletedPhase(phase: Int, in rect: CGRect, path: inout Path) {
        switch phase {
        case 0: // Inhale (top)
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        case 1: // Hold Inhale (right)
            path.move(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        case 2: // Exhale (bottom)
            path.move(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        case 3: // Hold Exhale (left)
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: 0))
        default:
            break
        }
    }
    
    private func drawCurrentPhase(in rect: CGRect, path: inout Path) {
        switch currentPhase {
        case "Inhale": // Top edge
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width * phaseProgress, y: 0))
            
        case "Hold Inhale": // Right edge
            path.move(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * phaseProgress))
            
        case "Exhale": // Bottom edge
            path.move(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width * (1 - phaseProgress), y: rect.height))
            
        case "Hold Exhale": // Left edge
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height * (1 - phaseProgress)))
            
        default:
            break
        }
    }
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    let screens: [TutorialScreen]
    @State private var currentScreen = 0
    
    init(screens: [TutorialScreen], isPresented: Binding<Bool>) {
        self.screens = screens
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(screens[currentScreen].title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(screens[currentScreen].content)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(screens[currentScreen].bulletPoints, id: \.self) { point in
                            HStack(alignment: .top) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .padding(.top, 6)
                                Text(point)
                            }
                        }
                    }
                    
                    if let proTip = screens[currentScreen].proTip {
                        VStack(alignment: .leading) {
                            Text("Pro Tip")
                                .font(.headline)
                            Text(proTip)
                                .font(.body)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            HStack(spacing: 20) {
                if currentScreen > 0 {
                    Button(action: {
                        withAnimation {
                            currentScreen -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                if currentScreen < screens.count - 1 {
                    Button(action: {
                        withAnimation {
                            currentScreen += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Done")
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }
}

