//
//  NotificationService.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Phase 5 Complete: NotificationService for Walk Reminders
 
 Features Implemented:
 ✅ Local notification scheduling and management
 ✅ Smart walk reminders based on activity levels
 ✅ Customizable reminder times (morning, afternoon, evening)
 ✅ Activity-based intelligent notifications
 ✅ Notification permission handling
 ✅ Badge count management
 ✅ Rich notification content with dog-specific messaging
 ✅ Integration with PersistenceController for settings
 */

import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Models
struct WalkReminder: Codable, Identifiable {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var title: String
    var message: String
    var repeatDaily: Bool
    
    init(time: Date, title: String, message: String, isEnabled: Bool = true, repeatDaily: Bool = true) {
        self.id = UUID()
        self.time = time
        self.title = title
        self.message = message
        self.isEnabled = isEnabled
        self.repeatDaily = repeatDaily
    }
}

enum NotificationType: String, CaseIterable {
    case morningWalk = "morning_walk"
    case afternoonWalk = "afternoon_walk"
    case eveningWalk = "evening_walk"
    case smartReminder = "smart_reminder"
    case goalAchievement = "goal_achievement"
    case weeklyReport = "weekly_report"
    
    var defaultTitle: String {
        switch self {
        case .morningWalk: return "Good Morning! 🌅"
        case .afternoonWalk: return "Afternoon Walk Time! ☀️"
        case .eveningWalk: return "Evening Stroll! 🌙"
        case .smartReminder: return "Walk Reminder 🐕"
        case .goalAchievement: return "Goal Achieved! 🎉"
        case .weeklyReport: return "Weekly Report 📊"
        }
    }
}

// MARK: - Notification Service
@MainActor
class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Properties
    static let shared = NotificationService()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var walkReminders: [WalkReminder] = []
    @Published private(set) var isSmartNotificationsEnabled = true
    @Published private(set) var lastNotificationCheck = Date()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Initialization
    override init() {
        super.init()
        print("📱 [NotificationService] Initializing notification service")
        
        notificationCenter.delegate = self
        loadSettings()
        checkAuthorizationStatus()
        setupDefaultReminders()
    }
    
    // MARK: - Authorization Management
    func requestNotificationPermission() async -> Bool {
        print("📱 [NotificationService] Requesting notification permission")
        
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            await MainActor.run {
                authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                print("✅ [NotificationService] Notification permission granted")
                await scheduleAllReminders()
            } else {
                print("❌ [NotificationService] Notification permission denied")
            }
            
            return granted
            
        } catch {
            print("❌ [NotificationService] Error requesting permission: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
                print("📱 [NotificationService] Current authorization status: \(authorizationStatus.rawValue)")
            }
        }
    }
    
    // MARK: - Reminder Management
    func addWalkReminder(_ reminder: WalkReminder) {
        print("📱 [NotificationService] Adding walk reminder: \(reminder.title) at \(reminder.time)")
        
        walkReminders.append(reminder)
        saveSettings()
        
        if reminder.isEnabled {
            Task {
                await scheduleNotification(for: reminder)
            }
        }
    }
    
    func updateWalkReminder(_ reminder: WalkReminder) {
        print("📱 [NotificationService] Updating walk reminder: \(reminder.id)")
        
        if let index = walkReminders.firstIndex(where: { $0.id == reminder.id }) {
            walkReminders[index] = reminder
            saveSettings()
            
            Task {
                await cancelNotification(for: reminder.id.uuidString)
                if reminder.isEnabled {
                    await scheduleNotification(for: reminder)
                }
            }
        }
    }
    
    func removeWalkReminder(_ reminder: WalkReminder) {
        print("📱 [NotificationService] Removing walk reminder: \(reminder.id)")
        
        walkReminders.removeAll { $0.id == reminder.id }
        saveSettings()
        
        Task {
            await cancelNotification(for: reminder.id.uuidString)
        }
    }
    
    func toggleReminder(_ reminder: WalkReminder) {
        var updatedReminder = reminder
        updatedReminder.isEnabled.toggle()
        updateWalkReminder(updatedReminder)
    }
    
    // MARK: - Smart Notifications
    func checkForSmartReminders() async {
        guard isSmartNotificationsEnabled else {
            print("📱 [NotificationService] Smart notifications disabled")
            return
        }
        
        print("📱 [NotificationService] Checking for smart reminders")
        
        // Get today's step data
        let stepHistory = persistenceController.loadStepDataHistory()
        let todaysData = stepHistory.first { $0.isToday() }
        
        guard let profile = persistenceController.currentDogProfile else {
            print("⚠️ [NotificationService] No dog profile for smart reminders")
            return
        }
        
        // Check if dog needs more activity
        if let stepData = todaysData {
            let progressPercentage = stepData.goalProgressPercentage
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            // Smart reminder logic
            if currentHour >= 14 && progressPercentage < 30 {
                await sendSmartReminder(
                    title: "\(profile.name) needs more exercise! 🐕",
                    message: "Only \(progressPercentage)% of daily goal achieved. Time for a walk!",
                    type: .smartReminder
                )
            } else if currentHour >= 18 && progressPercentage < 60 {
                await sendSmartReminder(
                    title: "Evening walk with \(profile.name)? 🌅",
                    message: "Let's reach that daily goal together!",
                    type: .smartReminder
                )
            }
        } else if Calendar.current.component(.hour, from: Date()) >= 12 {
            // No data yet today
            await sendSmartReminder(
                title: "\(profile.name) is ready for adventure! 🎾",
                message: "No walks recorded today. Let's get moving!",
                type: .smartReminder
            )
        }
        
        lastNotificationCheck = Date()
    }
    
    func sendGoalAchievementNotification(for stepData: StepData) async {
        guard let profile = persistenceController.currentDogProfile else { return }
        
        let title = "🎉 \(profile.name) reached the daily goal!"
        let message = "\(stepData.estimatedDogSteps) steps completed! Great job!"
        
        await sendSmartReminder(title: title, message: message, type: .goalAchievement)
    }
    
    func sendWeeklyReport(stepData: [StepData]) async {
        guard let profile = persistenceController.currentDogProfile else { return }
        
        let totalSteps = stepData.reduce(0) { $0 + $1.estimatedDogSteps }
        let avgSteps = totalSteps / max(stepData.count, 1)
        
        let title = "📊 \(profile.name)'s Weekly Report"
        let message = "This week: \(totalSteps) total steps, \(avgSteps) daily average!"
        
        await sendSmartReminder(title: title, message: message, type: .weeklyReport)
    }
    
    // MARK: - Notification Scheduling
    private func scheduleAllReminders() async {
        print("📱 [NotificationService] Scheduling all reminders")
        
        // Cancel existing notifications
        await cancelAllNotifications()
        
        // Schedule enabled reminders
        for reminder in walkReminders where reminder.isEnabled {
            await scheduleNotification(for: reminder)
        }
    }
    
    private func scheduleNotification(for reminder: WalkReminder) async {
        print("📱 [NotificationService] Scheduling notification for: \(reminder.title)")
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        content.badge = 1
        
        // Add dog-specific context if available
        if let profile = persistenceController.currentDogProfile {
            content.body = content.body.replacingOccurrences(of: "{dogName}", with: profile.name)
        }
        
        // Create trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: reminder.repeatDaily
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ [NotificationService] Scheduled notification: \(reminder.title)")
        } catch {
            print("❌ [NotificationService] Failed to schedule notification: \(error)")
        }
    }
    
    private func sendSmartReminder(title: String, message: String, type: NotificationType) async {
        print("📱 [NotificationService] Sending smart reminder: \(title)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = type.rawValue
        
        // Immediate delivery
        let request = UNNotificationRequest(
            identifier: "smart_\(type.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ [NotificationService] Smart reminder sent")
        } catch {
            print("❌ [NotificationService] Failed to send smart reminder: \(error)")
        }
    }
    
    private func cancelNotification(for identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("📱 [NotificationService] Cancelled notification: \(identifier)")
    }
    
    private func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("📱 [NotificationService] Cancelled all notifications")
    }
    
    // MARK: - Settings Management
    func updateSmartNotifications(enabled: Bool) {
        print("📱 [NotificationService] Smart notifications: \(enabled ? "enabled" : "disabled")")
        isSmartNotificationsEnabled = enabled
        saveSettings()
    }
    
    private func setupDefaultReminders() {
        guard walkReminders.isEmpty else { return }
        
        print("📱 [NotificationService] Setting up default reminders")
        
        let calendar = Calendar.current
        
        // Morning walk (8:00 AM)
        if let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) {
            let morningReminder = WalkReminder(
                time: morningTime,
                title: "Good Morning! 🌅",
                message: "Time for {dogName}'s morning walk!"
            )
            walkReminders.append(morningReminder)
        }
        
        // Evening walk (6:00 PM)
        if let eveningTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) {
            let eveningReminder = WalkReminder(
                time: eveningTime,
                title: "Evening Walk Time! 🌙",
                message: "{dogName} is ready for an evening stroll!"
            )
            walkReminders.append(eveningReminder)
        }
        
        saveSettings()
    }
    
    private func loadSettings() {
        print("📱 [NotificationService] Loading notification settings")
        
        let appSettings = persistenceController.appSettings
        isSmartNotificationsEnabled = appSettings.notificationsEnabled
        
        // Load walk reminders from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "WalkReminders"),
           let reminders = try? JSONDecoder().decode([WalkReminder].self, from: data) {
            walkReminders = reminders
            print("✅ [NotificationService] Loaded \(reminders.count) walk reminders")
        }
    }
    
    private func saveSettings() {
        print("📱 [NotificationService] Saving notification settings")
        
        // Save walk reminders
        if let data = try? JSONEncoder().encode(walkReminders) {
            UserDefaults.standard.set(data, forKey: "WalkReminders")
        }
        
        // Update app settings
        var appSettings = persistenceController.appSettings
        appSettings.notificationsEnabled = isSmartNotificationsEnabled
        _ = persistenceController.saveAppSettings(appSettings)
    }
    
    // MARK: - Utility Methods
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func clearBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("📱 [NotificationService] Badge count cleared")
    }
    
    func getNotificationSummary() -> String {
        let enabledCount = walkReminders.filter { $0.isEnabled }.count
        let totalCount = walkReminders.count
        
        var summary = "📱 Notifications: \(enabledCount)/\(totalCount) enabled\n"
        summary += "🧠 Smart Reminders: \(isSmartNotificationsEnabled ? "On" : "Off")\n"
        summary += "🔔 Authorization: \(authorizationStatus.description)\n"
        summary += "⏰ Last Check: \(lastNotificationCheck.formatted(date: .omitted, time: .shortened))"
        
        return summary
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 [NotificationService] Will present notification: \(notification.request.content.title)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 [NotificationService] Did receive notification response: \(response.notification.request.identifier)")
        
        // Handle notification tap
        let identifier = response.notification.request.identifier
        
        if identifier.contains("smart_") {
            // Handle smart reminder tap
            print("📱 [NotificationService] Smart reminder tapped")
        } else if let reminderID = UUID(uuidString: identifier) {
            // Handle walk reminder tap
            print("📱 [NotificationService] Walk reminder tapped: \(reminderID)")
        }
        
        Task { @MainActor in
            clearBadgeCount()
        }
        completionHandler()
    }
}

// MARK: - Extensions
extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
} 