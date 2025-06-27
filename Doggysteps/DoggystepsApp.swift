//
//  DoggystepsApp.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI
import CoreMotion

// MARK: - Pixel Theme Colors
extension Color {
    static let pixelGreen = Color(red: 0.4, green: 0.7, blue: 0.6)
    static let pixelDarkGreen = Color(red: 0.2, green: 0.5, blue: 0.4)
    static let pixelBeige = Color(red: 0.9, green: 0.85, blue: 0.7)
    static let pixelDarkBeige = Color(red: 0.8, green: 0.75, blue: 0.6)
    static let pixelBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
}

// MARK: - Main App
@main
struct DoggystepsApp: App {
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .onAppear {
                    print("🐕 [DoggystepsApp] Initializing Doggysteps app")
                    
                    // Initialize core services
                    let persistenceController = PersistenceController.shared
                    let notificationService = NotificationService.shared
                    let coreMotionService = CoreMotionService.shared
                    
                    print("🐕 [DoggystepsApp] App coordinator view appeared")
                    print("💾 [DoggystepsApp] Persistence controller initialized")
                    print("📱 [DoggystepsApp] Notification service initialized")
                    print("📱 [DoggystepsApp] CoreMotion service initialized")
                    
                    // Load existing profile if available
                    if let profile = persistenceController.currentDogProfile {
                        print("✅ [DoggystepsApp] Loaded existing profile: \(profile.name)")
                    } else {
                        print("💭 [DoggystepsApp] No saved profile found - first run")
                    }
                    
                    // Print app capabilities
                    self.printAppCapabilities()
                }
        }
    }
    
    // MARK: - Private Methods
    private func printAppCapabilities() {
        print("🐕 [DoggystepsApp] Setting up app capabilities...")
        
        // CoreMotion capability check
        if CMPedometer.isStepCountingAvailable() {
            print("✅ [DoggystepsApp] CoreMotion step counting is available on this device")
        } else {
            print("❌ [DoggystepsApp] CoreMotion step counting is NOT available on this device")
        }
        
        // Push notification capability
        print("📱 [DoggystepsApp] Push notifications capability ready for setup")
    }
}

// MARK: - App Coordinator View
struct AppCoordinatorView: View {
    
    // MARK: - Properties
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @ObservedObject private var persistenceController = PersistenceController.shared
    @State private var isCheckingOnboardingStatus = true
    
    // MARK: - Body
    var body: some View {
        Group {
            if isCheckingOnboardingStatus {
                // Loading screen while checking onboarding status
                loadingView
            } else if shouldShowOnboarding {
                // Show onboarding flow for new users
                OnboardingCoordinatorView()
                    .environmentObject(onboardingViewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                // Show main app for returning users
                MainAppView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: shouldShowOnboarding)
        .animation(.easeInOut(duration: 0.3), value: isCheckingOnboardingStatus)
        .onAppear {
            checkOnboardingStatus()
        }
        .onChange(of: onboardingViewModel.isOnboardingComplete) { _, isComplete in
            if isComplete {
                print("🐕 [AppCoordinatorView] Onboarding completed, transitioning to main app")
                
                // Mark onboarding as completed in persistence
                persistenceController.markOnboardingCompleted()
                
                // Small delay for smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        // This will trigger the computed property to re-evaluate
                        isCheckingOnboardingStatus = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var shouldShowOnboarding: Bool {
        let hasCompletedOnboarding = persistenceController.isOnboardingCompleted()
        let hasValidProfile = persistenceController.currentDogProfile != nil
        
        print("🐕 [AppCoordinatorView] Onboarding check - Completed: \(hasCompletedOnboarding), Has Profile: \(hasValidProfile)")
        
        // Show onboarding if either condition is false
        return !hasCompletedOnboarding || !hasValidProfile
    }
    
    // MARK: - View Components - Modern Loading Screen
    private var loadingView: some View {
        ZStack {
            // Clean background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon with modern styling
                VStack(spacing: 20) {
                    // App icon
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    
                    // App title
                    VStack(spacing: 8) {
                        Text("Doggysteps")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Track your dog's daily adventures")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Modern loading indicator
                VStack(spacing: 16) {
                    // Activity indicator
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    
                    Text("Loading...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Private Methods
    private func checkOnboardingStatus() {
        print("🐕 [AppCoordinatorView] Checking onboarding status...")
        
        // Simulate a brief loading time for smooth UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isCheckingOnboardingStatus = false
            }
            
            if shouldShowOnboarding {
                print("🐕 [AppCoordinatorView] Showing onboarding flow")
            } else {
                print("🐕 [AppCoordinatorView] Showing main app")
            }
        }
    }
}
