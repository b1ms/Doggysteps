//
//  TodayView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Today View - Modern Fitness App UI
 
 Features:
 ✅ Clean modern design with large step counter
 ✅ Progress bar with milestone rewards
 ✅ Card-based metrics layout
 ✅ Distance and calories tracking
 ✅ Highlights section with achievements
 */

import SwiftUI

// MARK: - Today View
struct TodayView: View {
    
    // MARK: - Properties
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var showingReminderSettings = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header with time and notifications
                    topHeader
                    
                    // Distance and calories summary
                    summarySection
                    
                    // Large step counter
                    stepCounterSection
                    
                    // Progress bar with milestones
                    progressSection
                    
                    // Metrics section
                    metricsSection
                    
                    Spacer(minLength: 60) // Space for bottom navigation
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView()
        }
        .onAppear {
            print("📱 [TodayView] Today view appeared")
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack {
            // Streak indicator (moved from right)
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.orange.opacity(viewModel.currentStreak > 0 ? 0.15 : 0.05))
            .cornerRadius(16)
            .opacity(viewModel.currentStreak > 0 ? 1.0 : 0.6)
            
            Spacer()
            
            // Notification bell
            Button(action: { showingReminderSettings = true }) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
            
            // Profile button
            Button(action: { showingProfile = true }) {
                Circle()
                    .fill(.brown.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("🐕")
                            .font(.system(size: 16))
                    }
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        HStack {
            Text(formattedDistance)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("|")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(formattedCalories)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Share button
            Button(action: {}) {
                HStack(spacing: 6) {
                    Text("Share")
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Step Counter Section
    private var stepCounterSection: some View {
        VStack(spacing: 8) {
            // Large step count
            Text(formatStepCount(currentStepCount))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Steps label with info icon
            HStack(spacing: 4) {
                Text("steps")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress bar with milestones
            progressBar
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        let goalSteps = viewModel.todaysStepData?.goalSteps ?? 10000
        let actualProgress = Double(currentStepCount) / Double(goalSteps)
        let progress = min(actualProgress, 1.0)
        let percentage = Int(actualProgress * 100)
        
        return VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: actualProgress > 1.0 ? [.green, .mint] : [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                    
                    // Milestone markers
                    HStack {
                        let milestone1 = goalSteps / 4 // 25% of goal
                        let milestone2 = goalSteps / 2 // 50% of goal
                        
                        Spacer()
                            .frame(width: geometry.size.width * 0.25) // First milestone position
                        
                        Circle()
                            .fill(currentStepCount >= milestone1 ? .yellow : Color(.systemGray4))
                            .frame(width: 20, height: 20)
                            .overlay {
                                if currentStepCount >= milestone1 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        
                        Spacer()
                        
                        Circle()
                            .fill(currentStepCount >= milestone2 ? .orange : Color(.systemGray4))
                            .frame(width: 20, height: 20)
                            .overlay {
                                if currentStepCount >= milestone2 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                }
                            }
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 20)
            
            // Percentage display
            HStack {
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(actualProgress > 1.0 ? .green : .primary)
            }
            
            // Progress message
            VStack(spacing: 4) {
                let dogName = viewModel.dogProfile?.name ?? "Your dog"
                let pronoun = viewModel.dogProfile?.gender.pronoun ?? "they"
                let possessivePronoun = viewModel.dogProfile?.gender.possessivePronoun ?? "their"
                let remainingSteps = max(0, goalSteps - currentStepCount)
                
                if remainingSteps > 0 {
                    Text("\(dogName) needs \(formatStepCount(goalSteps)) paw steps a day, \(pronoun) needs \(formatStepCount(remainingSteps)) more!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                } else {
                    Text("🎉 \(dogName) crushed \(possessivePronoun) daily goal! Amazing work!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            .padding(.top, 8)
        }
    }
    

    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activity")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                // Distance metric
                metricCard(
                    icon: "🚀",
                    title: "Distance",
                    value: formattedDistance,
                    backgroundColor: .blue.opacity(0.1),
                    iconColor: .blue
                )
                
                // Active time metric
                metricCard(
                    icon: "⏰",
                    title: "Active Time",
                    value: formattedActiveTime,
                    backgroundColor: .green.opacity(0.1),
                    iconColor: .green
                )
                
                // Human steps metric
                metricCard(
                    icon: "🧘🏽‍♂️",
                    title: "Human Steps",
                    value: formattedHumanSteps,
                    backgroundColor: .orange.opacity(0.1),
                    iconColor: .orange
                )
                
                // Walk sessions metric
                metricCard(
                    icon: "🦮",
                    title: "Walk Sessions",
                    value: "\(todaysWalkCount)",
                    backgroundColor: .purple.opacity(0.1),
                    iconColor: .purple
                )
            }
        }
    }
    
    // MARK: - Metric Card
    private func metricCard(
        icon: String,
        title: String,
        value: String,
        backgroundColor: Color,
        iconColor: Color
    ) -> some View {
        VStack(spacing: 16) {
            // Icon (emoji or SF Symbol)
            if icon.hasPrefix("sf:") {
                // SF Symbol
                Image(systemName: String(icon.dropFirst(3)))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.2))
                    .cornerRadius(12)
            } else {
                // Emoji
                Text(icon)
                    .font(.system(size: 32))
                    .frame(height: 40)
            }
            
            // Value and title
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Properties
    
    private var currentStepCount: Int {
        return viewModel.todaysStepData?.estimatedDogSteps ?? 0
    }
    
    private var formattedDistance: String {
        guard let stepData = viewModel.todaysStepData else { return "0.0 mi" }
        let miles = stepData.distanceInKilometers * 0.621371
        return String(format: "%.1f mi", miles)
    }
    
    private var formattedCalories: String {
        guard let stepData = viewModel.todaysStepData else { return "0 kcal" }
        // Rough calorie estimation: ~0.04 calories per step for dogs
        let calories = Int(Double(stepData.estimatedDogSteps) * 0.04)
        return "\(calories) kcal"
    }
    
    private var formattedActiveTime: String {
        guard let stepData = viewModel.todaysStepData else { return "0 min" }
        // Estimate active time based on steps (rough calculation)
        let minutes = stepData.estimatedDogSteps / 100 // ~100 steps per minute
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(remainingMinutes) min"
    }
    
    private var formattedHumanSteps: String {
        guard let stepData = viewModel.todaysStepData else { return "0" }
        return formatStepCount(stepData.humanSteps)
    }
    
    private var todaysWalkCount: Int {
        return viewModel.todaysWalkSessions.count
    }
    
    // MARK: - Helper Methods
    
    private func formatStepCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}

// MARK: - Settings View Placeholder
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var showingProfile = false
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationView {
            List {
                Section("App Settings") {
                    Button(action: {
                        showingNotifications = true
                    }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundStyle(.blue)
                            Text("Notifications")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundStyle(.green)
                            Text("Profile")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Help & Support") {
                    Button(action: {
                        // Open app settings
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundStyle(.orange)
                            Text("App Settings")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Open HealthKit permissions
                        if let settingsUrl = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("HealthKit Permissions")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(homeViewModel)
        }
        .sheet(isPresented: $showingNotifications) {
            ReminderSettingsView()
        }
    }
}

// MARK: - Preview
struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
            .environmentObject(HomeViewModel())
    }
} 