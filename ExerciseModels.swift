import Foundation
import Combine
import AVFoundation

class ExerciseTimer: ObservableObject {
    // Remove ExerciseType enum from here since it's now in SharedModels.swift
    
    @Published var timeRemaining: TimeInterval
    // ... rest of the file stays the same ...
} 