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
    @Published var kegelContractDuration: Int {
        didSet {
            os_log("Kegel contract duration changed to: %{public}d", log: .default, type: .info, kegelContractDuration)
            UserDefaults.standard.set(kegelContractDuration, forKey: "kegelContractDuration")
        }
    }
    @Published var kegelRelaxDuration: Int {
        didSet {
            os_log("Kegel relax duration changed to: %{public}d", log: .default, type: .info, kegelRelaxDuration)
            UserDefaults.standard.set(kegelRelaxDuration, forKey: "kegelRelaxDuration")
        }
    }
    @Published var kegelRounds: Int {
        didSet {
            os_log("Kegel rounds changed to: %{public}d", log: .default, type: .info, kegelRounds)
            UserDefaults.standard.set(kegelRounds, forKey: "kegelRounds")
        }
    }
    
    @Published var inhaleDuration: Int {
        didSet {
            os_log("Inhale duration changed to: %{public}d", log: .default, type: .info, inhaleDuration)
            UserDefaults.standard.set(inhaleDuration, forKey: "inhaleDuration")
        }
    }
    @Published var hold1Duration: Int {
        didSet {
            os_log("Hold 1 duration changed to: %{public}d", log: .default, type: .info, hold1Duration)
            UserDefaults.standard.set(hold1Duration, forKey: "hold1Duration")
        }
    }
    @Published var exhaleDuration: Int {
        didSet {
            os_log("Exhale duration changed to: %{public}d", log: .default, type: .info, exhaleDuration)
            UserDefaults.standard.set(exhaleDuration, forKey: "exhaleDuration")
        }
    }
    @Published var hold2Duration: Int {
        didSet {
            os_log("Hold 2 duration changed to: %{public}d", log: .default, type: .info, hold2Duration)
            UserDefaults.standard.set(hold2Duration, forKey: "hold2Duration")
        }
    }
    @Published var boxBreathingRounds: Int {
        didSet {
            os_log("Box breathing rounds changed to: %{public}d", log: .default, type: .info, boxBreathingRounds)
            UserDefaults.standard.set(boxBreathingRounds, forKey: "boxBreathingRounds")
        }
    }
    
    @Published var meditationDuration: Int {
        didSet {
            os_log("Meditation duration changed to: %{public}d", log: .default, type: .info, meditationDuration)
            UserDefaults.standard.set(meditationDuration, forKey: "meditationDuration")
        }
    }
    
    @Published var meditationSoundFile: String {
        didSet {
            os_log("Meditation sound file changed to: %{public}@", log: .default, type: .info, meditationSoundFile)
            UserDefaults.standard.set(meditationSoundFile, forKey: "meditationSoundFile")
        }
    }
    
    init() {
        self.kegelContractDuration = UserDefaults.standard.integer(forKey: "kegelContractDuration") != 0 ? UserDefaults.standard.integer(forKey: "kegelContractDuration") : 5
        self.kegelRelaxDuration = UserDefaults.standard.integer(forKey: "kegelRelaxDuration") != 0 ? UserDefaults.standard.integer(forKey: "kegelRelaxDuration") : 5
        self.kegelRounds = UserDefaults.standard.integer(forKey: "kegelRounds") != 0 ? UserDefaults.standard.integer(forKey: "kegelRounds") : 10
        
        self.inhaleDuration = UserDefaults.standard.integer(forKey: "inhaleDuration") != 0 ? UserDefaults.standard.integer(forKey: "inhaleDuration") : 4
        self.hold1Duration = UserDefaults.standard.integer(forKey: "hold1Duration") != 0 ? UserDefaults.standard.integer(forKey: "hold1Duration") : 4
        self.exhaleDuration = UserDefaults.standard.integer(forKey: "exhaleDuration") != 0 ? UserDefaults.standard.integer(forKey: "exhaleDuration") : 4
        self.hold2Duration = UserDefaults.standard.integer(forKey: "hold2Duration") != 0 ? UserDefaults.standard.integer(forKey: "hold2Duration") : 4
        self.boxBreathingRounds = UserDefaults.standard.integer(forKey: "boxBreathingRounds") != 0 ? UserDefaults.standard.integer(forKey: "boxBreathingRounds") : 7
        
        self.meditationDuration = UserDefaults.standard.integer(forKey: "meditationDuration") != 0 ? UserDefaults.standard.integer(forKey: "meditationDuration") : 600
        
        self.meditationSoundFile = UserDefaults.standard.string(forKey: "meditationSoundFile") ?? "meditation1"
        print("Initial meditation sound file: \(self.meditationSoundFile)")
    }

    // Add this helper function
    func friendlyNameForSoundFile(_ file: String) -> String {
        switch file {
        case "meditation1": return "Earth"
        case "meditation2": return "Sky"
        case "meditation3": return "Ocean"
        default: return "None"
        }
    }

    // Add this helper function
    func soundFileForFriendlyName(_ name: String) -> String {
        switch name {
        case "Earth": return "meditation1"
        case "Sky": return "meditation2"
        case "Ocean": return "meditation3"
        default: return "None"
        }
    }
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

class ProgressManager: ObservableObject {
    @Published var dailyProgress: [DailyProgress] = []
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "dailyProgress"
    
    init() {
        loadProgress()
    }
    
    func updateProgress(date: Date, kegelPercentage: Double, boxBreathingPercentage: Double, meditationPercentage: Double) {
        os_log("Updating progress - Kegel: %{public}f, Box Breathing: %{public}f, Meditation: %{public}f", log: .default, type: .info, kegelPercentage, boxBreathingPercentage, meditationPercentage)
        let overallPercentage = (kegelPercentage + boxBreathingPercentage + meditationPercentage) / 3
        
        let status: DailyProgress.ProgressStatus
        if overallPercentage >= 0.99 {
            status = .fullyCompleted
        } else if overallPercentage > 0 {
            status = .partiallyCompleted
        } else {
            status = .notCompleted
        }
        
        os_log("Progress status: %{public}@", log: .default, type: .info, String(describing: status))
        
        if let index = dailyProgress.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            dailyProgress[index] = DailyProgress(date: date, status: status, kegelPercentage: kegelPercentage, boxBreathingPercentage: boxBreathingPercentage, meditationPercentage: meditationPercentage)
        } else {
            dailyProgress.append(DailyProgress(date: date, status: status, kegelPercentage: kegelPercentage, boxBreathingPercentage: boxBreathingPercentage, meditationPercentage: meditationPercentage))
        }
        saveProgress()
    }
    
    private func saveProgress() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(dailyProgress) {
            userDefaults.set(encoded, forKey: progressKey)
        }
    }
    
    private func loadProgress() {
        if let savedProgress = userDefaults.object(forKey: progressKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedProgress = try? decoder.decode([DailyProgress].self, from: savedProgress) {
                dailyProgress = loadedProgress
            }
        }
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
            content: "Welcome to AlphaFlow, your path to peak masculinity. Our unique combination of exercises is designed to enhance your physical and mental strength, giving you the edge in all areas of life.",
            bulletPoints: [
                "Improved sexual health and performance",
                "Enhanced stress resilience and focus",
                "Better overall physical and mental well-being"
            ],
            proTip: "AlphaFlow integrates three powerful practices: Kegel exercises, box breathing, and meditation. Together, they form a comprehensive approach to male health that you won't find anywhere else."
        ),
        TutorialScreen(
            title: "Kegel Exercises",
            content: "Kegel exercises strengthen your pelvic floor muscles – the unsung heroes of your love life. Here's why you should care and how to do them:",
            bulletPoints: [
                "Boost your bedroom performance: Think of it as a gym workout for your manhood.",
                "Enhance pleasure: For you and your partner. It's a win-win situation!",
                "Improve control: Master the art of timing and last longer than you thought possible."
            ],
            proTip: "How to flex your love muscle:\n1. Find the right muscles (hint: they're the ones you use to stop peeing mid-stream).\n2. Squeeze those muscles for 5 seconds, then relax for 5 seconds.\n3. Repeat, but don't forget to breathe – passing out isn't sexy.\n\nPractice anywhere, anytime. It's your little secret superpower!"
        ),
        TutorialScreen(
            title: "Box Breathing",
            content: "Box breathing is a powerful technique used by elite athletes and Navy SEALs to maintain calm and focus under pressure.",
            bulletPoints: [
                "Instantly reduce stress and anxiety",
                "Improve focus and decision-making",
                "Enhance sleep quality"
            ],
            proTip: "Use box breathing before important meetings, workouts, or whenever you need to perform at your best."
        ),
        TutorialScreen(
            title: "Meditation",
            content: "Meditation is mental training that sharpens your mind and builds emotional resilience. It's not just for monks – it's for warriors who want to conquer their inner battlefield.",
            bulletPoints: [
                "Reduce stress and anxiety",
                "Improve focus and productivity",
                "Enhance self-awareness and emotional control"
            ],
            proTip: "Consistency is key. Even 5 minutes daily can make a significant impact."
        ),
        TutorialScreen(
            title: "You're Ready to Start!",
            content: "Congratulations, you're now equipped with the AlphaFlow toolkit for male excellence!",
            bulletPoints: [
                "Kegel exercises for pelvic strength",
                "Box breathing for stress control",
                "Meditation for mental mastery"
            ],
            proTip: "Remember, true alphas commit to daily practice. Your journey to peak performance starts now."
        )
    ]
}

struct ContentView: View {
    @State private var currentExercise: Exercise?
    @State private var isExerciseActive = false
    @State private var selectedTab: Tab = .home
    
    // Initialize SettingsManager
    @StateObject private var settings = SettingsManager()
    @StateObject private var progressManager = ProgressManager()
    
    @State private var showTutorial = false // Keep this line
    
    enum Exercise: CaseIterable {
        case kegel, boxBreathing, meditation
    }
    
    enum Tab {
        case home
        case exercises
        case progress
        case settings
    }
    
    var body: some View {
        NavigationStack {
            mainContent
        }
        .environmentObject(settings)
        .environmentObject(progressManager)
        .sheet(isPresented: $showTutorial) {
            TutorialView(showTutorial: $showTutorial)
        }
    }
    
    private var mainContent: some View {
        VStack {
            // Main Content based on Selected Tab
            switch selectedTab {
            case .home:
                homeView
            case .exercises:
                exercisesView
            case .progress:
                progressView
            case .settings:
                settingsView
            }
            
            // Bottom Navigation Bar
            bottomNavigationBar
        }
        .navigationDestination(isPresented: $isExerciseActive) {
            ExerciseView(initialExercise: currentExercise ?? .kegel, isPresented: $isExerciseActive, progressManager: progressManager)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Home View
    private var homeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ALPHAflow Title
                HStack(spacing: 0) {
                    Text("ALPHA")
                        .fontWeight(.bold)
                    Text("flow")
                        .italic()
                }
                .font(.system(size: 40))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                
                // Today's Session Card
                VStack {
                    Text("Today's Session")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    HStack(spacing: 15) {
                        exerciseInfoView(icon: "figure.walk", name: "Kegel", duration: "\(settings.kegelRounds) rounds")
                        exerciseInfoView(icon: "wind", name: "Box Breathing", duration: "\(settings.boxBreathingRounds) rounds")
                        exerciseInfoView(icon: "brain", name: "Meditation", duration: "\(settings.meditationDuration / 60) min")
                    }
                    
                    Button(action: {
                        startSession()
                    }) {
                        Text("Start Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                
                // Progress Overview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Progress Overview")
                        .font(.headline)
                    
                    WeekProgressView()
                        .frame(height: 100)
                    
                    HStack {
                        Text("Current Streak:")
                        Spacer()
                        Text("\(calculateStreak()) \(calculateStreak() == 1 ? "day" : "days")")
                            .fontWeight(.bold)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(15)
                
                // View Tutorial Button
                Button(action: {
                    showTutorial = true
                }) {
                    Text("View Tutorial")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Daily Motivation
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily Motivation")
                        .font(.headline)
                    
                    Text(getDailyMotivation())
                        .italic()
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(15)
            }
            .padding()
        }
    }
    
    private func exerciseInfoView(icon: String, name: String, duration: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            Text(duration)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func calculateStreak() -> Int {
        var streak = 0
        let sortedProgress = progressManager.dailyProgress.sorted { $0.date > $1.date }
        
        for progress in sortedProgress {
            if progress.status == .fullyCompleted {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func getDailyMotivation() -> String {
        // Implement logic to get a daily motivation quote
        return "Every small step leads to big changes. Keep going!"
    }
    
    // MARK: - Exercises View
    private var exercisesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Exercise Overview")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                overviewSection
                
                ForEach(Exercise.allCases, id: \.self) { exercise in
                    exerciseInfoCard(for: exercise)
                }
            }
            .padding()
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Practice Benefits")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Incorporating Kegel exercises, box breathing, and meditation into your daily routine can lead to significant improvements in your overall well-being. This combination strengthens your pelvic floor, enhances stress management, improves focus, and promotes relaxation. Regular practice can result in better bladder control, reduced anxiety, improved cardiovascular health, and increased mindfulness in daily life.")
                .font(.body)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func exerciseInfoCard(for exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: exercise.iconName)
                    .foregroundColor(.blue)
                Text(exercise.title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text(exercise.description)
                .font(.body)
            
            Text("How to perform:")
                .font(.headline)
                .padding(.top, 5)
            
            Text(exercise.howTo)
                .font(.body)
            
            Text("Benefits:")
                .font(.headline)
                .padding(.top, 5)
            
            Text(exercise.benefits)
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 20) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            MonthProgressView()
                .padding()
            
            Spacer()
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        Form {
            Section(header: Text("Preferences")) {
                Toggle("Dark Mode", isOn: .constant(false))
                Toggle("Enable Sounds", isOn: .constant(true))
            }
            
            Section(header: Text("Account")) {
                NavigationLink(destination: Text("Profile Settings")) {
                    Text("Profile")
                }
                NavigationLink(destination: Text("Privacy Settings")) {
                    Text("Privacy")
                }
            }
            
            Section {
                Button(action: {
                    // Handle Logout
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
            }
            
            // New Premium Features Section
            Section {
                Text("Premium Features")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                    .foregroundColor(.blue)
            }
            
            // Add Kegel Settings
            Section(header: Text("Kegel Settings")) {
                Stepper("Contract Duration: \(settings.kegelContractDuration) seconds", value: $settings.kegelContractDuration, in: 1...60)
                Stepper("Relax Duration: \(settings.kegelRelaxDuration) seconds", value: $settings.kegelRelaxDuration, in: 1...60)
                Stepper("Rounds: \(settings.kegelRounds)", value: $settings.kegelRounds, in: 1...100)
            }
            
            // Add Box Breathing Settings
            Section(header: Text("Box Breathing Settings")) {
                Stepper("Inhale Duration: \(settings.inhaleDuration) seconds", value: $settings.inhaleDuration, in: 1...60)
                Stepper("Hold Duration 1: \(settings.hold1Duration) seconds", value: $settings.hold1Duration, in: 1...60)
                Stepper("Exhale Duration: \(settings.exhaleDuration) seconds", value: $settings.exhaleDuration, in: 1...60)
                Stepper("Hold Duration 2: \(settings.hold2Duration) seconds", value: $settings.hold2Duration, in: 1...60)
                Stepper("Rounds: \(settings.boxBreathingRounds)", value: $settings.boxBreathingRounds, in: 1...100)
            }
            
            // Add Meditation Settings
            Section(header: Text("Meditation Settings")) {
                Stepper("Duration: \(settings.meditationDuration / 60) minutes", value: $settings.meditationDuration, in: 60...3600, step: 60)
                
                Picker("Meditation Sound", selection: $settings.meditationSoundFile) {
                    Text("None").tag("None")
                    Text("Earth").tag("meditation1")
                    Text("Sky").tag("meditation2")
                    Text("Ocean").tag("meditation3")
                }
            }
            
            Section(header: Text("Tutorial")) {
                Button("View Tutorial") {
                    showTutorial = true
                }
            }
        }
    }
    
    // MARK: - Bottom Navigation Bar
    private var bottomNavigationBar: some View {
        HStack {
            Spacer()
            tabBarItem(icon: "house.fill", title: "Home", selected: selectedTab == .home) {
                selectedTab = .home
            }
            Spacer()
            tabBarItem(icon: "figure.walk", title: "Exercises", selected: selectedTab == .exercises) {
                selectedTab = .exercises
            }
            Spacer()
            tabBarItem(icon: "chart.bar.fill", title: "Progress", selected: selectedTab == .progress) {
                selectedTab = .progress
            }
            Spacer()
            tabBarItem(icon: "gearshape.fill", title: "Settings", selected: selectedTab == .settings) {
                selectedTab = .settings
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground).shadow(radius: 2))
    }
    
    private func tabBarItem(icon: String, title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selected ? Color.blue : Color.gray)
        }
    }
    
    // MARK: - Helper Views
    private func CardView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(content)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private func ProgressChartView() -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Text("Chart Placeholder")
                    .foregroundColor(.gray)
            )
    }
    
    // MARK: - Added Functions
    
    private func startSession() {
        os_log("Starting new session", log: .default, type: .info)
        currentExercise = .kegel
        isExerciseActive = true
    }
}

// MARK: - Exercise Extensions
extension ContentView.Exercise {
    var title: String {
        switch self {
        case .kegel: return "Kegel"
        case .boxBreathing: return "Box Breathing"
        case .meditation: return "Meditation"
        }
    }
    
    var iconName: String {
        switch self {
        case .kegel: return "figure.strengthtraining.traditional"
        case .boxBreathing: return "wind"
        case .meditation: return "figure.mind.and.body"
        }
    }
    
    var description: String {
        switch self {
        case .kegel:
            return "Kegel exercises strengthen the pelvic floor muscles, which support the bladder, bowel, and uterus."
        case .boxBreathing:
            return "Box breathing is a relaxation technique that helps to regulate the autonomic nervous system and improve focus."
        case .meditation:
            return "Meditation is a practice that involves focusing the mind to achieve a mentally clear and emotionally calm state."
        }
    }
    
    var howTo: String {
        switch self {
        case .kegel:
            return "1. Identify the correct muscles by stopping urination midstream.\n2. Contract these muscles for 5 seconds.\n3. Relax for 5 seconds.\n4. Repeat for 10-15 rounds."
        case .boxBreathing:
            return "1. Inhale slowly for 4 seconds.\n2. Hold your breath for 4 seconds.\n3. Exhale slowly for 4 seconds.\n4. Hold your breath for 4 seconds.\n5. Repeat for several rounds."
        case .meditation:
            return "1. Find a comfortable seated position.\n2. Close your eyes and focus on your breath.\n3. When your mind wanders, gently bring your attention back to your breath.\n4. Start with 5-10 minutes and gradually increase duration."
        }
    }
    
    var benefits: String {
        switch self {
        case .kegel:
            return "• Improved bladder control\n• Enhanced sexual function\n• Stronger core muscles\n• Reduced risk of pelvic organ prolapse"
        case .boxBreathing:
            return "• Reduced stress and anxiety\n• Improved focus and concentration\n• Better emotional regulation\n• Enhanced cardiovascular health"
        case .meditation:
            return "• Reduced stress and anxiety\n• Improved emotional well-being\n• Enhanced self-awareness\n• Better sleep quality\n• Increased attention span"
        }
    }
}

// MARK: - ExerciseView
struct ExerciseView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var exercise: ContentView.Exercise
    @Binding var isPresented: Bool
    @ObservedObject var progressManager: ProgressManager
    
    @State private var kegelPercentage: Double = 0
    @State private var boxBreathingPercentage: Double = 0
    @State private var meditationPercentage: Double = 0
    
    @State private var currentExerciseIndex: Int = 0
    @State private var exercises: [ContentView.Exercise] = [.kegel, .boxBreathing, .meditation]
    
    init(initialExercise: ContentView.Exercise, isPresented: Binding<Bool>, progressManager: ProgressManager) {
        self._exercise = State(initialValue: initialExercise)
        self._isPresented = isPresented
        self.progressManager = progressManager
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(exercise.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            exerciseContent
                .frame(maxHeight: .infinity)
                .background(
                    DynamicBackgroundView(exercise: exercise)
                )
                .edgesIgnoringSafeArea(.all)
            
            if exercise == .meditation {
                Button(action: {
                    endSession()
                }) {
                    Text("End Session")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            } else {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Exit")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    
                    Button(action: {
                        performSkip()
                    }) {
                        Text("Skip")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(Color(UIColor.systemBackground))
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private var exerciseContent: some View {
        switch exercise {
        case .kegel:
            KegelView(onComplete: handleExerciseComplete, progressPercentage: $kegelPercentage)
                .environmentObject(settings)
                .onAppear { HapticFeedback.shared.isEnabled = true }
        case .boxBreathing:
            BoxBreathingView(onComplete: handleExerciseComplete, progressPercentage: $boxBreathingPercentage)
                .environmentObject(settings)
                .onAppear { HapticFeedback.shared.isEnabled = true }
        case .meditation:
            MeditationView(onComplete: handleExerciseComplete, progressPercentage: $meditationPercentage)
                .environmentObject(settings)
                .onAppear { HapticFeedback.shared.isEnabled = false }
        }
    }
    
    private func handleExerciseComplete() {
        currentExerciseIndex += 1
        if currentExerciseIndex < exercises.count {
            exercise = exercises[currentExerciseIndex]
        } else {
            endSession()
        }
    }
    
    private func performSkip() {
        handleExerciseComplete()
    }
    
    private func endSession() {
        // Disable haptic feedback when the session ends
        HapticFeedback.shared.isEnabled = false
        
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
    let exercise: ContentView.Exercise

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
        "Focus on contracting the muscles you use to stop urination.",
        "Keep your abdominal, buttock, and thigh muscles relaxed.",
        "Breathe normally during the exercises.",
        "Regular practice can improve bladder control and sexual performance."
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
                // Square shape
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 250, height: 250)
                
                // Progress indicator
                BreathingProgressShape(progress: viewModel.progress, phase: viewModel.currentPhase)
                    .stroke(Color.blue, lineWidth: 15)
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
        .onChange(of: viewModel.isComplete) { isComplete in
            if isComplete {
                onComplete()
            }
        }
    }
}

// Add this class before the BoxBreathingView struct
class BoxBreathingViewModel: ObservableObject {
    @Published var currentPhase: BoxBreathingPhase = .inhale
    @Published var phaseTimeRemaining: Double = 0
    @Published var currentRound: Int = 1
    @Published var progress: CGFloat = 0.0
    @Published var isReady: Bool = false
    @Published var isComplete: Bool = false
    
    private var settings: SettingsManager?
    private var displayLink: CADisplayLink?
    @Binding var progressPercentage: Double
    
    enum BoxBreathingPhase: String, CaseIterable {
        case inhale = "Inhale"
        case hold1 = "Hold Inhale"
        case exhale = "Exhale"
        case hold2 = "Hold Exhale"
    }
    
    init(progressPercentage: Binding<Double>) {
        self._progressPercentage = progressPercentage
    }
    
    func updateSettings(_ newSettings: SettingsManager) {
        self.settings = newSettings
    }
    
    func startExercise() {
        guard let settings = settings else { return }
        currentRound = 1
        currentPhase = .inhale
        phaseTimeRemaining = Double(getDuration(for: currentPhase))
        
        // Add a small delay before starting the exercise
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isReady = true
            self.startPhase()
        }
    }
    
    private func startPhase() {
        phaseTimeRemaining = Double(getDuration(for: currentPhase))
        progress = 0.0
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateProgress() {
        guard let settings = settings else { return }
        let duration = Double(getDuration(for: currentPhase))
        
        if phaseTimeRemaining > 0 {
            phaseTimeRemaining -= 1 / 60.0 // Assuming 60 FPS
            progress = CGFloat(1.0 - (phaseTimeRemaining / duration))
        } else {
            nextPhase()
        }
        
        updateProgressPercentage()
        
        if isComplete {
            displayLink?.invalidate()
            // Disable haptic feedback when the exercise is complete
            HapticFeedback.shared.isEnabled = false
        }
    }
    
    private func nextPhase() {
        guard let settings = settings else { return }
        
        // Play haptic feedback when transitioning phases
        HapticFeedback.shared.playHapticFeedback()
        
        if let nextPhaseIndex = BoxBreathingPhase.allCases.firstIndex(of: currentPhase)?.advanced(by: 1),
           nextPhaseIndex < BoxBreathingPhase.allCases.endIndex {
            currentPhase = BoxBreathingPhase.allCases[nextPhaseIndex]
            startPhase()
        } else {
            if currentRound >= settings.boxBreathingRounds {
                displayLink?.invalidate()
                progressPercentage = 1.0
                isComplete = true
                return
            }
            
            currentRound += 1
            currentPhase = .inhale
            startPhase()
        }
    }
    
    private func getDuration(for phase: BoxBreathingPhase) -> Int {
        guard let settings = settings else { return 4 } // Default duration
        switch phase {
        case .inhale: return settings.inhaleDuration
        case .hold1: return settings.hold1Duration
        case .exhale: return settings.exhaleDuration
        case .hold2: return settings.hold2Duration
        }
    }
    
    private func updateProgressPercentage() {
        guard let settings = settings else { return }
        let totalDuration = Double(settings.boxBreathingRounds * 4) // 4 phases per round
        let completedDuration = Double((currentRound - 1) * 4 + BoxBreathingPhase.allCases.firstIndex(of: currentPhase)!) + (1.0 - phaseTimeRemaining / Double(getDuration(for: currentPhase)))
        progressPercentage = min(1.0, completedDuration / totalDuration)
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

struct BreathingProgressShape: Shape {
    var progress: CGFloat
    var phase: BoxBreathingViewModel.BoxBreathingPhase
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sideLength = min(rect.width, rect.height)
        
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.minX + sideLength, y: rect.minY)
        let bottomRight = CGPoint(x: rect.minX + sideLength, y: rect.minY + sideLength)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.minY + sideLength)
        
        path.move(to: topLeft)
        
        switch phase {
        case .inhale:
            path.addLine(to: CGPoint(x: topLeft.x + sideLength * progress, y: topLeft.y))
        case .hold1:
            path.addLine(to: topRight)
            path.addLine(to: CGPoint(x: topRight.x, y: topRight.y + sideLength * progress))
        case .exhale:
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: CGPoint(x: bottomRight.x - sideLength * progress, y: bottomRight.y))
        case .hold2:
            path.addLine(to: topRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)
            path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - sideLength * progress))
        }
        
        return path
    }
}

struct WeekProgressView: View {
    @EnvironmentObject var progressManager: ProgressManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week's Progress")
                .font(.headline)
            
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    let date = startOfWeek().addingTimeInterval(Double(index) * 24 * 60 * 60)
                    let progress = progressManager.dailyProgress.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
                    
                    VStack {
                        Text(dayAbbreviation(for: date))
                            .font(.caption2)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForStatus(progress?.status))
                            .frame(height: 20)
                        Text(percentageText(for: progress))
                            .font(.caption2)
                    }
                }
            }
            
            HStack {
                legendItem(color: .green, label: "Completed")
                legendItem(color: .yellow, label: "Partial")
                legendItem(color: .red, label: "Missed")
            }
            .font(.caption)
        }
    }
    
    private func startOfWeek() -> Date {
        let calendar = Calendar.current
        let today = Date()
        if let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) {
            return sunday
        }
        return today // fallback to today if can't get Sunday for some reason
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
    
    private func colorForStatus(_ status: DailyProgress.ProgressStatus?) -> Color {
        switch status {
        case .fullyCompleted:
            return .green
        case .partiallyCompleted:
            return .yellow
        case .notCompleted, .none:
            return .red
        }
    }
    
    private func percentageText(for progress: DailyProgress?) -> String {
        guard let progress = progress else { return "0%" }
        let percentage = (progress.kegelPercentage + progress.boxBreathingPercentage + progress.meditationPercentage) / 3.0
        return String(format: "%.0f%%", percentage * 100)
    }
}

struct MonthProgressView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @State private var currentDate: Date = Date()
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(currentMonthYear())
                    .font(.headline)
                Spacer()
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(isCurrentMonth())
            }
            .padding(.horizontal)
            
            // Streak Counter
            Text("Current Streak: \(calculateStreak()) \(calculateStreak() == 1 ? "day" : "days")")
                .font(.headline)
                .foregroundColor(.green)
            
            // Weekly Progress View (only show for current month)
            if isCurrentMonth() {
                WeekProgressView()
            }
            
            // Monthly Calendar
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        let progress = progressManager.dailyProgress.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
                        let isToday = Calendar.current.isDateInToday(date)
                        
                        VStack {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .fontWeight(isToday ? .bold : .regular)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForStatus(progress?.status))
                                .overlay(
                                    Text(percentageText(for: progress))
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .aspectRatio(1, contentMode: .fit)
                    } else {
                        Color.clear
                    }
                }
            }
            
            // Legend
            HStack {
                legendItem(color: .green, label: "Completed")
                legendItem(color: .yellow, label: "Partial")
                legendItem(color: .red, label: "Missed")
            }
            .font(.caption)
        }
        .padding()
    }
    
    private func currentMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private func moveMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func isCurrentMonth() -> Bool {
        return Calendar.current.isDate(currentDate, equalTo: Date(), toGranularity: .month)
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Add trailing empty days to complete the last week
        let trailingEmptyDays = (7 - (days.count % 7)) % 7
        days += Array(repeating: nil as Date?, count: trailingEmptyDays)
        
        return days
    }
    
    private func calculateStreak() -> Int {
        var streak = 0
        let sortedProgress = progressManager.dailyProgress.sorted { $0.date > $1.date }
        
        for progress in sortedProgress {
            if progress.status == .fullyCompleted {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func percentageText(for progress: DailyProgress?) -> String {
        guard let progress = progress else { return "" }
        let percentage = (progress.kegelPercentage + progress.boxBreathingPercentage + progress.meditationPercentage) / 3.0
        return String(format: "%.0f%%", percentage * 100)
    }
    
    private func colorForStatus(_ status: DailyProgress.ProgressStatus?) -> Color {
        switch status {
        case .fullyCompleted:
            return .green
        case .partiallyCompleted:
            return .yellow
        case .notCompleted, .none:
            return .red
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Updated MeditationView
struct MeditationView: View {
    @EnvironmentObject var settings: SettingsManager
    let onComplete: () -> Void
    @Binding var progressPercentage: Double
    
    @State private var progress: CGFloat = 0.0
    @State private var timer: Timer?
    @State private var currentTime: Int = 0
    @State private var audioPlayer: AVAudioPlayer?
    
    let meditationTips = [
        "Find a quiet, comfortable place to sit.",
        "Close your eyes and focus on your breath.",
        "If your mind wanders, gently bring your attention back to your breath.",
        "Regular meditation can improve mental clarity and reduce stress."
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.teal, lineWidth: 15)
                    .frame(width: 250, height: 250)
                    .rotationEffect(Angle(degrees: -90))
                
                VStack {
                    Text("Meditate")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.teal)
                    
                    Text(timeString(from: currentTime))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.teal)
                }
            }
            
            Text("Focus on your breath")
                .font(.title2)
                .foregroundColor(.secondary)
            
            TipView(tips: meditationTips)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .onAppear {
            setupAudioSession()
            setupAudioPlayer()
            startMeditation()
        }
        .onDisappear {
            timer?.invalidate()
            audioPlayer?.stop()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupAudioPlayer() {
        guard settings.meditationSoundFile != "None" else {
            print("No sound selected")
            return
        }
        
        guard let soundURL = Bundle.main.url(forResource: settings.meditationSoundFile, withExtension: "mp3") else {
            print("Sound file not found: \(settings.meditationSoundFile).mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            print("Audio player setup successfully for: \(settings.meditationSoundFile).mp3")
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    
    private func startMeditation() {
        // Disable haptic feedback for meditation
        HapticFeedback.shared.isEnabled = false
        
        currentTime = settings.meditationDuration
        progress = 0.0
        
        print("Starting meditation with sound: \(settings.friendlyNameForSoundFile(settings.meditationSoundFile))")
        audioPlayer?.play()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if currentTime > 0 {
                currentTime -= 1
                progress = 1.0 - (CGFloat(currentTime) / CGFloat(settings.meditationDuration))
                updateProgress()
                
                if currentTime == 0 {
                    timer.invalidate()
                    audioPlayer?.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onComplete()
                    }
                }
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func updateProgress() {
        let rawProgress = Double(settings.meditationDuration - currentTime) / Double(settings.meditationDuration)
        progressPercentage = min(1.0, rawProgress)
        if progressPercentage >= 0.95 {
            progressPercentage = 1.0
        }
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Additional Helper Views
struct CardView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(content)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ProgressChartView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Text("Chart Placeholder")
                    .foregroundColor(.gray)
            )
    }
}

// Add this struct after the MonthProgressView

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showTutorial: Bool
    @State private var currentScreenIndex = 0
    
    var body: some View {
        VStack {
            TabView(selection: $currentScreenIndex) {
                ForEach(0..<TutorialContent.screens.count, id: \.self) { index in
                    TutorialScreenView(screen: TutorialContent.screens[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            HStack {
                if currentScreenIndex < TutorialContent.screens.count - 1 {
                    Button("Skip") {
                        endTutorial()
                    }
                    Spacer()
                    Button("Next") {
                        withAnimation {
                            currentScreenIndex += 1
                        }
                    }
                } else {
                    Button("Close") {
                        endTutorial()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    private func endTutorial() {
        showTutorial = false
        dismiss()
    }
}

struct TutorialScreenView: View {
    let screen: TutorialScreen
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(screen.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(screen.content)
                    .font(.body)
                
                if !screen.bulletPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(screen.bulletPoints, id: \.self) { point in
                            HStack(alignment: .top) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .padding(.top, 6)
                                Text(point)
                            }
                        }
                    }
                }
                
                if let proTip = screen.proTip {
                    VStack(alignment: .leading) {
                        Text("Pro Tip:")
                            .font(.headline)
                        Text(proTip)
                            .font(.body)
                            .italic()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct TipView: View {
    let tips: [String]
    @State private var currentTipIndex = 0
    @State private var opacity = 1.0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tip:")
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 4)
            
            Text(tips[currentTipIndex])
                .font(.subheadline)
                .opacity(opacity)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 60, alignment: .top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
        .onAppear(perform: startRotatingTips)
    }
    
    private func startRotatingTips() {
        guard tips.count > 1 else { return }
        
        Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentTipIndex = (currentTipIndex + 1) % tips.count
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1
                }
            }
        }
    }
}
