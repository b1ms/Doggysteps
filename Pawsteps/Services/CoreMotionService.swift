//
//  CoreMotionService.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation
import CoreMotion
import Combine
import UIKit

// MARK: - Core Motion Service Protocol
protocol CoreMotionServiceProtocol {
    func startStepCounting() async -> Result<Void, CoreMotionError>
    func stopStepCounting()
    func getTodaysSteps() -> Int
    func getTodaysDistance() -> Double
    func isStepCountingAvailable() -> Bool
    func requestMotionPermissions() async -> Bool
    
    // Session management
    func startWalkSession() async -> Result<Void, CoreMotionError>
    func stopWalkSession() -> WalkSessionData?
    func getCurrentSessionData() -> WalkSessionData?
    func isSessionActive() -> Bool
}

// MARK: - Walk Session Data Model
struct WalkSessionData {
    let steps: Int
    let distance: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date?
    
    init(steps: Int, distance: Double, duration: TimeInterval, startTime: Date, endTime: Date? = nil) {
        self.steps = steps
        self.distance = distance
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Core Motion Error Types
enum CoreMotionError: LocalizedError {
    case notAvailable
    case permissionDenied
    case dataNotAvailable
    case sessionAlreadyActive
    case noActiveSession
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Step counting is not available on this device"
        case .permissionDenied:
            return "Motion permission was denied"
        case .dataNotAvailable:
            return "Step data is not available"
        case .sessionAlreadyActive:
            return "A walk session is already active"
        case .noActiveSession:
            return "No active walk session found"
        case .unknownError(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Step Data Model
struct StepCountData {
    let steps: Int
    let distance: Double
    let timestamp: Date
    
    init(steps: Int, distance: Double, timestamp: Date = Date()) {
        self.steps = steps
        self.distance = distance
        self.timestamp = timestamp
    }
}

// MARK: - Tracking Mode
enum TrackingMode {
    case daily
    case session
    case inactive
}

// MARK: - Core Motion Service Implementation
class CoreMotionService: CoreMotionServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published private(set) var currentSteps: Int = 0
    @Published private(set) var currentDistance: Double = 0
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var lastUpdateTime: Date?
    
    // Session tracking properties
    @Published private(set) var sessionSteps: Int = 0
    @Published private(set) var sessionDistance: Double = 0
    @Published private(set) var sessionDuration: TimeInterval = 0
    @Published private(set) var sessionStartTime: Date?
    
    private let pedometer = CMPedometer()
    private var stepCountingStartDate: Date?
    private var sessionStartDate: Date?
    private let calendar = Calendar.current
    
    // Tracking state management
    private var currentMode: TrackingMode = .inactive
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // App lifecycle observation
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        print("📱 [CoreMotionService] Initializing Core Motion service")
        print("📱 [CoreMotionService] Step counting available: \(CMPedometer.isStepCountingAvailable())")
        print("📱 [CoreMotionService] Motion permission status: \(CMPedometer.authorizationStatus().rawValue)")
        
        setupAppLifecycleObservers()
    }
    
    deinit {
        endBackgroundTask()
        pedometer.stopUpdates()
    }
    
    // MARK: - App Lifecycle Management
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleAppWillTerminate()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppDidEnterBackground() {
        print("📱 [CoreMotionService] App entering background")
        
        // Only request background time for active sessions
        if currentMode == .session {
            beginBackgroundTask()
        }
    }
    
    private func handleAppWillEnterForeground() {
        print("📱 [CoreMotionService] App entering foreground")
        endBackgroundTask()
        
        // Refresh data when returning to foreground
        Task {
            await refreshCurrentData()
        }
    }
    
    private func handleAppWillTerminate() {
        print("📱 [CoreMotionService] App terminating")
        pedometer.stopUpdates()
        endBackgroundTask()
    }
    
    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "StepTracking") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // MARK: - Public Methods
    func isStepCountingAvailable() -> Bool {
        return CMPedometer.isStepCountingAvailable()
    }
    
    func requestMotionPermissions() async -> Bool {
        print("📱 [CoreMotionService] Requesting motion permissions")
        
        guard isStepCountingAvailable() else {
            print("❌ [CoreMotionService] Step counting not available on this device")
            return false
        }
        
        let authStatus = CMPedometer.authorizationStatus()
        print("📱 [CoreMotionService] Current authorization status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .authorized:
            print("✅ [CoreMotionService] Motion permissions already granted")
            return true
        case .denied, .restricted:
            print("❌ [CoreMotionService] Motion permissions denied or restricted")
            return false
        case .notDetermined:
            // Request permission by starting pedometer updates
            return await withCheckedContinuation { continuation in
                print("📱 [CoreMotionService] Starting permission request...")
                let startDate = Date()
                var hasResumed = false
                
                pedometer.startUpdates(from: startDate) { [weak self] data, error in
                    print("📱 [CoreMotionService] Permission callback received")
                    
                    // Stop updates immediately
                    self?.pedometer.stopUpdates()
                    
                    guard !hasResumed else {
                        print("📱 [CoreMotionService] Already resumed, ignoring")
                        return
                    }
                    hasResumed = true
                    
                    // Check if we have permission now
                    let newStatus = CMPedometer.authorizationStatus()
                    print("📱 [CoreMotionService] New authorization status: \(newStatus.rawValue)")
                    
                    if newStatus == .authorized {
                        print("✅ [CoreMotionService] Motion permissions granted")
                        continuation.resume(returning: true)
                    } else {
                        print("❌ [CoreMotionService] Permission request failed or denied")
                        continuation.resume(returning: false)
                    }
                }
                
                // Add a timeout to prevent hanging
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                    guard !hasResumed else { return }
                    hasResumed = true
                    print("⚠️ [CoreMotionService] Permission request timeout")
                    continuation.resume(returning: false)
                }
            }
        @unknown default:
            print("⚠️ [CoreMotionService] Unknown authorization status")
            return false
        }
    }
    
    func startStepCounting() async -> Result<Void, CoreMotionError> {
        print("📱 [CoreMotionService] Starting daily step counting")
        
        guard isStepCountingAvailable() else {
            print("❌ [CoreMotionService] Step counting not available")
            return .failure(.notAvailable)
        }
        
        // Don't start daily tracking if session is active
        if currentMode == .session {
            print("⚠️ [CoreMotionService] Session is active, daily tracking will resume after session")
            return .success(())
        }
        
        let hasPermission = await requestMotionPermissions()
        guard hasPermission else {
            print("❌ [CoreMotionService] Motion permissions not granted")
            return .failure(.permissionDenied)
        }
        
        // Stop any existing updates first
        pedometer.stopUpdates()
        
        // Start counting from the beginning of today
        let startOfToday = calendar.startOfDay(for: Date())
        stepCountingStartDate = startOfToday
        currentMode = .daily
        
        pedometer.startUpdates(from: startOfToday) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [CoreMotionService] Step counting error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("⚠️ [CoreMotionService] No pedometer data received")
                    return
                }
                
                // Only update if we're in daily mode
                guard self.currentMode == .daily else { return }
                
                // Update current step count and distance
                self.currentSteps = data.numberOfSteps.intValue
                self.currentDistance = data.distance?.doubleValue ?? 0
                self.lastUpdateTime = Date()
                self.isTracking = true
                
                print("📱 [CoreMotionService] Daily step update: \(self.currentSteps) steps, \(String(format: "%.2f", self.currentDistance)) meters")
            }
        }
        
        print("✅ [CoreMotionService] Daily step counting started from today's beginning")
        return .success(())
    }
    
    func stopStepCounting() {
        print("📱 [CoreMotionService] Stopping step counting")
        
        pedometer.stopUpdates()
        isTracking = false
        stepCountingStartDate = nil
        currentMode = .inactive
        
        print("✅ [CoreMotionService] Step counting stopped")
    }
    
    func getTodaysSteps() -> Int {
        print("📱 [CoreMotionService] Getting today's steps: \(currentSteps)")
        return currentSteps
    }
    
    func getTodaysDistance() -> Double {
        print("📱 [CoreMotionService] Getting today's distance: \(String(format: "%.2f", currentDistance)) meters")
        return currentDistance
    }
    
    // MARK: - Session Management
    func startWalkSession() async -> Result<Void, CoreMotionError> {
        print("📱 [CoreMotionService] Starting walk session")
        
        guard isStepCountingAvailable() else {
            print("❌ [CoreMotionService] Step counting not available")
            return .failure(.notAvailable)
        }
        
        guard currentMode != .session else {
            print("❌ [CoreMotionService] Walk session already active")
            return .failure(.sessionAlreadyActive)
        }
        
        let hasPermission = await requestMotionPermissions()
        guard hasPermission else {
            print("❌ [CoreMotionService] Motion permissions not granted")
            return .failure(.permissionDenied)
        }
        
        // Stop daily tracking
        pedometer.stopUpdates()
        
        // Reset session data
        sessionSteps = 0
        sessionDistance = 0
        sessionDuration = 0
        sessionStartTime = Date()
        sessionStartDate = Date()
        currentMode = .session
        
        // Start session tracking
        pedometer.startUpdates(from: sessionStartDate!) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [CoreMotionService] Session tracking error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("⚠️ [CoreMotionService] No session data received")
                    return
                }
                
                // Only update if we're in session mode
                guard self.currentMode == .session else { return }
                
                // Update session data
                self.sessionSteps = data.numberOfSteps.intValue
                self.sessionDistance = data.distance?.doubleValue ?? 0
                
                if let startTime = self.sessionStartTime {
                    self.sessionDuration = Date().timeIntervalSince(startTime)
                }
                
                self.lastUpdateTime = Date()
                
                // Debug logging every 10 seconds
                if Int(self.sessionDuration) % 10 == 0 {
                    print("📱 [CoreMotionService] Session update: \(self.sessionSteps) steps, \(String(format: "%.2f", self.sessionDistance)) meters, \(String(format: "%.0f", self.sessionDuration))s")
                }
            }
        }
        
        print("✅ [CoreMotionService] Walk session started")
        return .success(())
    }
    
    func stopWalkSession() -> WalkSessionData? {
        print("📱 [CoreMotionService] Stopping walk session")
        
        guard currentMode == .session else {
            print("❌ [CoreMotionService] No active session to stop")
            return nil
        }
        
        guard let startTime = sessionStartTime else {
            print("❌ [CoreMotionService] Session start time not found")
            return nil
        }
        
        // Stop pedometer updates
        pedometer.stopUpdates()
        
        // Create session data
        let sessionData = WalkSessionData(
            steps: sessionSteps,
            distance: sessionDistance,
            duration: sessionDuration,
            startTime: startTime,
            endTime: Date()
        )
        
        // Reset session state
        sessionSteps = 0
        sessionDistance = 0
        sessionDuration = 0
        sessionStartTime = nil
        sessionStartDate = nil
        currentMode = .inactive
        
        print("✅ [CoreMotionService] Walk session stopped: \(sessionData.steps) steps in \(String(format: "%.0f", sessionData.duration))s")
        
        // Restart daily tracking automatically
        Task {
            let _ = await startStepCounting()
        }
        
        return sessionData
    }
    
    func getCurrentSessionData() -> WalkSessionData? {
        guard currentMode == .session,
              let startTime = sessionStartTime else {
            return nil
        }
        
        return WalkSessionData(
            steps: sessionSteps,
            distance: sessionDistance,
            duration: sessionDuration,
            startTime: startTime,
            endTime: nil
        )
    }
    
    func isSessionActive() -> Bool {
        return currentMode == .session
    }
    
    // MARK: - Historical Data Methods
    func getStepsForDate(_ date: Date) async -> Result<StepCountData, CoreMotionError> {
        print("📱 [CoreMotionService] Getting steps for date: \(date)")
        
        guard isStepCountingAvailable() else {
            return .failure(.notAvailable)
        }
        
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: startOfDay, to: endOfDay) { data, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [CoreMotionService] Failed to get steps for date: \(error.localizedDescription)")
                        continuation.resume(returning: .failure(.unknownError(error)))
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ [CoreMotionService] No data available for date")
                        continuation.resume(returning: .failure(.dataNotAvailable))
                        return
                    }
                    
                    let stepData = StepCountData(
                        steps: data.numberOfSteps.intValue,
                        distance: data.distance?.doubleValue ?? 0,
                        timestamp: date
                    )
                    
                    print("✅ [CoreMotionService] Retrieved \(stepData.steps) steps for \(date)")
                    continuation.resume(returning: .success(stepData))
                }
            }
        }
    }
    
    // MARK: - Session Tracking Methods
    func getStepsForSession(startTime: Date, endTime: Date) async -> Result<StepCountData, CoreMotionError> {
        print("📱 [CoreMotionService] Getting steps for session: \(startTime) to \(endTime)")
        
        guard isStepCountingAvailable() else {
            return .failure(.notAvailable)
        }
        
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: startTime, to: endTime) { data, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [CoreMotionService] Failed to get session steps: \(error.localizedDescription)")
                        continuation.resume(returning: .failure(.unknownError(error)))
                        return
                    }
                    
                    guard let data = data else {
                        print("❌ [CoreMotionService] No session data available")
                        continuation.resume(returning: .failure(.dataNotAvailable))
                        return
                    }
                    
                    let stepData = StepCountData(
                        steps: data.numberOfSteps.intValue,
                        distance: data.distance?.doubleValue ?? 0,
                        timestamp: endTime
                    )
                    
                    print("✅ [CoreMotionService] Retrieved \(stepData.steps) steps for session")
                    continuation.resume(returning: .success(stepData))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func refreshCurrentData() async {
        guard currentMode == .daily else { return }
        
        // Refresh today's data
        let result = await getStepsForDate(Date())
        switch result {
        case .success(let data):
            currentSteps = data.steps
            currentDistance = data.distance
            lastUpdateTime = Date()
        case .failure(let error):
            print("❌ [CoreMotionService] Failed to refresh data: \(error)")
        }
    }
}

// MARK: - Singleton Access
extension CoreMotionService {
    static let shared = CoreMotionService()
} 