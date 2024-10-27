import Foundation
import Combine

enum ExerciseType: String, CaseIterable {
    case kegel = "Kegel Exercise"
    case boxBreathing = "Box Breathing"
    case meditation = "Meditation"
}

class ExerciseTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var isActive = false
    @Published var currentPhase: String = ""
    @Published var currentRound: Int = 1
    @Published var progress: Double = 0.0
    @Published var phaseProgress: Double = 0.0
    @Published var phaseTimeRemaining: Int = 0
    @Published var roundsRemaining: Int
    @Published var displayTimeRemaining: Int = 0
    private var internalTimeRemaining: Double = 0
    private var currentPhaseTotalDuration: Double = 0
    private var exerciseType: ExerciseType
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    private var phaseTimer: AnyCancellable?
    private(set) var totalDuration: TimeInterval
    private var phases: [String]
    private var phaseDurations: [TimeInterval]
    private var currentPhaseIndex: Int = 0
    private(set) var totalRounds: Int
    
    init(type: ExerciseType, settings: ExerciseSettings) {
        print("Initializing ExerciseTimer for \(type) with settings: \(settings)")
        self.exerciseType = type
        switch type {
        case .kegel:
            self.phases = ["Contract", "Relax"]
            self.phaseDurations = [settings.kegelContractDuration, settings.kegelRelaxDuration]
            self.totalRounds = settings.kegelRounds
        case .boxBreathing:
            self.phases = ["Inhale", "Hold Inhale", "Exhale", "Hold Exhale"]
            self.phaseDurations = [settings.boxBreathingInhaleDuration, settings.boxBreathingHoldInhaleDuration,
                                   settings.boxBreathingExhaleDuration, settings.boxBreathingHoldExhaleDuration]
            self.totalRounds = settings.boxBreathingRounds
        case .meditation:
            self.phases = ["Meditate"]
            self.phaseDurations = [settings.meditationDuration * 60] // Convert minutes to seconds
            self.totalRounds = 1
        }
        
        self.totalDuration = phaseDurations.reduce(0, +) * Double(totalRounds)
        self.timeRemaining = totalDuration
        self.currentPhase = phases[0]
        self.roundsRemaining = self.totalRounds
    }
    
    func start() {
        isActive = true
        startPhase()
    }
    
    private func startPhase() {
        print("Starting phase for \(exerciseType) - Phase: \(currentPhase), Round: \(currentRound)")  // Debug print
        
        currentPhaseTotalDuration = phaseDurations[currentPhaseIndex]
        internalTimeRemaining = currentPhaseTotalDuration
        displayTimeRemaining = Int(ceil(internalTimeRemaining))
        phaseProgress = 0.0

        phaseTimer?.cancel()  // Cancel existing timer if any
        phaseTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updatePhase()
            }
    }
    
    private func updatePhase() {
        if internalTimeRemaining > 0.1 {
            internalTimeRemaining -= 0.1
            timeRemaining -= 0.1
            displayTimeRemaining = max(1, Int(ceil(internalTimeRemaining)))
            phaseTimeRemaining = displayTimeRemaining
            phaseProgress = (currentPhaseTotalDuration - internalTimeRemaining) / currentPhaseTotalDuration
            progress = 1.0 - (timeRemaining / totalDuration)
            
            // Add debug logging
            if exerciseType == .boxBreathing {
                print("Box Breathing - Phase: \(currentPhase), Round: \(currentRound), Remaining: \(roundsRemaining)")
                print("Time remaining: \(timeRemaining), Internal time: \(internalTimeRemaining)")
            }
        } else {
            phaseProgress = 1.0
            print("Phase complete, moving to next phase")  // Debug print
            moveToNextPhase()
        }
        
        currentPhase = phases[currentPhaseIndex]
    }
    
    private func moveToNextPhase() {
        let oldPhaseIndex = currentPhaseIndex
        currentPhaseIndex = (currentPhaseIndex + 1) % phases.count
        
        print("Moving from phase \(oldPhaseIndex) to \(currentPhaseIndex)")  // Debug print
        print("Current exercise: \(exerciseType), Phases count: \(phases.count)")  // Debug print
        
        // If we've completed all phases in the current round
        if currentPhaseIndex == 0 {
            print("Completed full round for \(exerciseType)")  // Debug print
            print("Before decrement - Rounds remaining: \(roundsRemaining), Current round: \(currentRound)")  // Debug print
            
            roundsRemaining -= 1
            
            print("After decrement - Rounds remaining: \(roundsRemaining), Current round: \(currentRound)")  // Debug print
            
            if roundsRemaining <= 0 {
                print("No rounds remaining, completing exercise: \(exerciseType)")  // Debug print
                completeExercise()
                return  // Add explicit return to prevent starting new phase
            } else {
                currentRound += 1
                print("Starting new round \(currentRound) for \(exerciseType)")  // Debug print
                startPhase()
            }
        } else {
            startPhase()
        }
    }

    private func completeExercise() {
        print("Exercise completed: \(exerciseType)")  // Debug print
        stop()
        DispatchQueue.main.async {
            print("Posting exercise complete notification for: \(self.exerciseType)")  // Debug print
            NotificationCenter.default.post(
                name: .exerciseComplete,
                object: nil,
                userInfo: ["exerciseType": self.exerciseType]
            )
        }
    }

    func stop() {
        isActive = false
        phaseTimer?.cancel()
        phaseTimer = nil
    }
    
    func reset() {
        stop()
        timeRemaining = totalDuration
        currentRound = 1
        currentPhaseIndex = 0
        currentPhase = phases[0]
        progress = 0.0
        phaseProgress = 0.0
        displayTimeRemaining = Int(ceil(phaseDurations[0]))
        roundsRemaining = totalRounds
        internalTimeRemaining = phaseDurations[0]
    }
    
    func updateSettings(type: ExerciseType, settings: ExerciseSettings) {
        self.exerciseType = type  // Add this line to update the stored exercise type
        
        switch type {
        case .kegel:
            self.phases = ["Contract", "Relax"]
            self.phaseDurations = [settings.kegelContractDuration, settings.kegelRelaxDuration]
            self.totalRounds = settings.kegelRounds
        case .boxBreathing:
            self.phases = ["Inhale", "Hold Inhale", "Exhale", "Hold Exhale"]
            self.phaseDurations = [settings.boxBreathingInhaleDuration, settings.boxBreathingHoldInhaleDuration,
                                   settings.boxBreathingExhaleDuration, settings.boxBreathingHoldExhaleDuration]
            self.totalRounds = settings.boxBreathingRounds
        case .meditation:
            self.phases = ["Meditate"]
            self.phaseDurations = [settings.meditationDuration * 60] // Convert minutes to seconds
            self.totalRounds = 1
        }
        
        self.totalDuration = phaseDurations.reduce(0, +) * Double(totalRounds)
        self.timeRemaining = totalDuration
        self.currentPhase = phases[0]
        self.currentRound = 1
        self.progress = 0.0
        self.phaseProgress = 0.0
        self.phaseTimeRemaining = 0
        self.roundsRemaining = totalRounds
    }
    
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ExerciseSettings: Codable, Equatable {
    var kegelContractDuration: Double = 5
    var kegelRelaxDuration: Double = 5
    var kegelRounds: Int = 10
    
    var boxBreathingInhaleDuration: Double = 4
    var boxBreathingHoldInhaleDuration: Double = 4
    var boxBreathingExhaleDuration: Double = 4
    var boxBreathingHoldExhaleDuration: Double = 4
    var boxBreathingRounds: Int = 4
    
    var meditationDuration: Double = 5 // in minutes
}

struct ExerciseSession: Codable {
    let date: Date
    let kegelDuration: TimeInterval
    let boxBreathingDuration: TimeInterval
    let meditationDuration: TimeInterval
}

extension Notification.Name {
    static let exerciseComplete = Notification.Name("exerciseComplete")
}
