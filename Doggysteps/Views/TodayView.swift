//
//  TodayView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Today View - Minimalist Black & White Dashboard
 
 Features:
 ✅ Large step count display with clean typography
 ✅ Minimalist progress circle in monochrome
 ✅ Settings button in top-left corner
 ✅ Clean white background with subtle shadows
 ✅ Activity summary cards in black and white
 ✅ Goal tracking with minimal styling
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
                    if let stepData = viewModel.todaysStepData {
                        // Has walk data - show normal dashboard
                        dashboardWithData(stepData)
                    } else {
                        // No walks today - show prompt to start walking
                        noWalksPromptSection
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                // Settings button in top-left corner
                settingsButton
                    .padding(.top, 60)
                    .padding(.leading, 20)
            }
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
    
    // MARK: - View Components
    
    // MARK: - Dashboard with Data
    private func dashboardWithData(_ stepData: StepData) -> some View {
        VStack(spacing: 40) {
            // Large step count
            stepCountSection(for: stepData)
            
            // Activity metrics
            activityMetricsSection(for: stepData)
            
            // Goal section
            goalSection(for: stepData)
        }
    }
    
    private func stepCountSection(for stepData: StepData) -> some View {
        VStack(spacing: 30) {
            Spacer()
                .frame(height: 40)
            
            // Step counter text
            if let profile = viewModel.dogProfile {
                Text("\(profile.name) has done \(formatLargeNumber(stepData.estimatedDogSteps)) steps")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            
            // Minimalist progress circle
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 2)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: min(max(stepData.goalProgress, 0), 1))
                    .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: stepData.goalProgress)
                
                VStack(spacing: 4) {
                    Text("\(stepData.goalProgressPercentage)%")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("of goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                }
            }
        }
    }
    
    private func activityMetricsSection(for stepData: StepData) -> some View {
        VStack(spacing: 20) {
            // Activity metrics
            HStack(spacing: 20) {
                activityMetric(
                    title: "Distance",
                    value: String(format: "%.1f mi", stepData.distanceInKilometers * 0.621371),
                    icon: "location"
                )
                
                activityMetric(
                    title: "Active Time",
                    value: formattedActiveTime,
                    icon: "clock"
                )
                
                activityMetric(
                    title: "Walks",
                    value: "\(todaysWalkCount)",
                    icon: "figure.walk"
                )
            }
        }
    }
    
    private func goalSection(for stepData: StepData) -> some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(spacing: 8) {
                Text("\(viewModel.dogProfile?.name.uppercased() ?? "YOUR DOG") NEEDS \(formatLargeNumber(stepData.goalSteps)) A DAY")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
                
                Text("steps")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - No Walks Prompt Section
    private var noWalksPromptSection: some View {
        VStack(spacing: 40) {
            Spacer()
                .frame(height: 60)
            
            // Progress circle showing empty (without large step counter)
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 2)
                    .frame(width: 180, height: 180)
                
                VStack(spacing: 4) {
                    Text("0%")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("of goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Personalized message with dog's name and step goal
            VStack(spacing: 16) {
                if let profile = viewModel.dogProfile {
                    let dailyGoal = StepEstimationService.shared.calculateDailyGoal(
                        for: profile.breedName,
                        bodyCondition: profile.bodyCondition
                    )
                    
                    Text("\(profile.name) has done 0 steps")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("\(profile.gender.pronoun.capitalized) needs \(formatLargeNumber(dailyGoal)) steps today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No walks recorded today")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Start a dog walk to begin tracking steps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Activity metrics (showing zeros)
            noWalksActivityMetricsSection
            
            // Call to action
            VStack(spacing: 12) {
                Text("Dog steps are only calculated during active walk sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Tap the 'Start Dog Walk' tab to begin")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.primary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Spacer()
        }
    }
    
    private var noWalksActivityMetricsSection: some View {
        VStack(spacing: 20) {
            // Activity metrics showing zeros
            HStack(spacing: 20) {
                activityMetric(
                    title: "Distance",
                    value: "0.0 mi",
                    icon: "location"
                )
                
                activityMetric(
                    title: "Active Time",
                    value: "0h 0m",
                    icon: "clock"
                )
                
                activityMetric(
                    title: "Walks",
                    value: "0",
                    icon: "figure.walk"
                )
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundStyle(.primary)
                .background(
                    Circle()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 44, height: 44)
                )
        }
    }
    
    private func activityMetric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
    
    // MARK: - Helper Properties
    
    private var formattedStepCount: String {
        guard let stepData = viewModel.todaysStepData else { return "0" }
        return formatLargeNumber(stepData.estimatedDogSteps)
    }
    
    private var formattedGoalSteps: String {
        guard let stepData = viewModel.todaysStepData else { return "10,000" }
        return formatLargeNumber(stepData.goalSteps)
    }
    
    private var formattedDistance: String {
        guard let stepData = viewModel.todaysStepData else { return "0.0 mi" }
        let miles = stepData.distanceInKilometers * 0.621371
        return String(format: "%.2f mi", miles)
    }
    
    private var formattedActiveTime: String {
        guard let stepData = viewModel.todaysStepData else { return "0h 0m" }
        // Estimate active time based on steps (rough calculation)
        let minutes = stepData.estimatedDogSteps / 100 // ~100 steps per minute
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
    
    private var todaysWalkCount: Int {
        return viewModel.todaysWalkSessions.count
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d MMM"
        return formatter.string(from: Date())
    }
    
    // MARK: - Helper Methods
    
    private func formatLargeNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1f", thousands).replacingOccurrences(of: ".0", with: "") + "k"
        } else {
            return "\(number)"
        }
    }
    
    private func dayOfWeek(offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
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
#Preview {
    TodayView()
        .environmentObject(HomeViewModel())
} 