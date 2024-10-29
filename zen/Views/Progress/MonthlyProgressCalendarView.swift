import SwiftUI

struct MonthlyProgressCalendarView: View {
    @StateObject private var progressStore = ProgressStore.shared
    @State private var selectedDate = Date()
    
    // Add this to force refresh when progress updates
    @State private var lastUpdate = Date()
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // Create a struct for weekday labels with unique IDs
    private struct WeekdayLabel: Identifiable {
        let id: Int
        let label: String
    }
    
    // Create weekday labels with unique IDs
    private let weekdayLabels: [WeekdayLabel] = {
        let labels = ["S", "M", "T", "W", "T", "F", "S"]
        return labels.enumerated().map { WeekdayLabel(id: $0, label: $1) }
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Text(monthFormatter.string(from: selectedDate))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Use WeekdayLabel for unique IDs
                ForEach(weekdayLabels) { weekday in
                    Text(weekday.label)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                
                // Use enumerated for unique IDs for calendar days
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(date: date, progress: progressStore.dailyProgress[date]?.completionPercentage ?? 0)
                    } else {
                        Color.clear
                    }
                }
            }
            .padding(.horizontal)
            
            // Monthly Stats
            MonthlyStatsView(selectedDate: selectedDate, progressStore: progressStore)
        }
        .padding(.vertical)
        // Add this to refresh the view when progress changes
        .onReceive(progressStore.objectWillChange) { _ in
            lastUpdate = Date()
        }
    }
    
    private func previousMonth() {
        withAnimation {
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextMonth() {
        withAnimation {
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let offsetDays = firstWeekday - 1
        
        let daysInMonth = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                days.append(calendar.startOfDay(for: date))
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let progress: Double
    
    private let size: CGFloat = 35
    
    var body: some View {
        Circle()
            .fill(progressColor)
            .frame(width: size, height: size)
            .overlay(
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(progress > 0.3 ? .white : .primary)
            )
    }
    
    private var progressColor: Color {
        switch progress {
        case 0:
            return Color(.systemGray6)
        case 0..<0.34:  // 1 exercise
            return .blue
        case 0.34..<0.67:  // 2 exercises
            return .blue.opacity(0.8)
        default:  // 3 exercises
            return .blue
        }
    }
}

struct MonthlyStatsView: View {
    let selectedDate: Date
    let progressStore: ProgressStore
    
    private var monthStats: (completedDays: Int, totalPercentage: Double) {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let daysInMonth = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var completedDays = 0
        var totalPercentage = 0.0
        
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                let startOfDay = calendar.startOfDay(for: date)
                if let progress = progressStore.dailyProgress[startOfDay] {
                    completedDays += progress.completionPercentage > 0 ? 1 : 0
                    totalPercentage += progress.completionPercentage
                }
            }
        }
        
        return (completedDays, totalPercentage / Double(daysInMonth))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Monthly Statistics")
                .font(.headline)
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(monthStats.completedDays)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Active Days")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("\(Int(monthStats.totalPercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}