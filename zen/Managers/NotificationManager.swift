import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    @Published var reminderTime = Date()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    
    init() {
        loadSettings()
        checkNotificationStatus()
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            await MainActor.run {
                self.isNotificationsEnabled = granted
                self.saveSettings()
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func scheduleNotification() {
        // Remove any existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        guard isNotificationsEnabled else { return }
        
        // Create time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Create trigger
        var trigger = DateComponents()
        trigger.hour = components.hour
        trigger.minute = components.minute
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Time for Your Daily Practice"
        content.body = "Maintain your progress with today's exercises"
        content.sound = .default
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func checkNotificationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func loadSettings() {
        isNotificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        if let savedTime = defaults.object(forKey: "reminderTime") as? Date {
            reminderTime = savedTime
        } else {
            // Default to 9:00 AM if no time is saved
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            reminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    private func saveSettings() {
        defaults.set(isNotificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(reminderTime, forKey: "reminderTime")
        
        if isNotificationsEnabled {
            scheduleNotification()
        } else {
            notificationCenter.removeAllPendingNotificationRequests()
        }
    }
} 