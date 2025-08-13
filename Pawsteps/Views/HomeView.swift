//
//  HomeView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 HomeView - Pixel Game Theme Dashboard
 
 Features Implemented:
 ✅ Retro pixel game aesthetic
 ✅ Green/teal color scheme with beige accents
 ✅ Game-like inventory display for metrics
 ✅ Pixelated progress bars and UI elements
 ✅ 8-bit style typography and icons
 ✅ Personalized greeting with pixel styling
 ✅ Dog steps today with breed-specific calculations
 ✅ Distance walked with metric/imperial support
 ✅ Pixel progress circle with animations
 ✅ Activity insights with game-style presentation
 ✅ Weekly activity chart in pixel style
 ✅ Health status summary with pixel styling
 ✅ Comprehensive error handling with pixel aesthetics
 ✅ Responsive design with pixel game aesthetics
 
 UI Components:
 - Pixel header with greeting and dog profile card
 - Today's activity summary with pixel progress indicators
 - Pixelated circular progress chart
 - Activity insights with pixel presentation
 - Pixel stats cards (human steps, weekly average)
 - Weekly activity bar chart in pixel style
 - Health status summary with pixel confidence indicators
 - Pixel action buttons with game styling
 - Activity details sheet with pixel data breakdown
 - Profile management sheet with pixel design
 */

import SwiftUI
import Charts

// MARK: - Home View
struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingActivityDetails = false
    @State private var showingReminderSettings = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pixel header with greeting and dog info
                    pixelHeaderSection
                    
                    if viewModel.motionAuthorized {
                        // Today's step summary
                        pixelTodaysSummarySection
                        
                        // Pixel progress section
                        pixelProgressSection
                        
                        // Activity insights
                        pixelActivityInsightsSection
                        
                        // Quick stats
                        pixelQuickStatsSection
                        
                        // Weekly chart
                        if !viewModel.weeklyStepData.isEmpty {
                            pixelWeeklyChartSection
                        }
                        
                        // Health status summary
                        pixelHealthStatusSection
                    } else {
                        // Core Motion authorization prompt
                        pixelMotionPromptSection
                    }
                    
                    // Action buttons
                    pixelActionButtonsSection
                }
                .padding(.horizontal, 16)
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.pixelGreen, Color.pixelDarkGreen],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .overlay(alignment: .top) {
            // Pixel navigation header
            pixelNavigationHeader
        }
        .sheet(isPresented: $viewModel.showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView()
                .environmentObject(viewModel)
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
        .onAppear {
            print("🏠 [HomeView] Pixel Home view appeared")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("🏠 [HomeView] App became active, checking motion status")
            viewModel.refreshMotionStatus()
        }
    }
    
    // MARK: - Pixel Navigation Header
    private var pixelNavigationHeader: some View {
        HStack {
            // Settings button (LB)
            Button(action: { 
                HapticService.shared.selection()
                viewModel.showingSettings = true 
            }) {
                Text("LB")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pixelBrown)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.black, lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            // App title
            LogoView()
            
            Spacer()
            
            // Profile button (RB)
            Button(action: { 
                HapticService.shared.selection()
                viewModel.showingProfile = true 
            }) {
                Text("RB")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pixelBrown)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.black, lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Pixel View Components
    private var pixelHeaderSection: some View {
        VStack(spacing: 20) {
            // Greeting
            VStack(spacing: 8) {
                Text(viewModel.greeting)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 1, y: 1)
            }
            .padding(.top, 20)
            
            // Dog info card
            if let dogProfile = viewModel.dogProfile {
                pixelDogInfoCard(dogProfile)
            }
        }
    }
    
    private func pixelDogInfoCard(_ profile: DogProfile) -> some View {
        HStack(spacing: 16) {
            // Dog avatar
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.pixelBeige)
                .background(
                    Circle()
                        .fill(Color.pixelDarkGreen)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.3), lineWidth: 1)
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.pixelBrown)
                
                Text("\(profile.breedName) • \(profile.bodyCondition.rawValue)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.pixelBrown.opacity(0.8))
            }
            
            Spacer()
            
            // Motion status
            VStack(spacing: 6) {
                Image(systemName: viewModel.motionAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(viewModel.motionAuthorized ? .green : .red)
                
                Text(viewModel.motionAuthorized ? "Connected" : "Disconnected")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.pixelBrown)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pixelBeige)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pixelDarkBeige, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 0, x: 2, y: 2)
        )
    }
    
    private var pixelTodaysSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📦 TODAY'S ACTIVITY")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            
            if let stepData = viewModel.todaysStepData {
                pixelTodaysSummaryCard(stepData)
            } else if viewModel.isLoading {
                pixelLoadingCard
            } else {
                pixelNoDataCard
            }
        }
    }
    
    private func pixelTodaysSummaryCard(_ stepData: StepData) -> some View {
        VStack(spacing: 16) {
            // Main metrics row
            HStack(spacing: 16) {
                // Dog Steps
                VStack(spacing: 4) {
                    Text("🐕")
                        .font(.title2)
                    Text("\(stepData.estimatedDogSteps)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                    Text("Dog Steps")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pixelBeige.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.pixelDarkBeige, lineWidth: 1)
                        )
                )
                
                // Distance
                VStack(spacing: 4) {
                    Text("🗺️")
                        .font(.title2)
                    Text(String(format: "%.1f km", stepData.distanceInKilometers))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                    Text("Distance")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pixelBeige.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.pixelDarkBeige, lineWidth: 1)
                        )
                )
            }
            
            // Pixel progress bar
            pixelProgressBar(progress: stepData.goalProgress, percentage: stepData.goalProgressPercentage)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pixelBeige)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pixelDarkBeige, lineWidth: 2)
                )
        )
    }
    
    private func pixelProgressBar(progress: Double, percentage: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Daily Goal Progress")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.pixelBrown)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(Color.pixelBrown)
            }
            
            // Pixelated progress bar
            GeometryReader { geometry in
                let progressClamped = min(max(progress, 0), 1.0)
                let filledSegments = Int(progressClamped * 15)
                
                HStack(spacing: 2) {
                    // Progress segments (filled)
                    ForEach(0..<filledSegments, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.pixelDarkGreen)
                            .frame(height: 8)
                    }
                    
                    // Empty segments (remaining)
                    ForEach(filledSegments..<15, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.pixelDarkBeige)
                            .frame(height: 8)
                    }
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
    
    private var pixelLoadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading today's activity...")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color.pixelBrown)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    private var pixelNoDataCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No activity data yet")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color.pixelBrown.opacity(0.8))
            
            if !viewModel.motionAuthorized {
                VStack(spacing: 12) {
                    Button("Enable Motion Tracking") {
                        HapticService.shared.selection()
                        Task {
                            await viewModel.requestMotionPermissions()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Check Status") {
                        HapticService.shared.selection()
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(Color.pixelBrown)
                }
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    private var pixelProgressSection: some View {
        VStack(spacing: 16) {
            Text("Daily Progress")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color.pixelBrown)
            
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
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                    
                    Text("of goal")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                }
            }
        }
    }
    
    private var pixelQuickStatsSection: some View {
        VStack(spacing: 20) {
            // Main step count display (like temperature)
            if let stepData = viewModel.todaysStepData {
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(stepData.estimatedDogSteps)")
                            .font(.system(size: 72, weight: .black))
                            .foregroundColor(.primary)
                        
                        Text("steps")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    
                    Text("\(stepData.goalProgressPercentage)% of daily goal")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            
            // Weather-style metrics grid
            VStack(spacing: 16) {
                // Row 1
                HStack {
                    // Distance metric
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        if let stepData = viewModel.todaysStepData {
                            Text(String(format: "%.1f mi", stepData.distanceInKilometers * 0.621371))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        } else {
                            Text("0.0 mi")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("DISTANCE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Row 2
                HStack {
                    // Active time metric
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        if let stepData = viewModel.todaysStepData {
                            Text(formatActiveTime(minutes: Int(stepData.distanceInKilometers * 12))) // Rough estimate
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        } else {
                            Text("0 min")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("ACTIVE TIME")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Row 3
                HStack {
                    // Human steps metric
                    HStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("\(viewModel.todaysStepData?.humanSteps ?? 0)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("HUMAN STEPS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Row 4
                HStack {
                    // Weekly average metric
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("\(viewModel.weeklyAverage)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("WEEKLY AVG")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Row 5
                HStack {
                    // Goal progress metric
                    HStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        if let stepData = viewModel.todaysStepData {
                            Text("\(stepData.goalProgressPercentage)%")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.primary)
                        } else {
                            Text("0%")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("GOAL PROGRESS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Row 6
                HStack {
                    // Motion status metric
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.motionAuthorized ? "sensor.tag.radiowaves.forward.fill" : "sensor.tag.radiowaves.forward")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text(viewModel.motionAuthorized ? "Connected" : "Disconnected")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("MOTION SENSOR")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // Helper function for formatting active time
    private func formatActiveTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
    
    private var pixelWeeklyChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Activity")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                
                Spacer()
                
                Button("View Details") {
                    showingActivityDetails = true
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.blue)
            }
            
            // Simple bar chart representation
            pixelWeeklyChart
        }
    }
    
    private var pixelWeeklyChart: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(viewModel.weeklyStepData.prefix(7).enumerated()), id: \.offset) { index, stepData in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue.gradient)
                        .frame(width: 32, height: CGFloat(stepData.estimatedDogSteps) / 200.0)
                        .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: stepData.estimatedDogSteps)
                    
                    Text(dayOfWeek(from: stepData.date))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                }
            }
        }
        .padding()
        .frame(height: 120)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Enhanced Phase 4 Sections
    
    private var pixelActivityInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Activity Insights")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                
                Spacer()
                
                Text(viewModel.activityTrend.emoji)
                    .font(.system(size: 20))
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.activityInsights.prefix(3), id: \.message) { insight in
                    HStack(spacing: 12) {
                        Image(systemName: insightIcon(for: insight))
                            .font(.system(size: 20))
                            .foregroundColor(insightColor(for: insight))
                            .frame(width: 24)
                        
                        Text(insight.message)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.pixelBrown)
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
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                        .italic()
                        .padding()
                }
            }
        }
    }
    
    private var pixelHealthStatusSection: some View {
        VStack(spacing: 16) {
            Text("Health Summary")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color.pixelBrown)
            
            VStack(spacing: 16) {
                // Today's summary
                if let stepData = viewModel.todaysStepData {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today's Assessment")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.pixelBrown)
                            
                            Spacer()
                            
                            Text(stepData.activityEmoji)
                                .font(.system(size: 20))
                        }
                        
                        Text(viewModel.motionStatusSummary)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.pixelBrown)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Weekly trend
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Trend")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                    
                    Text(viewModel.weeklyStepTrend)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                }
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Data quality indicator
                if let stepData = viewModel.todaysStepData {
                    HStack {
                        Text("Data Confidence:")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.pixelBrown.opacity(0.8))
                        
                        Text(stepData.confidenceEmoji)
                        Text(stepData.confidence)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Quality: \(stepData.confidence)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.pixelBrown.opacity(0.8))
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var pixelMotionPromptSection: some View {
                 VStack(spacing: 20) {
             Image(systemName: "figure.walk.circle")
                 .font(.system(size: 60))
                 .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Enable Step Tracking")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.pixelBrown)
                
                Text("Allow motion access to track your walks and calculate your dog's steps during active walk sessions.")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.pixelBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Enable Motion Tracking") {
                    HapticService.shared.selection()
                    Task {
                        await viewModel.requestMotionPermissions()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                

            }
            
            Text("Step counting only works during active walk sessions - no background tracking.")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color.pixelBrown.opacity(0.8))
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
    
    private var pixelActionButtonsSection: some View {
        VStack(spacing: 16) {
            if viewModel.motionAuthorized {
                // Authorized action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        HapticService.shared.selection()
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
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        HapticService.shared.selection()
                        showingReminderSettings = true
                    }) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Reminders")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                // Status information
                VStack(spacing: 8) {
                    if let lastUpdate = viewModel.lastUpdateTime {
                        Text("Last updated: \(lastUpdate, style: .time)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.pixelBrown.opacity(0.8))
                    }
                    
                    HStack(spacing: 16) {
                        Label("HealthKit Connected", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        if let stepData = viewModel.todaysStepData {
                            Label("\(stepData.confidence) Confidence", systemImage: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                // Not authorized - show primary action
                VStack(spacing: 12) {
                    Button("Connect Motion Tracking") {
                        HapticService.shared.selection()
                        Task {
                            await viewModel.requestMotionPermissions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    

                    
                    Text("Enable step tracking for your dog")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                }
            }
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
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                
                Spacer()
                
                Text(data.activityEmoji)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Dog Steps:")
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                    Spacer()
                    Text("\(data.estimatedDogSteps)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                }
                
                HStack {
                    Text("Human Steps:")
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                    Spacer()
                    Text("\(data.humanSteps)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                }
                
                HStack {
                    Text("Distance:")
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                    Spacer()
                    Text(String(format: "%.1f km", data.distanceInKilometers))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.pixelBrown)
                }
                
                HStack {
                    Text("Goal Progress:")
                        .foregroundColor(Color.pixelBrown.opacity(0.8))
                    Spacer()
                    Text("\(data.goalProgressPercentage)%")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(data.isGoalMet ? .green : .primary)
                }
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                            .foregroundColor(Color.pixelBeige)
                        
                        Text(profile.name)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                        
                        Text("\(profile.breedName) • \(profile.bodyCondition.rawValue)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
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