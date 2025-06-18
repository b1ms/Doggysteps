//
//  StartDogWalkView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Start Dog Walk View - Minimalist Black & White Design
 
 Features:
 ✅ Large "Start Workout" button with minimal styling
 ✅ Real-time step tracking using CoreMotion during active walks only
 ✅ Dog step calculation only during active walk sessions
 ✅ Walk session management and data persistence
 ✅ Clean monochromatic interface
 ✅ No background estimation or HealthKit dependency
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
    @State private var showingProfileSheet = false
    
    // Core Motion - Using centralized service only
    private let coreMotionService = CoreMotionService.shared
    
    // MARK: - Computed Properties
    private var isWalkingActive: Bool {
        return currentWalkSession?.isActive == true
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
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
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Start Walk")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingProfileSheet) {
            ProfileView()
        }
        .alert("No Profile", isPresented: $showingProfileAlert) {
            Button("Create Profile") {
                showingProfileSheet = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please create a dog profile before starting a walk session.")
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
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 64))
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                Text("Ready for a Walk?")
                    .font(.title2)
                    .fontWeight(.light)
                    .foregroundStyle(.primary)
                    .tracking(0.5)
                
                if let dogName = viewModel.dogProfile?.name {
                    Text("Time to take \(dogName) out for some exercise!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .tracking(0.3)
                }
            }
        }
    }
    
    private var mainActionButton: some View {
        Button(action: {
            if isWalkingActive {
                stopWalk()
            } else {
                startWalk()
            }
        }) {
            VStack(spacing: 16) {
                Image(systemName: isWalkingActive ? "stop.circle" : "play.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.primary)
                
                Text(isWalkingActive ? "Stop Walk" : "Start Walk")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.primary.opacity(isWalkingActive ? 0.6 : 0.3), lineWidth: isWalkingActive ? 2 : 1)
                    .fill(Color(.systemGray6).opacity(isWalkingActive ? 0.1 : 0.05))
            )
        }
        .scaleEffect(isWalkingActive ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isWalkingActive)
    }
    
    private func currentSessionCard(_ session: WalkSession) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Active Walk Session")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .tracking(0.5)
                
                // Live activity indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isWalkingActive)
                    
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .tracking(1)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    SessionMetric(icon: "clock", value: session.formattedDuration, title: "Duration")
                    Spacer()
                    SessionMetric(icon: "figure.walk", value: "\(session.humanSteps)", title: "Steps")
                }
                
                HStack {
                    SessionMetric(icon: "pawprint", value: "\(session.estimatedDogSteps)", title: "Dog Steps")
                    Spacer()
                    SessionMetric(icon: "location", value: String(format: "%.1f km", session.distanceInKilometers), title: "Distance")
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
                .fill(Color(.systemGray6).opacity(0.1))
        )
    }
    
    private var recentWalksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Walks")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .tracking(0.5)
                Spacer()
            }
            
            if viewModel.todaysWalkSessions.isEmpty {
                Text("No walks today yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.quaternary.opacity(0.3))
                    .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.todaysWalkSessions.reversed(), id: \.id) { session in
                        recentWalkRow(session)
                    }
                }
            }
        }
    }
    
    private func recentWalkRow(_ session: WalkSession) -> some View {
        HStack {
            Image(systemName: "figure.walk.circle.fill")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(session.estimatedDogSteps) dog steps")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.startTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.primary)
                
                Text(session.startTime, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var profilePromptSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.orange.gradient)
            
            Text("Create Dog Profile")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Set up your dog's profile to get accurate step calculations during walks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Profile") {
                showingProfileSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Walk Management Methods
    
    private func startWalk() {
        print("🚶 [StartDogWalkView] Starting dog walk session")
        
        guard let profile = viewModel.dogProfile else {
            print("❌ [StartDogWalkView] No dog profile available")
            showingProfileAlert = true
            return
        }
        
        print("🚶 [StartDogWalkView] Profile found: \(profile.name)")
        
        // Create new walk session
        let breedMultiplier = viewModel.getBreedMultiplier(for: profile.breedName)
        print("🚶 [StartDogWalkView] Breed multiplier: \(breedMultiplier)")
        
        currentWalkSession = WalkSession(
            breedName: profile.breedName,
            breedMultiplier: breedMultiplier
        )
        
        walkStartTime = Date()
        
        print("✅ [StartDogWalkView] Walk session started for \(profile.name)")
        
        // Start CoreMotion tracking only
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
        guard var session = currentWalkSession else { return }
        
        // Get current session data from CoreMotionService
        if let sessionData = coreMotionService.getCurrentSessionData() {
            session.duration = sessionData.duration
            session.humanSteps = sessionData.steps
            session.estimatedDogSteps = Int(Double(session.humanSteps) * session.breedMultiplier)
            session.distanceInMeters = sessionData.distance
            session.dataSource = "CoreMotion"
            
            self.currentWalkSession = session
            
            // Debug logging every 30 seconds
            if Int(session.duration) % 30 == 0 && session.duration > 0 {
                print("📱 [StartDogWalkView] Session update: \(session.humanSteps) human steps → \(session.estimatedDogSteps) dog steps")
            }
        }
    }
    
    private func stopWalk() {
        print("🛑 [StartDogWalkView] Stopping dog walk")
        
        // Stop timer
        walkTimer?.invalidate()
        walkTimer = nil
        
        // Stop walk session via CoreMotionService
        if let sessionData = coreMotionService.stopWalkSession() {
            // Finalize walk session with data from CoreMotionService
            if var session = currentWalkSession {
                session.endTime = sessionData.endTime ?? Date()
                session.isActive = false
                session.usedHealthKit = false // CoreMotion only
                session.dataSource = "CoreMotion"
                session.duration = sessionData.duration
                session.humanSteps = sessionData.steps
                session.estimatedDogSteps = Int(Double(session.humanSteps) * session.breedMultiplier)
                session.distanceInMeters = sessionData.distance
                
                // Save completed walk session
                viewModel.saveCompletedWalkSession(session)
                print("✅ [StartDogWalkView] Walk completed: \(session.estimatedDogSteps) dog steps in \(session.formattedDuration)")
            }
        } else {
            print("⚠️ [StartDogWalkView] No session data available from CoreMotionService")
        }
        
        currentWalkSession = nil
        walkStartTime = nil
    }
}

// MARK: - Walk Options View
struct WalkOptionsView: View {
    let onStartWalk: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green.gradient)
                    
                    Text("Start Dog Walk")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track your dog's steps in real-time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    walkOption(
                        icon: "figure.walk",
                        title: "Step Tracking",
                        description: "Real-time pedometer tracking during walks",
                        isEnabled: true
                    )
                    
                    walkOption(
                        icon: "location",
                        title: "Distance Tracking",
                        description: "Accurate distance from device sensors",
                        isEnabled: true
                    )
                    
                    walkOption(
                        icon: "timer",
                        title: "Duration Tracking",
                        description: "Monitor walk duration and pace",
                        isEnabled: true
                    )
                }
                
                VStack(spacing: 12) {
                    Text("How it works:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Uses your phone's built-in pedometer for accurate step counting")
                        Text("• Dog steps are calculated using breed-specific multipliers")
                        Text("• All data is saved when you complete the walk")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(.quaternary.opacity(0.3))
                .cornerRadius(12)
                
                Spacer()
                
                Button("Start Walk") {
                    onStartWalk()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
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
    
    private func walkOption(icon: String, title: String, description: String, isEnabled: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isEnabled ? .blue : .orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isEnabled ? .green : .orange)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Session Metric Component
struct SessionMetric: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .tracking(0.5)
        }
    }
}

// MARK: - Preview
#Preview {
    StartDogWalkView()
        .environmentObject(HomeViewModel())
} 