import Foundation

struct DailyProgress: Codable, Equatable {
    let date: Date
    let completedExercises: Set<ExerciseType>
    
    var completionPercentage: Double {
        Double(completedExercises.count) / Double(ExerciseType.allCases.count)
    }
    
    static func == (lhs: DailyProgress, rhs: DailyProgress) -> Bool {
        lhs.date == rhs.date && lhs.completedExercises == rhs.completedExercises
    }
}

class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    @Published private(set) var dailyProgress: [Date: DailyProgress] = [:]
    private let storeKey = "dailyProgress"
    private let calendar = Calendar.current
    
    init() {
        loadProgress()
    }
    
    func recordExercise(_ type: ExerciseType) {
        let today = calendar.startOfDay(for: Date())
        
        // Create new progress instance with updated exercises
        var updatedExercises = dailyProgress[today]?.completedExercises ?? Set<ExerciseType>()
        updatedExercises.insert(type)
        
        // Create new progress instance
        let newProgress = DailyProgress(date: today, completedExercises: updatedExercises)
        
        // Update the progress on the main thread
        DispatchQueue.main.async {
            self.dailyProgress[today] = newProgress
            self.objectWillChange.send()  // Explicitly notify observers of change
            self.saveProgress()
        }
        
        print("Recording exercise: \(type)")
        print("Updated progress for today: \(updatedExercises)")
        print("Completion percentage: \(newProgress.completionPercentage)")
    }
    
    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: storeKey) else {
            print("No progress data found in UserDefaults")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let progress = try decoder.decode([String: DailyProgress].self, from: data)
            
            // Convert string dates back to Date objects
            dailyProgress = progress.reduce(into: [:]) { result, entry in
                if let date = dateFormatter.date(from: entry.key) {
                    result[date] = entry.value
                }
            }
            
            print("Loaded progress data: \(dailyProgress)")
        } catch {
            print("Error decoding progress data: \(error)")
        }
    }
    
    private func saveProgress() {
        do {
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            // Convert Date keys to string keys for reliable storage
            let progressDict = dailyProgress.reduce(into: [String: DailyProgress]()) { result, entry in
                let dateString = dateFormatter.string(from: entry.key)
                result[dateString] = entry.value
            }
            
            let data = try encoder.encode(progressDict)
            UserDefaults.standard.set(data, forKey: storeKey)
            UserDefaults.standard.synchronize()  // Force immediate save
            print("Progress saved successfully")
        } catch {
            print("Error saving progress: \(error)")
        }
    }
} 