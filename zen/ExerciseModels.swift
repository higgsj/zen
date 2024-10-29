import Foundation
import Combine
import AVFoundation

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
    
    @Published var audioHapticManager: AudioHapticManager
    
    init(type: ExerciseType, settings: ExerciseSettings, audioHapticManager: AudioHapticManager) {
        print("Initializing ExerciseTimer for \(type) with settings: \(settings)")
        self.exerciseType = type
        self.audioHapticManager = audioHapticManager
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
        print("Starting phase for \(exerciseType) - Phase: \(currentPhase), Round: \(currentRound)")
        
        // Play voice prompts at the START of each phase
        switch exerciseType {
        case .kegel:
            if currentPhase == "Contract" {
                audioHapticManager.playVoicePrompt("Squeeze")
                audioHapticManager.playHaptic(.heavy)
            } else if currentPhase == "Relax" {
                audioHapticManager.playVoicePrompt("Relax")
                audioHapticManager.playHaptic(.medium)
            }
        case .boxBreathing:
            switch currentPhase {
            case "Inhale":
                audioHapticManager.playVoicePrompt("Inhale")
            case "Hold Inhale", "Hold Exhale":
                audioHapticManager.playVoicePrompt("Hold")
            case "Exhale":
                audioHapticManager.playVoicePrompt("Exhale")
            default:
                break
            }
            audioHapticManager.playHaptic(.medium)
        case .meditation:
            if currentRound == 1 && currentPhaseIndex == 0 {
                audioHapticManager.playHaptic(.medium)
                audioHapticManager.startMeditationMusic()
            }
        }
        
        currentPhaseTotalDuration = phaseDurations[currentPhaseIndex]
        internalTimeRemaining = currentPhaseTotalDuration
        displayTimeRemaining = Int(ceil(internalTimeRemaining))
        phaseProgress = 0.0
        
        phaseTimer?.cancel()
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
        } else {
            phaseProgress = 1.0
            print("Phase complete, moving to next phase")
            moveToNextPhase()
        }
    }
    
    private func moveToNextPhase() {
        let oldPhaseIndex = currentPhaseIndex
        currentPhaseIndex = (currentPhaseIndex + 1) % phases.count
        currentPhase = phases[currentPhaseIndex]
        
        print("Moving from phase \(oldPhaseIndex) to \(currentPhaseIndex)")
        
        // If we've completed all phases in the current round
        if currentPhaseIndex == 0 {
            print("Completed full round for \(exerciseType)")
            roundsRemaining -= 1
            
            if roundsRemaining <= 0 {
                print("No rounds remaining, completing exercise: \(exerciseType)")
                completeExercise()
                return
            } else {
                currentRound += 1
                print("Starting new round \(currentRound) for \(exerciseType)")
                startPhase()
            }
        } else {
            startPhase()
        }
    }
    
    private func completeExercise() {
        print("Exercise completed: \(exerciseType)")
        
        // Stop meditation music
        if exerciseType == .meditation {
            audioHapticManager.stopMeditationMusic()
        }
        
        // Play success haptic
        audioHapticManager.playHaptic(.success)
        
        stop()
        DispatchQueue.main.async {
            print("Posting exercise complete notification for: \(self.exerciseType)")
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
        
        // Stop meditation music if it's playing
        if exerciseType == .meditation {
            audioHapticManager.stopMeditationMusic()
        }
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
        self.currentRound = 1
        self.progress = 0.0
        self.phaseProgress = 0.0
        self.phaseTimeRemaining = 0
        self.roundsRemaining = totalRounds
    }
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