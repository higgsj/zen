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
            
            ExercisesTabView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Exercises")
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

struct HomeTabView: View {
    @Binding var isSessionActive: Bool
    
    var body: some View {
        VStack {
            Text("Welcome to AlphaFlow")
                .font(.largeTitle)
            
            Button(action: {
                isSessionActive = true
            }) {
                Text("Start Today's Session")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Text("Motivational message of the day")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
}

struct ExercisesTabView: View {
    var body: some View {
        VStack {
            Text("Daily Exercises")
                .font(.largeTitle)
            
            ExerciseCard(exercise: .kegel)
            ExerciseCard(exercise: .boxBreathing)
            ExerciseCard(exercise: .meditation)
        }
    }
}

struct ExerciseCard: View {
    let exercise: ExerciseType
    @StateObject private var timer: ExerciseTimer
    
    init(exercise: ExerciseType) {
        self.exercise = exercise
        let settings = ExerciseSettings()
        _timer = StateObject(wrappedValue: ExerciseTimer(type: exercise, settings: settings))
    }
    
    var body: some View {
        VStack {
            Text(exercise.rawValue)
                .font(.headline)
            
            Button(action: {
                if timer.isActive {
                    timer.stop()
                } else {
                    timer.start()
                }
            }) {
                Text(timer.isActive ? "Stop" : "Start")
            }
            
            Text(String(format: "%.1f", timer.timeRemaining))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
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
        }
        .onAppear(perform: loadSettings)
        .onChange(of: settings) { _, newValue in
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
    @State private var sessionStart: Date?
    @State private var exerciseDurations: [ExerciseType: TimeInterval] = [:]
    @AppStorage("exerciseSettings") private var exerciseSettingsData: Data = Data()
    @State private var settings = ExerciseSettings()
    
    init(isSessionActive: Binding<Bool>) {
        self._isSessionActive = isSessionActive
        let settings = ExerciseSettings()
        _exerciseTimer = StateObject(wrappedValue: ExerciseTimer(type: .kegel, settings: settings))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("AlphaFlow Session")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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

struct ExerciseView: View {
    let exerciseType: ExerciseType
    @ObservedObject var timer: ExerciseTimer
    
    var body: some View {
        VStack(spacing: 20) {
            Text(exerciseType.rawValue)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            switch exerciseType {
            case .kegel:
                KegelExerciseView(timer: timer)
            case .boxBreathing:
                BoxBreathingView(timer: timer)
            case .meditation:
                DefaultExerciseView(timer: timer)
            }
            
            exerciseInstructions
        }
    }
    
    private var exerciseInstructions: some View {
        VStack {
            switch exerciseType {
            case .kegel:
                Text("Contract and relax your pelvic floor muscles")
            case .boxBreathing:
                Text("Inhale, hold, exhale, and hold for equal counts")
            case .meditation:
                Text("Focus on your breath and clear your mind")
            }
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding()
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

