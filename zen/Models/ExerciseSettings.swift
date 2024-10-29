import Foundation

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