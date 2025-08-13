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
    @State private var showingStepCalculationInfo = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header
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
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingStepCalculationInfo) {
            StepCalculationInfoView()
                .environmentObject(viewModel)
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
        ZStack {
            // PAWSTEPS title - perfectly centered
            Text("PAWSTEPS")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.black)
            
            // Left and right elements overlay
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
                
                            // Notification bell button
            Button(action: { 
                HapticService.shared.selection()
                showingReminderSettings = true 
            }) {
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("🔔")
                                .font(.system(size: 16))
                        }
                }
                
                            // Profile button
            Button(action: { 
                HapticService.shared.selection()
                showingProfile = true 
            }) {
                    Circle()
                        .fill(.brown.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("🐶")
                                .font(.system(size: 16))
                        }
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
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            
            // Steps label with info icon
            HStack(spacing: 4) {
                Text("steps")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                
                Button(action: {
                    HapticService.shared.selection()
                    showingStepCalculationInfo = true
                }) {
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
            // Percentage display (moved to top)
            HStack {
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(actualProgress > 1.0 ? .green : .primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track (made wider)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                    
                    // Progress fill (made wider)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: actualProgress > 1.0 ? [.green, .mint] : [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 20)
                }
            }
            .frame(height: 20)
            
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
        return "\(count)"
    }
}

// MARK: - Step Calculation Info View
struct StepCalculationInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🐾 How Paw Steps Are Calculated")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("We use breed-specific science to convert your steps into your dog's paw steps")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    // Current Dog Info
                    if let dogProfile = viewModel.dogProfile {
                        currentDogInfoCard(dogProfile)
                    }
                    
                    // How It Works Section
                    howItWorksSection
                    
                    // Breed Multiplier Examples
                    breedMultiplierExamples
                    
                    // Factors That Affect Calculation
                    calculationFactors
                    
                    // Accuracy & Confidence
                    accuracySection
                    
                    Spacer(minLength: 32)
                }
                .padding(20)
            }
            .navigationTitle("Step Calculation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticService.shared.selection()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Current Dog Info Card
    private func currentDogInfoCard(_ dogProfile: DogProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Dog's Calculation")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                infoRow(label: "Dog", value: dogProfile.name)
                infoRow(label: "Breed", value: dogProfile.breedName)
                
                if let breedInfo = BreedService.shared.getBreedByName(dogProfile.breedName) {
                    infoRow(label: "Step Multiplier", value: "\(String(format: "%.1f", breedInfo.stepMultiplier))x")
                    infoRow(label: "Breed Size", value: breedInfo.size)
                    infoRow(label: "Energy Level", value: breedInfo.energyLevel)
                    
                    HStack {
                        Text("Example:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1,000 your steps = \(Int(1000 * breedInfo.stepMultiplier)) paw steps")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - How It Works Section
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                stepExplanation(
                    step: "1",
                    title: "Track Your Steps",
                    description: "We track your steps using your phone's motion sensors during walks"
                )
                
                stepExplanation(
                    step: "2",
                    title: "Apply Breed Multiplier",
                    description: "Your steps are multiplied by your dog's breed-specific multiplier"
                )
                
                stepExplanation(
                    step: "3",
                    title: "Calculate Paw Steps",
                    description: "The result is your dog's estimated paw steps based on their size and pace"
                )
            }
        }
    }
    
    // MARK: - Breed Multiplier Examples
    private var breedMultiplierExamples: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breed Multiplier Examples")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Different breeds have different step patterns based on their size and stride length:")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                breedExample(breed: "Chihuahua", multiplier: 4.0, size: "Tiny legs, many steps")
                breedExample(breed: "Great Dane", multiplier: 0.9, size: "Long legs, fewer steps")
                breedExample(breed: "Labrador Retriever", multiplier: 1.4, size: "Medium-large, moderate pace")
                breedExample(breed: "French Bulldog", multiplier: 2.0, size: "Short legs, quick steps")
            }
        }
    }
    
    // MARK: - Calculation Factors
    private var calculationFactors: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Factors That Affect Calculation")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                factor(icon: "📏", title: "Dog Size", description: "Smaller dogs take more steps to cover the same distance")
                factor(icon: "🦴", title: "Leg Length", description: "Stride length affects step count")
                factor(icon: "⚡", title: "Energy Level", description: "Some breeds naturally move more quickly")
                factor(icon: "🏃", title: "Walking Pace", description: "Your walking speed influences your dog's movement")
            }
        }
    }
    
    // MARK: - Accuracy Section
    private var accuracySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accuracy & Confidence")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("✅")
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("High Confidence")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                        Text("Well-known breed with typical activity levels")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("⚠️")
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Medium Confidence")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                        Text("Estimated based on breed characteristics")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("❓")
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Low Confidence")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                        Text("Mixed breed or unusual activity patterns")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("💡 Remember: These are estimates to help you track your dog's activity. Every dog is unique!")
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Views
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
        }
    }
    
    private func stepExplanation(step: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func breedExample(breed: String, multiplier: Double, size: String) -> some View {
        HStack {
            Text(breed)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            Text("\(String(format: "%.1f", multiplier))x")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.blue)
            Text("•")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(size)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private func factor(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Settings View Placeholder
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var showingProfile = false

    
    var body: some View {
        NavigationView {
            List {
                Section("App Settings") {

                    
                    Button(action: {
                        HapticService.shared.selection()
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
                        HapticService.shared.selection()
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
                        HapticService.shared.selection()
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
                        HapticService.shared.selection()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(homeViewModel)
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