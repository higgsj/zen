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
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    
    init(duration: TimeInterval) {
        self.timeRemaining = duration
    }
    
    func start() {
        isActive = true
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 0.1
                } else {
                    self.stop()
                }
            }
    }
    
    func stop() {
        isActive = false
        timer?.cancel()
        timer = nil
    }
    
    func reset(duration: TimeInterval) {
        stop()
        timeRemaining = duration
    }
}

struct ExerciseSession: Codable {
    let date: Date
    let kegelDuration: TimeInterval
    let boxBreathingDuration: TimeInterval
    let meditationDuration: TimeInterval
}
