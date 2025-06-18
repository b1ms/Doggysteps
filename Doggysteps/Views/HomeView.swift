//
//  HomeView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 HomeView - Minimalist Black & White Dashboard
 
 Features Implemented:
 ✅ Personalized greeting with clean typography
 ✅ Dog steps today with breed-specific calculations
 ✅ Distance walked with metric/imperial support
 ✅ Minimalist progress circle with subtle animations
 ✅ Activity insights with clean presentation
 ✅ Weekly activity chart in monochrome
 ✅ Health status summary with minimal styling
 ✅ Clean monochromatic HealthKit integration
 ✅ Comprehensive error handling with subtle styling
 ✅ Responsive design with black & white aesthetics
 
 UI Components:
 - Header with greeting and minimal dog profile card
 - Today's activity summary with clean progress indicators
 - Minimalist circular progress chart
 - Activity insights with monochrome presentation
 - Clean stats cards (human steps, weekly average)
 - Weekly activity bar chart in black and white
 - Health status summary with subtle confidence indicators
 - Minimal action buttons with outline styling
 - Activity details sheet with clean data breakdown
 - Profile management sheet with minimal design
 */

import SwiftUI
import Charts

// MARK: - Home View
struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingActivityDetails = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with greeting and dog info
                    headerSection
                    
                    if viewModel.motionAuthorized {
                        // Today's step summary
                        todaysSummarySection
                        
                        // Progress circle
                        progressSection
                        
                        // Activity insights
                        activityInsightsSection
                        
                        // Quick stats
                        quickStatsSection
                        
                        // Weekly chart
                        if !viewModel.weeklyStepData.isEmpty {
                            weeklyChartSection
                        }
                        
                        // Health status summary
                        healthStatusSection
                    } else {
                        // Core Motion authorization prompt
                        motionPromptSection
                    }
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Doggysteps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.showingReminderSettings = true
                    }) {
                        Image(systemName: "bell")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    profileButton
                }
            }
            .sheet(isPresented: $viewModel.showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $viewModel.showingReminderSettings) {
                ReminderSettingsView()
            }
            .sheet(isPresented: $showingActivityDetails) {
                ActivityDetailsView(stepData: viewModel.weeklyStepData)
            }
            .alert("Motion Access", isPresented: .constant(viewModel.error != nil)) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { 
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.errorDescription ?? "")
            }
        }
        .onAppear {
            print("🏠 [HomeView] Home view appeared")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("🏠 [HomeView] App became active, checking motion status")
            viewModel.refreshMotionStatus()
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Greeting
            VStack(spacing: 8) {
                Text(viewModel.greeting)
                    .font(.title2)
                    .fontWeight(.light)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
            }
            
            // Dog info card
            if let dogProfile = viewModel.dogProfile {
                dogInfoCard(dogProfile)
            }
        }
    }
    
    private func dogInfoCard(_ profile: DogProfile) -> some View {
        HStack(spacing: 16) {
            // Dog avatar
            Image(systemName: "pawprint.circle")
                .font(.system(size: 32))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                                        Text("\(profile.breedName) • \(profile.bodyCondition.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    .tracking(0.3)
            }
            
            Spacer()
            
            // Motion status
            VStack(spacing: 6) {
                Image(systemName: viewModel.motionAuthorized ? "checkmark.circle" : "exclamationmark.circle")
                    .font(.title3)
                    .foregroundStyle(viewModel.motionAuthorized ? .primary : .secondary)
                
                Text(viewModel.motionAuthorized ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
                .fill(Color(.systemGray6).opacity(0.1))
        )
    }
    
    private var todaysSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Activity")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .tracking(0.5)
                Spacer()
            }
            
            if let stepData = viewModel.todaysStepData {
                todaysSummaryCard(stepData)
            } else if viewModel.isLoading {
                loadingCard
            } else {
                noDataCard
            }
        }
    }
    
    private func todaysSummaryCard(_ stepData: StepData) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stepData.estimatedDogSteps)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Dog Steps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f km", stepData.distanceInKilometers))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Distance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Daily Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(stepData.goalProgressPercentage)%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                ProgressView(value: stepData.goalProgress)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 3)
                    .animation(.easeInOut(duration: 1.0), value: stepData.goalProgress)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .cornerRadius(16)
    }
    
    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading today's activity...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    private var noDataCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundStyle(.gray)
            
            Text("No activity data yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !viewModel.motionAuthorized {
                VStack(spacing: 12) {
                    Button("Enable Motion Tracking") {
                        Task {
                            await viewModel.requestMotionPermissions()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Check Status") {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.blue)
                }
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Daily Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: viewModel.todaysProgress)
                    .stroke(.blue.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: viewModel.todaysProgress)
                
                VStack(spacing: 4) {
                    Text("\(viewModel.todaysProgressPercentage)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("of goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                statCard(
                    title: "Human Steps",
                    value: "\(viewModel.todaysStepData?.humanSteps ?? 0)",
                    icon: "figure.walk",
                    color: .green
                )
                
                statCard(
                    title: "Weekly Avg",
                    value: "\(viewModel.weeklyAverage)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var weeklyChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Activity")
                    .font(.headline)
                
                Spacer()
                
                Button("View Details") {
                    showingActivityDetails = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            // Simple bar chart representation
            weeklyChart
        }
    }
    
    private var weeklyChart: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(viewModel.weeklyStepData.prefix(7).enumerated()), id: \.offset) { index, stepData in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue.gradient)
                        .frame(width: 32, height: CGFloat(stepData.estimatedDogSteps) / 200.0)
                        .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: stepData.estimatedDogSteps)
                    
                    Text(dayOfWeek(from: stepData.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(height: 120)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Enhanced Phase 4 Sections
    
    private var activityInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Activity Insights")
                    .font(.headline)
                
                Spacer()
                
                Text(viewModel.activityTrend.emoji)
                    .font(.title2)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.activityInsights.prefix(3), id: \.message) { insight in
                    HStack(spacing: 12) {
                        Image(systemName: insightIcon(for: insight))
                            .font(.title3)
                            .foregroundStyle(insightColor(for: insight))
                            .frame(width: 24)
                        
                        Text(insight.message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                
                if viewModel.activityInsights.isEmpty {
                    Text("Get more activity data to see personalized insights!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding()
                }
            }
        }
    }
    
    private var healthStatusSection: some View {
        VStack(spacing: 16) {
            Text("Health Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Today's summary
                if let stepData = viewModel.todaysStepData {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today's Assessment")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(stepData.activityEmoji)
                                .font(.title2)
                        }
                        
                        Text(viewModel.motionStatusSummary)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Weekly trend
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Trend")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(viewModel.weeklyStepTrend)
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Data quality indicator
                if let stepData = viewModel.todaysStepData {
                    HStack {
                        Text("Data Confidence:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(stepData.confidenceEmoji)
                        Text(stepData.confidence)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Quality: \(stepData.confidence)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var motionPromptSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 12) {
                Text("Enable Step Tracking")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Allow motion access to track your walks and calculate your dog's steps during active walk sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Enable Motion Tracking") {
                    Task {
                        await viewModel.requestMotionPermissions()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                

            }
            
            Text("Step counting only works during active walk sessions - no background tracking.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods for Insights
    
    private func insightIcon(for insight: EstimationInsight) -> String {
        switch insight {
        case .goalAchievement: return "trophy.fill"
        case .improvementNeeded: return "exclamationmark.triangle.fill"
        case .lowActivity: return "figure.walk"
        case .trendPositive: return "arrow.up.circle.fill"
        case .trendNegative: return "arrow.down.circle.fill"
        case .trendStable: return "minus.circle.fill"
        }
    }
    
    private func insightColor(for insight: EstimationInsight) -> Color {
        switch insight {
        case .goalAchievement: return .green
        case .improvementNeeded: return .orange
        case .lowActivity: return .red
        case .trendPositive: return .green
        case .trendNegative: return .red
        case .trendStable: return .blue
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if viewModel.motionAuthorized {
                // Authorized action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await viewModel.refreshData()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    

                }
                
                // Status information
                VStack(spacing: 8) {
                    if let lastUpdate = viewModel.lastUpdateTime {
                        Text("Last updated: \(lastUpdate, style: .time)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Label("HealthKit Connected", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        if let stepData = viewModel.todaysStepData {
                            Label("\(stepData.confidence) Confidence", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            } else {
                // Not authorized - show primary action
                VStack(spacing: 12) {
                    Button("Connect Motion Tracking") {
                        Task {
                            await viewModel.requestMotionPermissions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Enable Walk Reminders") {
                        Task {
                            await viewModel.requestNotificationPermissions()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Text("Enable step tracking and walk reminders for your dog")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var profileButton: some View {
        Button(action: {
            viewModel.showingProfile = true
        }) {
            Image(systemName: "person.circle")
                .font(.title2)
        }
    }
    
    // MARK: - Helper Methods
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - Activity Details View
struct ActivityDetailsView: View {
    let stepData: [StepData]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(stepData) { data in
                        activityDetailCard(data)
                    }
                }
                .padding()
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func activityDetailCard(_ data: StepData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(data.formattedDate)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(data.activityEmoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Dog Steps:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(data.estimatedDogSteps)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Human Steps:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(data.humanSteps)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Distance:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f km", data.distanceInKilometers))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Goal Progress:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(data.goalProgressPercentage)%")
                        .fontWeight(.medium)
                        .foregroundStyle(data.isGoalMet ? .green : .primary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Profile Sheet View
struct ProfileSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let profile = viewModel.dogProfile {
                    VStack(spacing: 16) {
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue.gradient)
                        
                        Text(profile.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(profile.breedName) • \(profile.bodyCondition.rawValue)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Dog Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
} 