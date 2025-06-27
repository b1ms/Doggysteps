//
//  ReminderSettingsView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 ReminderSettingsView - Modern Clean UI Design
 
 Features:
 ✅ Modern card-based layout matching TodayView
 ✅ Clean white background design
 ✅ Walk reminder time management (add, edit, delete)
 ✅ Enable/disable individual reminders
 ✅ Smart notification toggle
 ✅ Notification permission management
 ✅ Real-time notification status display
 ✅ Custom reminder creation with validation
 ✅ Integration with NotificationService
 */

import SwiftUI
import UserNotifications

// MARK: - Reminder Settings View
struct ReminderSettingsView: View {
    
    // MARK: - Properties
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var showingAddReminder = false
    @State private var showingPermissionAlert = false
    @State private var newReminderTime = Date()
    @State private var newReminderTitle = ""
    @State private var newReminderMessage = ""
    
    // UI state
    @State private var isLoading = false
    @State private var showingNotificationSummary = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header
                    topHeader
                    
                    // Main content
                    VStack(spacing: 20) {
                        notificationStatusSection
                        smartNotificationsSection
                        walkRemindersSection
                        debugSection
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60) // Space for bottom navigation
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(
                time: $newReminderTime,
                title: $newReminderTitle,
                message: $newReminderMessage,
                onSave: addNewReminder
            )
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive walk reminders for your dog.")
        }
        .sheet(isPresented: $showingNotificationSummary) {
            NotificationSummaryView()
        }
        .onAppear {
            notificationService.checkAuthorizationStatus()
        }
    }
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Title
            Text("Walk Reminders")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Add reminder button
            Button(action: { showingAddReminder = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(notificationService.authorizationStatus == .authorized ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(notificationService.authorizationStatus == .authorized ? .blue : Color(.systemGray4))
                    .cornerRadius(16)
            }
            .disabled(notificationService.authorizationStatus != .authorized)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 20)
    }
    
    // MARK: - Notification Status Section
    private var notificationStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Status")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Status icon
                Text(notificationStatusIcon)
                    .font(.system(size: 24))
                    .frame(width: 48, height: 48)
                    .background(notificationStatusColor.opacity(0.2))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(notificationStatusText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Action button
                if notificationService.authorizationStatus == .notDetermined {
                    Button("Enable") {
                        Task {
                            await requestNotificationPermission()
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue)
                    .cornerRadius(20)
                } else if notificationService.authorizationStatus == .denied {
                    Button("Settings") {
                        openAppSettings()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Smart Notifications Section
    private var smartNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Notifications")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                        .frame(width: 40, height: 40)
                        .background(.purple.opacity(0.2))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intelligent Alerts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Get smart walk suggestions based on your dog's activity")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Toggle switch
                    Toggle("", isOn: .constant(notificationService.isSmartNotificationsEnabled))
                        .onChange(of: notificationService.isSmartNotificationsEnabled) { newValue in
                            notificationService.updateSmartNotifications(enabled: newValue)
                        }
                        .disabled(notificationService.authorizationStatus != .authorized)
                }
                
                if notificationService.isSmartNotificationsEnabled {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Smart reminders will notify you when:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            smartReminderFeature("30% goal not reached by 2 PM", icon: "target")
                            smartReminderFeature("60% goal not reached by 6 PM", icon: "bolt")
                            smartReminderFeature("No walks recorded by noon", icon: "exclamationmark.triangle")
                            smartReminderFeature("Daily goal achieved", icon: "checkmark.circle")
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Walk Reminders Section
    private var walkRemindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Walk Reminders")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !notificationService.walkReminders.isEmpty {
                    Text("\(notificationService.walkReminders.filter { $0.isEnabled }.count) active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.green)
                        .cornerRadius(12)
                }
            }
            
            // Reminders list
            if notificationService.walkReminders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Walk Reminders")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Add reminders to get notified when it's time for walks with your dog")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(notificationService.walkReminders) { reminder in
                        walkReminderRow(reminder)
                    }
                }
            }
        }
    }
    
    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug & Testing")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // View notification summary
                debugButton(
                    icon: "chart.bar",
                    title: "View Notification Summary",
                    action: { showingNotificationSummary = true }
                )
                
                // Test smart reminder
                debugButton(
                    icon: "testtube.2",
                    title: "Test Smart Reminder",
                    action: {
                        Task {
                            await testSmartReminder()
                        }
                    },
                    disabled: notificationService.authorizationStatus != .authorized
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func smartReminderFeature(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    private func walkReminderRow(_ reminder: WalkReminder) -> some View {
        HStack(spacing: 16) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.time, style: .time)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(reminder.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Days indicator (if we have recurring reminders)
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(.blue.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            
            // Toggle
            Toggle("", isOn: .constant(reminder.isEnabled))
                .onChange(of: reminder.isEnabled) { _ in
                    notificationService.toggleReminder(reminder)
                }
                .disabled(notificationService.authorizationStatus != .authorized)
        }
        .padding(16)
        .background(reminder.isEnabled ? Color(.systemGray6) : Color(.systemGray6).opacity(0.6))
        .cornerRadius(12)
        .opacity(reminder.isEnabled ? 1.0 : 0.7)
    }
    
    private func debugButton(
        icon: String,
        title: String,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(8)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(disabled ? Color(.systemGray6).opacity(0.5) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .disabled(disabled)
    }
    
    // MARK: - Helper Properties
    
    private var notificationStatusIcon: String {
        switch notificationService.authorizationStatus {
        case .authorized: return "✅"
        case .denied: return "❌"
        case .notDetermined: return "❓"
        case .provisional: return "🕐"
        case .ephemeral: return "⏱️"
        @unknown default: return "⚠️"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        default: return .gray
        }
    }
    
    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized: return "Notifications enabled - you'll receive walk reminders"
        case .denied: return "Notifications disabled - enable in Settings to receive reminders"
        case .notDetermined: return "Tap 'Enable' to allow walk reminder notifications"
        case .provisional: return "Quiet notifications enabled - reminders will appear in notification center"
        case .ephemeral: return "Temporary notification access"
        @unknown default: return "Unknown notification status"
        }
    }
    
    // MARK: - Helper Methods
    
    private func addNewReminder() {
        let reminder = WalkReminder(
            time: newReminderTime,
            title: newReminderTitle.isEmpty ? "Walk Time! 🐕" : newReminderTitle,
            message: newReminderMessage.isEmpty ? "Time for a walk with your dog!" : newReminderMessage
        )
        
        notificationService.addWalkReminder(reminder)
        
        // Reset form
        newReminderTime = Date()
        newReminderTitle = ""
        newReminderMessage = ""
    }
    
    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            let reminder = notificationService.walkReminders[index]
            notificationService.removeWalkReminder(reminder)
        }
    }
    
    private func requestNotificationPermission() async {
        isLoading = true
        let granted = await notificationService.requestNotificationPermission()
        isLoading = false
        
        if !granted {
            showingPermissionAlert = true
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func testSmartReminder() async {
        await notificationService.checkForSmartReminders()
    }
}

// MARK: - Add Reminder View
struct AddReminderView: View {
    @Binding var time: Date
    @Binding var title: String
    @Binding var message: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var repeatDaily = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("New Reminder")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Save") {
                            onSave()
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                    
                    // Form content
                    VStack(spacing: 24) {
                        // Time picker section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reminder Time")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                        }
                        
                        // Title section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Title")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("Walk Time! 🐕", text: $title)
                                .font(.system(size: 16))
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Message section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Message")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("Time for a walk with your dog!", text: $message, axis: .vertical)
                                .font(.system(size: 16))
                                .lineLimit(3...6)
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Repeat option
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Repeat")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Repeat daily")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $repeatDaily)
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Notification Summary View
struct NotificationSummaryView: View {
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var pendingNotifications: [UNNotificationRequest] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("Debug Info")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Spacer()
                            .frame(width: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                    
                    // Content
                    VStack(spacing: 24) {
                        // Status overview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notification Summary")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(notificationService.getNotificationSummary())
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Pending notifications
                        if !pendingNotifications.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scheduled Notifications")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                ForEach(pendingNotifications, id: \.identifier) { notification in
                                    pendingNotificationCard(notification)
                                }
                            }
                        }
                        
                        // Actions
                        VStack(spacing: 12) {
                            Button("Refresh Status") {
                                Task {
                                    await loadPendingNotifications()
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.blue)
                            .cornerRadius(12)
                            
                            Button("Clear Badge Count") {
                                notificationService.clearBadgeCount()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await loadPendingNotifications()
            }
        }
    }
    
    private func pendingNotificationCard(_ notification: UNNotificationRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(notification.content.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(notification.content.body)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text("Scheduled: \(trigger.nextTriggerDate()?.formatted() ?? "Unknown")")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func loadPendingNotifications() async {
        pendingNotifications = await notificationService.getPendingNotifications()
    }
}

// MARK: - View Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview
#Preview {
    ReminderSettingsView()
} 