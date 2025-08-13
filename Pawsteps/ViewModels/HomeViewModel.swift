//
//  HomeViewModel.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation
import SwiftUI
import Combine
import CoreMotion
import UIKit

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var todaysStepData: StepData?
    @Published private(set) var weeklyStepData: [StepData] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: HomeError?
    @Published private(set) var dogProfile: DogProfile?
    @Published private(set) var motionAuthorized = false
    @Published private(set) var lastUpdateTime: Date?
    
    // Walk session management
    @Published private(set) var completedWalkSessions: [WalkSession] = []
    @Published private(set) var todaysWalkSessions: [WalkSession] = []
    
    // UI State
    @Published var showingSettings = false
    @Published var showingProfile = false
    @Published var showingMotionPermissions = false
    
    // MARK: - Dependencies
    private let coreMotionService = CoreMotionService.shared
    private let stepEstimationService = StepEstimationService.shared
    private let persistenceController = PersistenceController.shared
    private let userDefaults = UserDefaults.standard
    
    // Date tracking for midnight reset
    private var cancellables = Set<AnyCancellable>()
    private var currentDate = Calendar.current.startOfDay(for: Date())
    
    // MARK: - Computed Properties
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = dogProfile?.name ?? "Your Dog"
        
        switch hour {
        case 5..<12:
            return "Good morning! Ready for \(name)'s walk?"
        case 12..<17:
            return "Good afternoon! How's \(name) doing?"
        case 17..<21:
            return "Good evening! Time for \(name)'s evening stroll?"
        default:
            return "Good night! \(name) looks tired."
        }
    }
    
    var todaysProgress: Double {
        guard let stepData = todaysStepData else { return 0 }
        return stepData.goalProgress
    }
    
    var todaysProgressPercentage: Int {
        return Int(todaysProgress * 100)
    }
    
    var stepsSummary: String {
        guard let stepData = todaysStepData else { return "No data" }
        return "\(stepData.estimatedDogSteps) steps today"
    }
    
    var distanceSummary: String {
        guard let stepData = todaysStepData else { return "0 km" }
        return String(format: "%.1f km walked", stepData.distanceInKilometers)
    }
    
    var weeklyAverage: Int {
        guard !weeklyStepData.isEmpty else { return 0 }
        let total = weeklyStepData.reduce(0) { $0 + $1.estimatedDogSteps }
        return total / weeklyStepData.count
    }
    
    var activityInsights: [EstimationInsight] {
        guard let profile = dogProfile else { return [] }
        return stepEstimationService.getEstimationInsights(for: profile.breedName)
    }
    
    var activityTrend: ActivityTrend {
        return stepEstimationService.getActivityTrend()
    }
    
    var todaysActivitySummary: String {
        guard let todaysData = todaysStepData else { return "No activity data available" }
        return todaysData.detailedSummary
    }
    
    var weeklyStepTrend: String {
        guard weeklyStepData.count >= 2 else { return "Not enough data" }
        
        let recent = weeklyStepData.prefix(3)
        let older = weeklyStepData.suffix(3)
        
        let recentAvg = recent.reduce(0) { $0 + $1.estimatedDogSteps } / recent.count
        let olderAvg = older.reduce(0) { $0 + $1.estimatedDogSteps } / older.count
        
        if recentAvg > olderAvg + 500 {
            return "📈 Activity is trending up!"
        } else if recentAvg < olderAvg - 500 {
            return "📉 Activity has decreased recently"
        } else {
            return "➡️ Activity levels are stable"
        }
    }
    
    var motionStatusSummary: String {
        guard let todaysData = todaysStepData else { return "No data available" }
        
        var summary = "🐕 "
        
        if todaysData.isGoalMet {
            summary += "Excellent! Goal achieved today. "
        } else if todaysData.goalProgressPercentage >= 80 {
            summary += "Almost there! Just a bit more to reach the goal. "
        } else if todaysData.goalProgressPercentage >= 50 {
            summary += "Good progress, but more activity would be beneficial. "
        } else {
            summary += "Low activity today - consider a longer walk! "
        }
        
        summary += todaysData.goalStatusDescription
        
        return summary
    }
    
    var canRefreshData: Bool {
        return motionAuthorized && !isLoading
    }
    
    var currentStreak: Int {
        return calculateCurrentStreak()
    }
    
    // MARK: - Initialization
    init() {
        print("🏠 [HomeViewModel] Initializing home view model")
        setupInitialState()
        setupDateChangeDetection()
        loadWalkSessions()
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    func refreshData() async {
        print("🏠 [HomeViewModel] Refreshing data from walk sessions only")
        
        isLoading = true
        error = nil
        
        // Ensure Core Motion is authorized
        if !motionAuthorized && coreMotionService.isStepCountingAvailable() {
            print("🏠 [HomeViewModel] Core Motion not authorized but available, requesting permissions")
            await requestMotionPermissions()
        }
        
        // Reload walk sessions and update data
        loadWalkSessions()
        updateTodaysDataFromWalkSessions()
        await loadWeeklyData()
        
        lastUpdateTime = Date()
        isLoading = false
        
        print("✅ [HomeViewModel] Data refresh completed from walk sessions only")
    }
    
    func requestMotionPermissions() async {
        print("🏠 [HomeViewModel] Requesting Core Motion permissions")
        
        let granted = await coreMotionService.requestMotionPermissions()
        motionAuthorized = granted
        
        if granted {
            print("✅ [HomeViewModel] Core Motion authorized, starting step counting")
            let result = await coreMotionService.startStepCounting()
            switch result {
            case .success:
                print("✅ [HomeViewModel] Step counting started successfully")
                await refreshData()
            case .failure(let error):
                print("❌ [HomeViewModel] Failed to start step counting: \(error)")
                self.error = .motionDenied
            }
        } else {
            print("❌ [HomeViewModel] Core Motion authorization denied")
            error = .motionDenied
        }
    }
    
    func loadDogProfile() {
        print("🏠 [HomeViewModel] Loading dog profile")
        
        if let profile = persistenceController.currentDogProfile {
            dogProfile = profile
            print("✅ [HomeViewModel] Loaded dog profile: \(profile.name) (\(profile.breedName), \(profile.bodyCondition.rawValue))")
        } else {
            print("⚠️ [HomeViewModel] No dog profile found")
        }
    }
    
    func saveDogProfile(_ profile: DogProfile) {
        print("🏠 [HomeViewModel] Saving dog profile")
        
        if persistenceController.saveDogProfile(profile) {
            dogProfile = profile
            print("✅ [HomeViewModel] Dog profile saved successfully")
        } else {
            print("❌ [HomeViewModel] Failed to save dog profile")
        }
    }
    
    func deleteProfile() {
        print("🏠 [HomeViewModel] Deleting dog profile")
        
        if persistenceController.deleteDogProfile() {
            dogProfile = nil
            print("✅ [HomeViewModel] Dog profile deleted successfully")
        } else {
            print("❌ [HomeViewModel] Failed to delete dog profile")
        }
    }
    

    
    func clearError() {
        error = nil
    }
    
    func refreshMotionStatus() {
        // Check if we have motion permissions by checking authorization status
        motionAuthorized = CMPedometer.authorizationStatus() == .authorized
    }
    
    // MARK: - Private Methods
    private func setupInitialState() {
        print("🏠 [HomeViewModel] Setting up initial state")
        
        // Load dog profile
        loadDogProfile()
        
        // Check Core Motion availability
        if coreMotionService.isStepCountingAvailable() {
            print("📱 [HomeViewModel] Core Motion is available on this device")
            // Don't automatically request permissions on init - let user trigger it
            motionAuthorized = CMPedometer.authorizationStatus() == .authorized
        } else {
            print("❌ [HomeViewModel] Core Motion is NOT available on this device")
            error = .motionNotAvailable
        }
    }
    
    private func setupDateChangeDetection() {
        print("🏠 [HomeViewModel] Setting up date change detection")
        
        // Listen for day changed notifications
        NotificationCenter.default
            .publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleDateChange()
                }
            }
            .store(in: &cancellables)
        
        // Also listen for app becoming active (in case user opens app after midnight)
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.checkForDateChange()
                }
            }
            .store(in: &cancellables)
        
        print("✅ [HomeViewModel] Date change detection setup complete")
    }
    
    private func handleDateChange() async {
        print("🕛 [HomeViewModel] Date changed - refreshing today's data")
        currentDate = Calendar.current.startOfDay(for: Date())
        
        // Refresh today's data which will now show 0 steps for the new day
        await refreshData()
        
        print("✅ [HomeViewModel] Data refreshed for new day")
    }
    
    private func checkForDateChange() async {
        let todayStartOfDay = Calendar.current.startOfDay(for: Date())
        
        if todayStartOfDay != currentDate {
            print("🕛 [HomeViewModel] App became active - detected date change from \(currentDate) to \(todayStartOfDay)")
            await handleDateChange()
        }
    }
    
    private func loadInitialData() async {
        print("🏠 [HomeViewModel] Loading initial data from walk sessions only")
        
        // Load only from walk sessions - no backup estimation
        loadWalkSessions()
        updateTodaysDataFromWalkSessions()
        await loadWeeklyData()
        
        print("✅ [HomeViewModel] Initial data loaded from walk sessions")
    }
    
    private func loadWeeklyData() async {
        print("🏠 [HomeViewModel] Loading weekly data from walk sessions")
        
        guard let profile = dogProfile else {
            print("⚠️ [HomeViewModel] No dog profile for weekly data - skipping")
            weeklyStepData = []
            return
        }
        
        var weeklyData: [StepData] = []
        let calendar = Calendar.current
        
        // Process each day for the past 7 days
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // Get walk sessions for this day
            let daySessions = completedWalkSessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: date)
            }
            
            // Only create step data if there are actual walk sessions
            if !daySessions.isEmpty {
                let totalHumanSteps = daySessions.reduce(0) { $0 + $1.humanSteps }
                let totalDogSteps = daySessions.reduce(0) { $0 + $1.estimatedDogSteps }
                let totalDistance = daySessions.reduce(0) { $0 + $1.distanceInMeters }
                
                let dailyGoal = stepEstimationService.calculateDailyGoal(
                    for: profile.breedName,
                    bodyCondition: profile.bodyCondition
                )
                
                let stepData = StepData(
                    date: date,
                    humanSteps: totalHumanSteps,
                    estimatedDogSteps: totalDogSteps,
                    distanceInMeters: totalDistance,
                    breedName: profile.breedName,
                    breedMultiplier: getBreedMultiplier(for: profile.breedName),
                    confidence: "High", // Walk sessions have high confidence
                    activityLevel: totalDogSteps >= dailyGoal ? "High" : "Moderate",
                    goalSteps: dailyGoal
                )
                
                weeklyData.append(stepData)
            }
        }
        
        weeklyStepData = weeklyData.sorted { $0.date > $1.date }
        print("✅ [HomeViewModel] Weekly data loaded from walk sessions: \(weeklyData.count) days")
    }
    
    // MARK: - Walk Session Management
    func saveCompletedWalkSession(_ session: WalkSession) {
        print("🏠 [HomeViewModel] Saving completed walk session: \(session.estimatedDogSteps) steps")
        
        completedWalkSessions.append(session)
        
        // Also add to today's sessions if it's from today
        if Calendar.current.isDateInToday(session.startTime) {
            todaysWalkSessions.append(session)
        }
        
        // Keep only recent sessions (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        completedWalkSessions = completedWalkSessions.filter { $0.startTime >= thirtyDaysAgo }
        
        // Save to persistence
        persistenceController.saveWalkSessions(completedWalkSessions)
        
        // Update today's step data based on walk sessions only
        updateTodaysDataFromWalkSessions()
        
        print("✅ [HomeViewModel] Walk session saved. Total sessions: \(completedWalkSessions.count)")
    }
    
    func getBreedMultiplier(for breedName: String) -> Double {
        return stepEstimationService.getBreedMultiplier(for: breedName)
    }
    
    private func loadWalkSessions() {
        completedWalkSessions = persistenceController.loadWalkSessions()
        
        // Filter today's sessions
        todaysWalkSessions = completedWalkSessions.filter { 
            Calendar.current.isDateInToday($0.startTime) 
        }
        
        print("🏠 [HomeViewModel] Loaded \(completedWalkSessions.count) walk sessions (\(todaysWalkSessions.count) today)")
    }
    
    private func updateTodaysDataFromWalkSessions() {
        guard let profile = dogProfile else { return }
        
        let todaySessions = completedWalkSessions.filter { 
            Calendar.current.isDateInToday($0.startTime) 
        }
        
        if !todaySessions.isEmpty {
            let totalHumanSteps = todaySessions.reduce(0) { $0 + $1.humanSteps }
            let totalDogSteps = todaySessions.reduce(0) { $0 + $1.estimatedDogSteps }
            let totalDistance = todaySessions.reduce(0) { $0 + $1.distanceInMeters }
            
                            let dailyGoal = stepEstimationService.calculateDailyGoal(
                    for: profile.breedName,
                    bodyCondition: profile.bodyCondition
                )
            
            todaysStepData = StepData(
                date: Date(),
                humanSteps: totalHumanSteps,
                estimatedDogSteps: totalDogSteps,
                distanceInMeters: totalDistance,
                breedName: profile.breedName,
                breedMultiplier: getBreedMultiplier(for: profile.breedName),
                confidence: "High", // Walk sessions have high confidence
                activityLevel: totalDogSteps >= dailyGoal ? "High" : "Moderate",
                goalSteps: dailyGoal
            )
            
            print("🏠 [HomeViewModel] Updated today's data from \(todaySessions.count) walk sessions")
        } else {
            // No walk sessions today - no step data (no backup estimation)
            todaysStepData = nil
            print("🏠 [HomeViewModel] No walk sessions today - cleared step data")
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        guard !completedWalkSessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Start from today and work backwards
        while true {
            // Check if there's at least one walk session on this date
            let hasWalkOnDate = completedWalkSessions.contains { walkSession in
                calendar.isDate(walkSession.startTime, inSameDayAs: currentDate)
            }
            
            if hasWalkOnDate {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // If we're checking today and there's no walk, streak is 0
                // If we're checking a past day and there's no walk, streak stops here
                break
            }
            
            // Safety check to prevent infinite loop (max 365 days)
            if streak >= 365 {
                break
            }
        }
        
        return streak
    }
    
    deinit {
        cancellables.removeAll()
        print("🏠 [HomeViewModel] HomeViewModel deinitialized")
    }
}

// MARK: - Home Error Types
enum HomeError: LocalizedError {
    case motionNotAvailable
    case motionDenied
    case noProfile
    case dataLoadFailed
    case walkSessionFailed
    
    var errorDescription: String? {
        switch self {
        case .motionNotAvailable:
            return "Step counting is not available on this device"
        case .motionDenied:
            return "Motion permission is required to track steps"
        case .noProfile:
            return "Please create a dog profile first"
        case .dataLoadFailed:
            return "Failed to load activity data"
        case .walkSessionFailed:
            return "Failed to track walk session"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .motionNotAvailable:
            return "This device doesn't support step counting"
        case .motionDenied:
            return "Please enable Motion permissions in Settings"
        case .noProfile:
            return "Tap the profile icon to create a dog profile"
        case .dataLoadFailed:
            return "Try refreshing the data"
        case .walkSessionFailed:
            return "Try starting the walk session again"
        }
    }
} 