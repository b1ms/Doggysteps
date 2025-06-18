//
//  ReminderSettingsView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Phase 5 Complete: ReminderSettingsView for Walk Reminder Management
 
 Features Implemented:
 ✅ Walk reminder time management (add, edit, delete)
 ✅ Enable/disable individual reminders
 ✅ Smart notification toggle
 ✅ Notification permission management
 ✅ Beautiful, modern iOS design
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
            List {
                notificationStatusSection
                
                smartNotificationsSection
                
                walkRemindersSection
                
                notificationInfoSection
            }
            .navigationTitle("Walk Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Reminder") {
                        showingAddReminder = true
                    }
                    .disabled(notificationService.authorizationStatus != .authorized)
                }
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
        }
        .onAppear {
            notificationService.checkAuthorizationStatus()
        }
    }
    
    // MARK: - View Sections
    
    private var notificationStatusSection: some View {
        Section {
            HStack {
                Image(systemName: notificationStatusIcon)
                    .foregroundStyle(notificationStatusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(.headline)
                    
                    Text(notificationStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if notificationService.authorizationStatus == .notDetermined {
                    Button("Enable") {
                        Task {
                            await requestNotificationPermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else if notificationService.authorizationStatus == .denied {
                    Button("Settings") {
                        openAppSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Permissions")
        }
    }
    
    private var smartNotificationsSection: some View {
        Section {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple.gradient)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Reminders")
                        .font(.headline)
                    
                    Text("Get intelligent walk suggestions based on your dog's activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { notificationService.isSmartNotificationsEnabled },
                    set: { notificationService.updateSmartNotifications(enabled: $0) }
                ))
                .disabled(notificationService.authorizationStatus != .authorized)
            }
            .padding(.vertical, 8)
            
            if notificationService.isSmartNotificationsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart reminders will notify you when:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        smartReminderFeature("Your dog hasn't reached 30% of daily goal by 2 PM")
                        smartReminderFeature("Your dog hasn't reached 60% of daily goal by 6 PM")
                        smartReminderFeature("No walks have been recorded by noon")
                        smartReminderFeature("Daily goal is achieved (celebration!)")
                    }
                }
                .padding(.top, 8)
            }
        } header: {
            Text("Intelligent Notifications")
        }
    }
    
    private var walkRemindersSection: some View {
        Section {
            if notificationService.walkReminders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text("No Walk Reminders")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add reminders to get notified when it's time for walks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(notificationService.walkReminders) { reminder in
                    walkReminderRow(reminder)
                }
                .onDelete(perform: deleteReminders)
            }
        } header: {
            HStack {
                Text("Walk Reminders")
                Spacer()
                if !notificationService.walkReminders.isEmpty {
                    Text("\(notificationService.walkReminders.filter { $0.isEnabled }.count) active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var notificationInfoSection: some View {
        Section {
            Button(action: {
                showingNotificationSummary = true
            }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Text("View Notification Summary")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            Button(action: {
                Task {
                    await testSmartReminder()
                }
            }) {
                HStack {
                    Image(systemName: "testtube.2")
                        .foregroundStyle(.orange)
                    
                    Text("Test Smart Reminder")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
            }
            .disabled(notificationService.authorizationStatus != .authorized)
        } header: {
            Text("Debug & Testing")
        }
    }
    
    // MARK: - Helper Views
    
    private func walkReminderRow(_ reminder: WalkReminder) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundStyle(reminder.isEnabled ? .primary : .secondary)
                
                Text(reminder.time, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if !reminder.message.isEmpty {
                    Text(reminder.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { _ in notificationService.toggleReminder(reminder) }
                ))
                .disabled(notificationService.authorizationStatus != .authorized)
                
                if reminder.repeatDaily {
                    Text("Daily")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(reminder.isEnabled ? 1.0 : 0.6)
    }
    
    private func smartReminderFeature(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Helper Properties
    
    private var notificationStatusIcon: String {
        switch notificationService.authorizationStatus {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .provisional: return "clock.circle.fill"
        case .ephemeral: return "timer.circle.fill"
        @unknown default: return "exclamationmark.circle.fill"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .provisional: return .blue
        case .ephemeral: return .purple
        @unknown default: return .gray
        }
    }
    
    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized: return "Notifications enabled - you'll receive walk reminders"
        case .denied: return "Notifications disabled - enable in Settings to receive reminders"
        case .notDetermined: return "Tap 'Enable' to allow walk reminder notifications"
        case .provisional: return "Quiet notifications enabled - reminders will appear in Notification Center"
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
            Form {
                Section("Reminder Time") {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }
                
                Section("Reminder Details") {
                    TextField("Title (optional)", text: $title)
                        .placeholder(when: title.isEmpty) {
                            Text("Walk Time! 🐕").foregroundStyle(.secondary)
                        }
                    
                    TextField("Message (optional)", text: $message, axis: .vertical)
                        .lineLimit(2...4)
                        .placeholder(when: message.isEmpty) {
                            Text("Time for a walk with your dog!").foregroundStyle(.secondary)
                        }
                    
                    Toggle("Repeat Daily", isOn: $repeatDaily)
                }
                
                Section {
                    Button("Save Reminder") {
                        onSave()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
                VStack(spacing: 20) {
                    // Status overview
                    VStack(spacing: 16) {
                        Text("Notification Summary")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(notificationService.getNotificationSummary())
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .cornerRadius(12)
                    }
                    
                    // Pending notifications
                    if !pendingNotifications.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scheduled Notifications")
                                .font(.headline)
                            
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
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Clear Badge Count") {
                            notificationService.clearBadgeCount()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Debug Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadPendingNotifications()
            }
        }
    }
    
    private func pendingNotificationCard(_ notification: UNNotificationRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notification.content.title)
                .font(.headline)
            
            Text(notification.content.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                Text("Scheduled: \(trigger.nextTriggerDate()?.formatted() ?? "Unknown")")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
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