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
            
            // Add motivational card here
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
            
            ExerciseCard(title: "Kegel Exercise", description: "Strengthen your pelvic floor muscles")
            ExerciseCard(title: "Box Breathing", description: "Control your breath, control your mind")
            ExerciseCard(title: "Meditation", description: "Find your inner peace and focus")
        }
    }
}

struct ExerciseCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ProgressTabView: View {
    var body: some View {
        Text("Progress View")
        // Implement progress tracking as described in app info
    }
}

struct SettingsTabView: View {
    var body: some View {
        Text("Settings View")
        // Implement settings as described in app info
    }
}

struct SessionView: View {
    @Binding var isSessionActive: Bool
    @State private var currentExercise: ExerciseType = .kegel
    @StateObject private var exerciseTimer = ExerciseTimer(duration: 0)
    @State private var sessionStart: Date?
    @State private var exerciseDurations: [ExerciseType: TimeInterval] = [:]
    
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
                
                Button(action: nextExercise) {
                    Text(currentExercise == .meditation ? "Finish Session" : "Next Exercise")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear(perform: startSession)
        .onDisappear(perform: endSession)
    }
    
    private func startSession() {
        sessionStart = Date()
        startExercise()
    }
    
    private func startExercise() {
        switch currentExercise {
        case .kegel:
            exerciseTimer.reset(duration: 300) // 5 minutes
        case .boxBreathing:
            exerciseTimer.reset(duration: 300) // 5 minutes
        case .meditation:
            exerciseTimer.reset(duration: 600) // 10 minutes
        }
        exerciseTimer.start()
    }
    
    private func nextExercise() {
        exerciseDurations[currentExercise] = 300 - exerciseTimer.timeRemaining
        exerciseTimer.stop()
        
        switch currentExercise {
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
        exerciseDurations[currentExercise] = 300 - exerciseTimer.timeRemaining
        let session = ExerciseSession(
            date: sessionStart ?? Date(),
            kegelDuration: exerciseDurations[.kegel] ?? 0,
            boxBreathingDuration: exerciseDurations[.boxBreathing] ?? 0,
            meditationDuration: exerciseDurations[.meditation] ?? 0
        )
        
        // Here, instead of saving to Supabase, you might want to save locally or use another service
        // For now, we'll just print the session data
        print("Session completed: \(session)")
        
        isSessionActive = false
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
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(1 - (timer.timeRemaining / 300)))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: timer.timeRemaining)
                
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
            
            exerciseInstructions
        }
        .onAppear(perform: updateExercisePhase)
        .onChange(of: timer.timeRemaining) { oldValue, newValue in
            updateExercisePhase()
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
    
    private func updateExercisePhase() {
        switch exerciseType {
        case .kegel:
            timer.currentPhase = timer.timeRemaining.truncatingRemainder(dividingBy: 10) < 5 ? "Contract" : "Relax"
        case .boxBreathing:
            let phase = Int(timer.timeRemaining.truncatingRemainder(dividingBy: 16))
            switch phase {
            case 0...3: timer.currentPhase = "Inhale"
            case 4...7: timer.currentPhase = "Hold"
            case 8...11: timer.currentPhase = "Exhale"
            default: timer.currentPhase = "Hold"
            }
        case .meditation:
            timer.currentPhase = "Meditate"
        }
    }
}
