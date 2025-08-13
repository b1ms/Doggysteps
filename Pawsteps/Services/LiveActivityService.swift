//
//  LiveActivityService.swift
//  Doggysteps
//
//  Created by Assistant on 07/01/2025.
//

import Foundation
import ActivityKit
import UIKit

// MARK: - Live Activity Service
@MainActor
class LiveActivityService: ObservableObject {
    
    // MARK: - Properties
    static let shared = LiveActivityService()
    
    @Published private(set) var currentActivity: Activity<WalkActivityAttributes>?
    @Published private(set) var isActivityActive = false
    @Published private(set) var isActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
    
    private var activityUpdateTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        print("🔴 [LiveActivityService] Initializing Live Activity service")
        checkActivitySupport()
    }
    
    // MARK: - Activity Support Check
    func checkActivitySupport() {
        let authInfo = ActivityAuthorizationInfo()
        isActivitySupported = authInfo.areActivitiesEnabled
        
        print("🔴 [LiveActivityService] Live Activities supported: \(isActivitySupported)")
        print("🔴 [LiveActivityService] Activities enabled: \(authInfo.areActivitiesEnabled)")
    }
    
    // MARK: - Start Activity
    func startWalkActivity(dogName: String, breedName: String) async -> Bool {
        let authInfo = ActivityAuthorizationInfo()
        
        print("🔴 [LiveActivityService] === LIVE ACTIVITY DEBUG ===")
        print("🔴 [LiveActivityService] iOS Version: \(ProcessInfo.processInfo.operatingSystemVersion)")
        print("🔴 [LiveActivityService] Activities Enabled: \(authInfo.areActivitiesEnabled)")
        print("🔴 [LiveActivityService] App State: \(UIApplication.shared.applicationState.rawValue)")
        print("🔴 [LiveActivityService] Current Activity: \(currentActivity?.id ?? "none")")
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ [LiveActivityService] Live Activities not enabled")
            print("🔴 [LiveActivityService] Possible reasons:")
            print("   - iOS version < 16.1")
            print("   - Running on Simulator (not supported)")
            print("   - Live Activities disabled in Settings")
            print("   - Widget Extension not configured")
            print("   - Info.plist missing NSSupportsLiveActivities")
            return false
        }
        
        guard currentActivity == nil else {
            print("⚠️ [LiveActivityService] Activity already active: \(currentActivity!.id)")
            return false
        }
        
        print("🔴 [LiveActivityService] Starting Live Activity for \(dogName)")
        
        let attributes = WalkActivityAttributes(
            dogName: dogName,
            breedName: breedName,
            walkStartTime: Date()
        )
        
        let initialContentState = WalkActivityAttributes.ContentState()
        
        do {
            let activity = try Activity<WalkActivityAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            print("✅ [LiveActivityService] Live Activity started with ID: \(activity.id)")
            return true
            
        } catch {
            print("❌ [LiveActivityService] Failed to start Live Activity: \(error)")
            return false
        }
    }
    
    // MARK: - Update Activity
    func updateWalkActivity(
        duration: TimeInterval,
        humanSteps: Int,
        dogSteps: Int,
        distance: Double,
        pace: String
    ) async {
        guard let activity = currentActivity else {
            print("⚠️ [LiveActivityService] No active activity to update")
            return
        }
        
        let updatedContentState = WalkActivityAttributes.ContentState(
            duration: duration,
            humanSteps: humanSteps,
            dogSteps: dogSteps,
            distance: distance,
            pace: pace
        )
        
        do {
            await activity.update(using: updatedContentState)
            print("🔴 [LiveActivityService] Activity updated: \(dogSteps) steps, \(updatedContentState.formattedDuration)")
        } catch {
            print("❌ [LiveActivityService] Failed to update activity: \(error)")
        }
    }
    
    // MARK: - End Activity
    func endWalkActivity(finalSteps: Int, finalDuration: String) async {
        guard let activity = currentActivity else {
            print("⚠️ [LiveActivityService] No active activity to end")
            return
        }
        
        print("🔴 [LiveActivityService] Ending Live Activity")
        
        let finalContentState = WalkActivityAttributes.ContentState(
            duration: activity.contentState.duration,
            humanSteps: activity.contentState.humanSteps,
            dogSteps: finalSteps,
            distance: activity.contentState.distance,
            pace: activity.contentState.pace
        )
        
        do {
            await activity.end(using: finalContentState, dismissalPolicy: .default)
            
            currentActivity = nil
            isActivityActive = false
            
            print("✅ [LiveActivityService] Live Activity ended")
            
        } catch {
            print("❌ [LiveActivityService] Failed to end activity: \(error)")
        }
    }
    
    // MARK: - Force End Activity
    func forceEndActivity() async {
        guard let activity = currentActivity else { return }
        
        print("🔴 [LiveActivityService] Force ending Live Activity")
        
        do {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
            isActivityActive = false
        } catch {
            print("❌ [LiveActivityService] Failed to force end activity: \(error)")
        }
    }
    
    // MARK: - Activity State Monitoring
    func startMonitoringActivity() {
        guard currentActivity != nil else { return }
        
        // Monitor activity state changes - simplified approach
        print("🔴 [LiveActivityService] Started monitoring activity state")
    }
    
    // MARK: - Utility Methods
    func hasActiveActivity() -> Bool {
        return currentActivity != nil && isActivityActive
    }
    
    func getActivityId() -> String? {
        return currentActivity?.id
    }
    
    func getActivitySummary() -> String {
        guard let activity = currentActivity else {
            return "No active Live Activity"
        }
        
        let state = activity.contentState
        return """
        🔴 Active Live Activity
        Dog: \(activity.attributes.dogName)
        Duration: \(state.formattedDuration)
        Steps: \(state.dogSteps)
        Distance: \(state.formattedDistance)
        """
    }
} 