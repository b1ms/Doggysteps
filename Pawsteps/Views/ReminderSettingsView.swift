//
//  ReminderSettingsView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI
import UserNotifications

// MARK: - Reminder Data Model
struct WalkReminder: Identifiable, Codable {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var title: String
    var repeatDays: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    
    init(time: Date = Date(), isEnabled: Bool = true, title: String = "Walk Time", repeatDays: Set<Int> = Set(1...7)) {
        self.id = UUID()
        self.time = time
        self.isEnabled = isEnabled
        self.title = title
        self.repeatDays = repeatDays
    }
}

// MARK: - Reminder Settings View
struct ReminderSettingsView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var notificationsEnabled = false
    @State private var reminders: [WalkReminder] = []

    @State private var showingAddReminder = false
    @State private var editingReminder: WalkReminder?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Description section
                    descriptionSection
                    
                    // Notification toggle section (only show if not enabled)
                    if !notificationsEnabled {
                        notificationToggleSection
                    }
                    
                    // Reminders section
                    if notificationsEnabled {
                        remindersSection
                    }
                    
                    // Add reminder button
                    if notificationsEnabled {
                        addReminderButton
                    }
                    
                    // Info section
                    infoSection
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Walk Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticService.shared.selection()
                        saveReminders()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView { reminder in
                    reminders.append(reminder)
                    scheduleNotification(for: reminder)
                }
            }
            .sheet(item: $editingReminder) { reminder in
                EditReminderView(reminder: reminder) { updatedReminder in
                    if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                        reminders[index] = updatedReminder
                        scheduleNotification(for: updatedReminder)
                    }
                }
            }

        }
        .onAppear {
            loadReminders()
            checkNotificationPermission()
        }
    }
    

    
    // MARK: - Description Section
    private var descriptionSection: some View {
        Text("Set up custom reminders to help you maintain your dog's daily walk routine.")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 16)
    }
    
    // MARK: - Notification Toggle Section
    private var notificationToggleSection: some View {
        VStack(spacing: 16) {
            // Settings button card
            Button {
                HapticService.shared.selection()
                openAppSettings()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Notifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Go to Settings to allow walk reminders")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(20)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Reminders Section
    private var remindersSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Your Reminders")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !reminders.isEmpty {
                    Text("\(reminders.count) reminder\(reminders.count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Reminders grid or empty state
            if reminders.isEmpty {
                emptyRemindersCard
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(reminders) { reminder in
                        reminderCard(reminder)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty Reminders Card
    private var emptyRemindersCard: some View {
        VStack(spacing: 16) {
            Text("📅")
                .font(.system(size: 40))
            
            VStack(spacing: 8) {
                Text("No reminders set")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Tap the + button below to add your first reminder")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Reminder Card
    private func reminderCard(_ reminder: WalkReminder) -> some View {
        Button {
            HapticService.shared.selection()
            editingReminder = reminder
        } label: {
            VStack(spacing: 12) {
                // Status indicator
                HStack {
                    Circle()
                        .fill(reminder.isEnabled ? .green : .gray)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                    
                    Button {
                        HapticService.shared.selection()
                        deleteReminder(reminder)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
                
                // Time display
                Text(reminder.time, style: .time)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                
                // Title and days
                VStack(spacing: 4) {
                    Text(reminder.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(selectedDaysText(for: reminder))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(reminderCardBackground(for: reminder))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Add Reminder Button
    private var addReminderButton: some View {
        Button {
            HapticService.shared.selection()
            showingAddReminder = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("Add New Reminder")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("How it Works")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Info cards
            VStack(spacing: 12) {
                infoCard(
                    icon: "⏰",
                    title: "Custom Schedule",
                    description: "Set specific times and days for each reminder",
                    backgroundColor: .orange.opacity(0.1),
                    iconColor: .orange
                )
                
                infoCard(
                    icon: "🔄",
                    title: "Flexible Repeating",
                    description: "Choose daily, weekdays, weekends, or custom days",
                    backgroundColor: .green.opacity(0.1),
                    iconColor: .green
                )
                
                infoCard(
                    icon: "🎯",
                    title: "Multiple Reminders",
                    description: "Add as many reminders as you need for your routine",
                    backgroundColor: .purple.opacity(0.1),
                    iconColor: .purple
                )
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Info Card
    private func infoCard(
        icon: String,
        title: String,
        description: String,
        backgroundColor: Color,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.2))
                .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    private func selectedDaysText(for reminder: WalkReminder) -> String {
        if reminder.repeatDays.count == 7 {
            return "Every day"
        } else if reminder.repeatDays.count == 5 && reminder.repeatDays.isSubset(of: Set(2...6)) {
            return "Weekdays"
        } else if reminder.repeatDays.count == 2 && reminder.repeatDays.isSubset(of: Set([1, 7])) {
            return "Weekends"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            let dayAbbreviations = formatter.shortWeekdaySymbols
            let days = reminder.repeatDays.sorted().map { dayAbbreviations?[$0 - 1] ?? "" }
            return days.joined(separator: ", ")
        }
    }
    
    private func reminderCardBackground(for reminder: WalkReminder) -> Color {
        if reminder.isEnabled {
            return .green.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    

    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func scheduleNotification(for reminder: WalkReminder) {
        guard notificationsEnabled && reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = "It's time for your dog's walk! 🐕"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
        
        // Schedule for each selected day
        for day in reminder.repeatDays {
            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(reminder.id.uuidString)-\(day)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    private func scheduleAllNotifications() {
        cancelAllNotifications()
        for reminder in reminders {
            scheduleNotification(for: reminder)
        }
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func deleteReminder(_ reminder: WalkReminder) {
        withAnimation(.easeInOut) {
            reminders.removeAll { $0.id == reminder.id }
        }
        
        // Cancel notifications for this reminder
        let identifiers = reminder.repeatDays.map { "\(reminder.id.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    private func saveReminders() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: "walkReminders")
        }
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
    }
    
    private func loadReminders() {
        if let savedReminders = UserDefaults.standard.data(forKey: "walkReminders") {
            let decoder = JSONDecoder()
            if let loadedReminders = try? decoder.decode([WalkReminder].self, from: savedReminders) {
                reminders = loadedReminders
            }
        }
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
}

// MARK: - Add Reminder View
struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (WalkReminder) -> Void
    
    @State private var title = "Walk Time"
    @State private var time = Date()
    @State private var isEnabled = true
    @State private var repeatDays: Set<Int> = Set(1...7)
    
    var body: some View {
        ReminderFormView(
            title: $title,
            time: $time,
            isEnabled: $isEnabled,
            repeatDays: $repeatDays,
            navigationTitle: "Add Reminder"
        ) {
            let reminder = WalkReminder(
                time: time,
                isEnabled: isEnabled,
                title: title,
                repeatDays: repeatDays
            )
            onAdd(reminder)
            dismiss()
        }
    }
}

// MARK: - Edit Reminder View
struct EditReminderView: View {
    @Environment(\.dismiss) private var dismiss
    let reminder: WalkReminder
    let onUpdate: (WalkReminder) -> Void
    
    @State private var title: String
    @State private var time: Date
    @State private var isEnabled: Bool
    @State private var repeatDays: Set<Int>
    
    init(reminder: WalkReminder, onUpdate: @escaping (WalkReminder) -> Void) {
        self.reminder = reminder
        self.onUpdate = onUpdate
        self._title = State(initialValue: reminder.title)
        self._time = State(initialValue: reminder.time)
        self._isEnabled = State(initialValue: reminder.isEnabled)
        self._repeatDays = State(initialValue: reminder.repeatDays)
    }
    
    var body: some View {
        ReminderFormView(
            title: $title,
            time: $time,
            isEnabled: $isEnabled,
            repeatDays: $repeatDays,
            navigationTitle: "Edit Reminder"
        ) {
            var updatedReminder = reminder
            updatedReminder.title = title
            updatedReminder.time = time
            updatedReminder.isEnabled = isEnabled
            updatedReminder.repeatDays = repeatDays
            onUpdate(updatedReminder)
            dismiss()
        }
    }
}

// MARK: - Reminder Form View
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var title: String
    @Binding var time: Date
    @Binding var isEnabled: Bool
    @Binding var repeatDays: Set<Int>
    let navigationTitle: String
    let onSave: () -> Void
    
    private let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    private let presetOptions = [
        ("Every day", Set(1...7)),
        ("Weekdays", Set(2...6)),
        ("Weekends", Set([1, 7]))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Form cards
                    VStack(spacing: 16) {
                        // Title card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminder Title")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            TextField("Enter reminder title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                        }
                        .padding(20)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Time card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            DatePicker("Select time", selection: $time, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                        }
                        .padding(20)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Enabled toggle card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Reminder")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Turn this reminder on or off")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                            }
                        }
                        .padding(20)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Repeat days card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Repeat Days")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            // Preset options
                            VStack(spacing: 8) {
                                ForEach(0..<presetOptions.count, id: \.self) { index in
                                    let (optionName, optionDays) = presetOptions[index]
                                    Button {
                                        HapticService.shared.selection()
                                        repeatDays = optionDays
                                    } label: {
                                        HStack {
                                            Text(optionName)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if repeatDays == optionDays {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(repeatDays == optionDays ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            Text("or select custom days:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            
                            // Individual day toggles
                            VStack(spacing: 8) {
                                ForEach(0..<7, id: \.self) { index in
                                    let dayNumber = index + 1
                                    Toggle(dayNames[index], isOn: Binding(
                                        get: { repeatDays.contains(dayNumber) },
                                        set: { enabled in
                                            if enabled {
                                                repeatDays.insert(dayNumber)
                                            } else {
                                                repeatDays.remove(dayNumber)
                                            }
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticService.shared.selection()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticService.shared.selection()
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || repeatDays.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview
struct ReminderSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderSettingsView()
            .environmentObject(HomeViewModel())
    }
} 