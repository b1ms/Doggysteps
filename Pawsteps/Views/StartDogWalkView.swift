//
//  StartDogWalkView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Start Dog Walk View - Modern Fitness App UI
 
 Features:
 ✅ Clean modern design matching TodayView
 ✅ Large action button with modern styling
 ✅ Real-time step tracking using CoreMotion during active walks only
 ✅ Dog step calculation only during active walk sessions
 ✅ Walk session management and data persistence
 ✅ Card-based metrics layout
 ✅ Consistent with TodayView aesthetics
 */

import SwiftUI
import CoreMotion

// MARK: - Start Dog Walk View
struct StartDogWalkView: View {
    
    // MARK: - Properties
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var currentWalkSession: WalkSession?
    @State private var showingWalkOptions = false
    @State private var showingPermissionAlert = false
    @State private var walkTimer: Timer?
    @State private var walkStartTime: Date?
    @State private var showingProfileAlert = false
    
    // Core Motion - Using centralized service only
    private let coreMotionService = CoreMotionService.shared
    
    // Live Activity service for persistent walk tracking
    @StateObject private var liveActivityService = LiveActivityService.shared
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header
                    topHeader
                    
                    // Main content
                    VStack(spacing: 24) {
                        // Header section
                        headerSection
                        
                        // Main action button
                        mainActionButton
                        
                        // Current session info
                        if let session = currentWalkSession {
                            currentSessionCard(session)
                        }
                        
                        // Recent walks section
                        recentWalksSection
                        
                        // Dog profile prompt if needed
                        if viewModel.dogProfile == nil {
                            profilePromptSection
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60) // Space for bottom navigation
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .alert("No Profile", isPresented: $showingProfileAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please create a dog profile from the Today tab before starting a walk session.")
        }
        .alert("Motion Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Motion permission is required to track steps during walks. Please enable it in Settings.")
        }
        .onAppear {
            // Listen for stop walk notifications from Live Activity buttons
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StopWalkFromLiveActivity"),
                object: nil,
                queue: .main
            ) { _ in
                stopWalk()
            }
        }
        .onDisappear {
            // Remove notification observers
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("StopWalkFromLiveActivity"), object: nil)
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
                // Walk status indicator
                if currentWalkSession?.isActive == true {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentWalkSession?.isActive == true)
                        Text("Walking")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(16)
                } else {
                    Spacer()
                }
                
                Spacer()
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Dog icon
            Text("🐶")
                .font(.system(size: 60, weight: .medium))
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(40)
            
            VStack(spacing: 8) {
                Text(currentWalkSession?.isActive == true ? "Walk in Progress" : "Ready for a Walk?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let dogName = viewModel.dogProfile?.name {
                    Text(currentWalkSession?.isActive == true ? "Keep going with \(dogName)!" : "Time to take \(dogName) out!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Main Action Button
    private var mainActionButton: some View {
        Button(action: {
            HapticService.shared.heavy()
            if currentWalkSession != nil {
                stopWalk()
            } else {
                startWalk()
            }
        }) {
            HStack(spacing: 16) {
                // Icon matching TodayView metric card style
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonBackgroundColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: buttonIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(buttonIconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(buttonTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(buttonSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(buttonBackgroundColor.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Button Properties
    private var buttonIcon: String {
        guard let session = currentWalkSession else { return "play.fill" }
        return session.isActive ? "stop.fill" : "play.fill"
    }
    
    private var buttonIconColor: Color {
        guard let session = currentWalkSession else { return .green }
        return session.isActive ? .red : .green
    }
    
    private var buttonBackgroundColor: Color {
        guard let session = currentWalkSession else { return .green }
        return session.isActive ? .red : .green
    }
    
    private var buttonTitle: String {
        guard let session = currentWalkSession else { return "Start Walk" }
        return session.isActive ? "Stop Walk" : "Start Walk"
    }
    
    private var buttonSubtitle: String {
        guard let session = currentWalkSession else { return "Begin tracking steps" }
        return session.isActive ? "End current session" : "Begin tracking steps"
    }
    
    // MARK: - Current Session Card
    private func currentSessionCard(_ session: WalkSession) -> some View {
        VStack(spacing: 20) {
            // Session header
            HStack {
                                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.3)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentWalkSession?.isActive == true)
                    
                    Text("Active Session")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("LIVE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                                     .padding(.vertical, 4)
                 .background(Color.red)
                 .cornerRadius(8)
            }
            
            // Session metrics
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                sessionMetricCard(
                    icon: "clock.fill",
                    title: "Duration",
                    value: session.formattedDuration,
                    backgroundColor: .blue.opacity(0.1),
                    iconColor: .blue
                )
                
                sessionMetricCard(
                    icon: "person.fill",
                    title: "Human Steps",
                    value: "\(session.humanSteps)",
                    backgroundColor: .orange.opacity(0.1),
                    iconColor: .orange
                )
                
                sessionMetricCard(
                    icon: "pawprint.fill",
                    title: "Dog Steps",
                    value: "\(session.estimatedDogSteps)",
                    backgroundColor: .green.opacity(0.1),
                    iconColor: .green
                )
                
                sessionMetricCard(
                    icon: "location.fill",
                    title: "Distance",
                    value: String(format: "%.1f km", session.distanceInKilometers),
                    backgroundColor: .purple.opacity(0.1),
                    iconColor: .purple
                )
            }
        }
        .padding(24)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
    
    // MARK: - Session Metric Card
    private func sessionMetricCard(
        icon: String,
        title: String,
        value: String,
        backgroundColor: Color,
        iconColor: Color
    ) -> some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)
            
            // Value and title
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Walks Section
    private var recentWalksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Walks")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if viewModel.todaysWalkSessions.isEmpty {
                VStack(spacing: 16) {
                    Text("👻")
                        .font(.system(size: 48))
                    
                    VStack(spacing: 8) {
                        Text("No walks today yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Start your first walk to see it here")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.todaysWalkSessions.reversed(), id: \.id) { session in
                        recentWalkRow(session)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Walk Row
    private func recentWalkRow(_ session: WalkSession) -> some View {
        let walkIndex = viewModel.todaysWalkSessions.firstIndex(where: { $0.id == session.id }) ?? 0
        let dogEmoji = getDogEmoji(for: walkIndex)
        
        return HStack(spacing: 16) {
            // Walk icon - rotating dog emojis
            Text(dogEmoji)
                .font(.system(size: 30))
                .frame(width: 40, height: 40)
            
            // Walk details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.estimatedDogSteps) dog steps")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(session.formattedDuration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.startTime, style: .time)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(session.startTime, style: .date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper method for rotating dog emojis
    private func getDogEmoji(for index: Int) -> String {
        let dogEmojis = ["🦮", "🐩", "🐕", "🐕‍🦺"]
        return dogEmojis[index % dogEmojis.count]
    }
    
    // MARK: - Profile Prompt Section
    private var profilePromptSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Create Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Set up your dog's profile to get accurate step calculations during walks.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Profile") {
                HapticService.shared.selection()
                // Note: Profile creation is available in the Today tab
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(12)
        }
        .padding(24)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Walk Management Methods
    
    private func startWalk() {
        print("🚶 [StartDogWalkView] Starting dog walk session")
        
        guard let profile = viewModel.dogProfile else {
            print("❌ [StartDogWalkView] No dog profile available")
            showingProfileAlert = true
            return
        }
        
        guard currentWalkSession == nil else {
            print("⚠️ [StartDogWalkView] Walk already in progress")
            return
        }
        
        // Create new walk session
        let breedMultiplier = viewModel.getBreedMultiplier(for: profile.breedName)
        var newSession = WalkSession(
            breedName: profile.breedName,
            breedMultiplier: breedMultiplier
        )
        newSession.isActive = true
        currentWalkSession = newSession
        walkStartTime = Date()
        
        print("✅ [StartDogWalkView] Walk session started for \(profile.name)")
        
        // Start Live Activity for persistent tracking
        Task {
            print("🔴 [StartDogWalkView] Attempting to start Live Activity...")
            print("🔴 [StartDogWalkView] Live Activities supported: \(liveActivityService.isActivitySupported)")
            
            let success = await liveActivityService.startWalkActivity(
                dogName: profile.name,
                breedName: profile.breedName
            )
            
            if success {
                print("✅ [StartDogWalkView] Live Activity started successfully")
                print("🔴 [StartDogWalkView] Activity ID: \(liveActivityService.getActivityId() ?? "unknown")")
            } else {
                print("❌ [StartDogWalkView] Live Activity failed to start")
                print("🔴 [StartDogWalkView] Reason: Live Activities not supported or not enabled")
                print("🔴 [StartDogWalkView] Check: iOS 16.1+, Physical device, Widget Extension, Info.plist")
            }
        }
        
        // Start CoreMotion tracking
        startPedometerTracking()
    }
    
    private func startPedometerTracking() {
        print("📱 [StartDogWalkView] Starting walk session via CoreMotionService")
        
        // Check if session is already active
        if coreMotionService.isSessionActive() {
            print("⚠️ [StartDogWalkView] Walk session already active")
            return
        }
        
        // Start tracking using centralized service
        Task {
            await startWalkSession()
        }
    }
    
    private func startWalkSession() async {
        let result = await coreMotionService.startWalkSession()
        
        switch result {
        case .success:
            print("✅ [StartDogWalkView] Walk session started successfully")
            await MainActor.run {
                startDurationTimer()
            }
        case .failure(let error):
            print("❌ [StartDogWalkView] Failed to start walk session: \(error)")
            
            await MainActor.run {
                showingPermissionAlert = true
                currentWalkSession = nil
                walkStartTime = nil
            }
        }
    }
    
    private func startDurationTimer() {
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateSessionFromCoreMotion()
        }
    }
    
    private func updateSessionFromCoreMotion() {
        guard var session = currentWalkSession, session.isActive else { return }
        
        // Get current session data from CoreMotionService
        if let sessionData = coreMotionService.getCurrentSessionData() {
            session.duration = sessionData.duration
            session.humanSteps = sessionData.steps
            session.estimatedDogSteps = Int(Double(session.humanSteps) * session.breedMultiplier)
            session.distanceInMeters = sessionData.distance
            session.dataSource = "CoreMotion"
            
            self.currentWalkSession = session
            
            // Update live walk notification every 30 seconds
            if Int(session.duration) % 30 == 0 && session.duration > 0 {
                print("📱 [StartDogWalkView] Session update: \(session.humanSteps) human steps → \(session.estimatedDogSteps) dog steps")
                
                // Update Live Activity with current progress
                if let dogName = viewModel.dogProfile?.name {
                    Task {
                        // Update Live Activity with real-time data
                        await liveActivityService.updateWalkActivity(
                            duration: session.duration,
                            humanSteps: session.humanSteps,
                            dogSteps: session.estimatedDogSteps,
                            distance: session.distanceInMeters,
                            pace: "--'--\"" // We can calculate pace later if needed
                        )
                    }
                }
            }
        }
    }
    
    private func stopWalk() {
        print("🛑 [StartDogWalkView] Stopping dog walk")
        
        guard let session = currentWalkSession, session.isActive else {
            print("⚠️ [StartDogWalkView] No active walk session")
            return
        }
        
        // Stop timer immediately
        walkTimer?.invalidate()
        walkTimer = nil
        
        // Stop walk session via CoreMotionService
        if let sessionData = coreMotionService.stopWalkSession() {
            // Finalize walk session with data from CoreMotionService
            var finalSession = session
            finalSession.endTime = sessionData.endTime ?? Date()
            finalSession.isActive = false
            finalSession.usedHealthKit = false
            finalSession.dataSource = "CoreMotion"
            finalSession.duration = sessionData.duration
            finalSession.humanSteps = sessionData.steps
            finalSession.estimatedDogSteps = Int(Double(finalSession.humanSteps) * finalSession.breedMultiplier)
            finalSession.distanceInMeters = sessionData.distance
            
            // Save completed walk session
            viewModel.saveCompletedWalkSession(finalSession)
            print("✅ [StartDogWalkView] Walk completed: \(finalSession.estimatedDogSteps) dog steps in \(finalSession.formattedDuration)")
            
            // Stop Live Activity
            Task {
                // End Live Activity with final stats
                await liveActivityService.endWalkActivity(
                    finalSteps: finalSession.estimatedDogSteps,
                    finalDuration: finalSession.formattedDuration
                )
            }
        }
        
        // Clear session state
        currentWalkSession = nil
        walkStartTime = nil
        
        print("🛑 [StartDogWalkView] Session stopped and cleared")
    }


}

// MARK: - Walk Options View (Modern Theme)
struct WalkOptionsView: View {
    let onStartWalk: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.blue)
                                                     .frame(width: 80, height: 80)
                         .background(Color.blue.opacity(0.1))
                         .cornerRadius(40)
                        
                        VStack(spacing: 8) {
                            Text("Start Dog Walk")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Track your dog's steps in real-time")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Features
                    VStack(spacing: 16) {
                        walkFeature(
                            icon: "figure.walk",
                            title: "Step Tracking",
                            description: "Real-time pedometer tracking during walks"
                        )
                        
                        walkFeature(
                            icon: "location.fill",
                            title: "Distance Tracking",
                            description: "Accurate distance from device sensors"
                        )
                        
                        walkFeature(
                            icon: "clock.fill",
                            title: "Duration Tracking",
                            description: "Monitor walk duration and pace"
                        )
                    }
                    
                    // How it works
                    VStack(spacing: 16) {
                        Text("How It Works")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(text: "Uses your phone's built-in pedometer for accurate step counting")
                            InfoRow(text: "Dog steps are calculated using breed-specific multipliers")
                            InfoRow(text: "All data is saved when you complete the walk")
                        }
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Start button
                    Button("Start Walk") {
                        HapticService.shared.selection()
                        onStartWalk()
                        dismiss()
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                                 .background(Color.blue)
             .cornerRadius(12)
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Walk Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func walkFeature(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                                 .frame(width: 40, height: 40)
                 .background(Color.blue.opacity(0.1))
                 .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
                         Circle()
                 .fill(Color.blue)
                 .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Session Metric Component (Modern Theme)
struct SessionMetric: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    StartDogWalkView()
        .environmentObject(HomeViewModel())
} 