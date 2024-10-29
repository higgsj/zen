import Foundation

struct DailyProgress: Codable {
    let date: Date
    let completedExercises: Set<ExerciseType>
    
    var completionPercentage: Double {
        Double(completedExercises.count) / Double(ExerciseType.allCases.count)
    }
}

class ProgressStore: ObservableObject {
    @Published private(set) var dailyProgress: [Date: DailyProgress] = [:]
    private let storeKey = "dailyProgress"
    
    init() {
        loadProgress()
    }
    
    func recordExercise(_ type: ExerciseType) {
        let today = Calendar.current.startOfDay(for: Date())
        var todayProgress = dailyProgress[today] ?? DailyProgress(date: today, completedExercises: [])
        var updatedExercises = todayProgress.completedExercises
        updatedExercises.insert(type)
        dailyProgress[today] = DailyProgress(date: today, completedExercises: updatedExercises)
        saveProgress()
    }
    
    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let progress = try? JSONDecoder().decode([Date: DailyProgress].self, from: data) else {
            return
        }
        dailyProgress = progress
    }
    
    private func saveProgress() {
        guard let data = try? JSONEncoder().encode(dailyProgress) else { return }
        UserDefaults.standard.set(data, forKey: storeKey)
    }
} 