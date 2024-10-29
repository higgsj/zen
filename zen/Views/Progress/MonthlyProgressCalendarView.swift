import SwiftUI

struct MonthlyProgressCalendarView: View {
    @StateObject private var progressStore = ProgressStore()
    @State private var selectedDate = Date()
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
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
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                
                ForEach(daysInMonth(), id: \.self) { date in
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
    }
    
    // ... rest of the MonthlyProgressView implementation stays the same ...
}

// Move DayCell and MonthlyStatsView here as well 