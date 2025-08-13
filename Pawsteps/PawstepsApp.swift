//
//  PawstepsApp.swift
//  Pawsteps
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
struct PawstepsApp: App {
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .onAppear {
                    print("🐕 [PawstepsApp] Initializing Pawsteps app")
                    
                    // Initialize core services
                    let persistenceController = PersistenceController.shared
                    let coreMotionService = CoreMotionService.shared
                    
                    print("🐕 [PawstepsApp] App coordinator view appeared")
                    print("💾 [PawstepsApp] Persistence controller initialized")
                    print("📱 [PawstepsApp] CoreMotion service initialized")
                    
                    // Load existing profile if available
                    if let profile = persistenceController.currentDogProfile {
                        print("✅ [PawstepsApp] Loaded existing profile: \(profile.name)")
                    } else {
                        print("💭 [PawstepsApp] No saved profile found - first run")
                    }
                    
                    // Print app capabilities
                    self.printAppCapabilities()
                    

                }
                .onOpenURL { url in
                    handleURLScheme(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    handleAppDidEnterBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleAppWillEnterForeground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WidgetOpenAppHaptic"))) { _ in
                    handleWidgetOpenAppHaptic()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WidgetStopWalkHaptic"))) { _ in
                    handleWidgetStopWalkHaptic()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WalkStoppedSuccessHaptic"))) { _ in
                    handleWalkStoppedSuccessHaptic()
                }
        }
    }
    
    // MARK: - URL Scheme Handling
    private func handleURLScheme(_ url: URL) {
        print("🔗 [PawstepsApp] Received URL: \(url)")
        
        guard url.scheme == "doggysteps" else {
            print("❌ [PawstepsApp] Invalid URL scheme: \(url.scheme ?? "none")")
            return
        }
        
        switch url.host {
        case "open":
            print("📱 [PawstepsApp] Opening app from Live Activity")
            // Schedule haptic feedback notification
            NotificationCenter.default.post(
                name: NSNotification.Name("WidgetOpenAppHaptic"), 
                object: nil
            )
            // App will naturally open - no additional action needed
            
        case "stopwalk":
            print("🛑 [PawstepsApp] Stop walk requested from Live Activity")
            // Schedule haptic feedback notification
            NotificationCenter.default.post(
                name: NSNotification.Name("WidgetStopWalkHaptic"), 
                object: nil
            )
            handleStopWalkRequest()
            
        default:
            print("❌ [PawstepsApp] Unknown URL action: \(url.host ?? "none")")
        }
    }
    
    private func handleStopWalkRequest() {
        // Stop any active walk session
        DispatchQueue.main.async {
            // Get the live activity service
            let liveActivityService = LiveActivityService.shared
            
            // End any active Live Activities
            Task {
                await liveActivityService.forceEndActivity()
                print("🛑 [PawstepsApp] Live Activity ended from URL scheme")
                
                // Post notification for success haptic feedback
                NotificationCenter.default.post(
                    name: NSNotification.Name("WalkStoppedSuccessHaptic"), 
                    object: nil
                )
            }
            
            // You can add additional logic here to stop the walk in your app
            // For example, notify other services or update the UI
            NotificationCenter.default.post(name: NSNotification.Name("StopWalkFromLiveActivity"), object: nil)
        }
    }
    
    // MARK: - Private Methods
    private func printAppCapabilities() {
        print("🐕 [PawstepsApp] Setting up app capabilities...")
        
        // CoreMotion capability check
        if CMPedometer.isStepCountingAvailable() {
            print("✅ [PawstepsApp] CoreMotion step counting is available on this device")
        } else {
            print("❌ [PawstepsApp] CoreMotion step counting is NOT available on this device")
        }
    }
    

    

    
    // MARK: - App Lifecycle Handlers
    private func handleAppDidEnterBackground() {
        print("📱 [PawstepsApp] App did enter background")
    }
    
    private func handleAppWillEnterForeground() {
        print("📱 [PawstepsApp] App will enter foreground")
    }
    
    private func handleAppDidBecomeActive() {
        print("📱 [PawstepsApp] App did become active")
    }
    
    // MARK: - Widget Haptic Handlers
    private func handleWidgetOpenAppHaptic() {
        print("🔔 [PawstepsApp] Widget Open App haptic triggered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticService.shared.medium()
        }
    }
    
    private func handleWidgetStopWalkHaptic() {
        print("🔔 [PawstepsApp] Widget Stop Walk haptic triggered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticService.shared.heavy()
        }
    }
    
    private func handleWalkStoppedSuccessHaptic() {
        print("🔔 [PawstepsApp] Walk stopped success haptic triggered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticService.shared.success()
        }
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
    
    // MARK: - View Components - PAWSTEPS Loading Screen
    private var loadingView: some View {
        ZStack {
            // Clean background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // PAWSTEPS title with same font as step counter
                Text("PAWSTEPS")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                
                Spacer()
            }
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
