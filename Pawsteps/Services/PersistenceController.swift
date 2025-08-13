//
//  PersistenceController.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation
import Combine

// MARK: - Persistence Controller Protocol
@MainActor
protocol PersistenceControllerProtocol {
    func saveDogProfile(_ profile: DogProfile) -> Bool
    func loadDogProfile() -> DogProfile?
    func deleteDogProfile() -> Bool
    func saveAppSettings(_ settings: AppSettings) -> Bool
    func loadAppSettings() -> AppSettings
    func saveStepDataHistory(_ stepData: [StepData]) -> Bool
    func loadStepDataHistory() -> [StepData]
    func clearAllData() -> Bool
    func saveWalkSessions(_ sessions: [WalkSession]) -> Bool
    func loadWalkSessions() -> [WalkSession]
}

// MARK: - App Settings Model
struct AppSettings: Codable {
    var motionEnabled: Bool
    var preferredUnits: MeasurementUnit
    var dailyGoalCustomization: Bool
    var onboardingCompleted: Bool
    var appVersion: String
    var lastSyncDate: Date?
    
    enum MeasurementUnit: String, Codable, CaseIterable {
        case metric = "metric"
        case imperial = "imperial"
        
        var displayName: String {
            switch self {
            case .metric: return "Metric (km/kg)"
            case .imperial: return "Imperial (mi/lb)"
            }
        }
    }
    
    static let `default` = AppSettings(
        motionEnabled: false,
        preferredUnits: .metric,
        dailyGoalCustomization: false,
        onboardingCompleted: false,
        appVersion: "1.0.0",
        lastSyncDate: nil
    )
}

// Note: DogProfile already conforms to Codable in DogProfile.swift

// MARK: - Persistence Controller Implementation
@MainActor
class PersistenceController: PersistenceControllerProtocol, ObservableObject {
    
    // MARK: - Properties
    static let shared = PersistenceController()
    
    private let userDefaults = UserDefaults.standard
    @Published private(set) var currentDogProfile: DogProfile?
    @Published private(set) var appSettings: AppSettings
    
    // UserDefaults Keys
    private enum Keys {
        static let dogProfile = "DogProfile"
        static let appSettings = "AppSettings"
        static let stepDataHistory = "StepDataHistory"
        static let onboardingCompleted = "OnboardingCompleted"
        static let lastAppVersion = "LastAppVersion"
        static let walkSessions = "WalkSessions"
    }
    
    // MARK: - Initialization
    private init() {
        print("💾 [PersistenceController] Initializing persistence controller")
        
        // Initialize with defaults first
        self.appSettings = AppSettings.default
        self.currentDogProfile = nil
        
        // Then load saved data
        self.appSettings = loadAppSettings()
        self.currentDogProfile = loadDogProfile()
        
        print("💾 [PersistenceController] Loaded settings: \(appSettings)")
        if let profile = currentDogProfile {
            print("💾 [PersistenceController] Loaded dog profile: \(profile.name) (\(profile.breedName))")
        } else {
            print("💾 [PersistenceController] No saved dog profile found")
        }
    }
    
    // MARK: - Dog Profile Management
    func saveDogProfile(_ profile: DogProfile) -> Bool {
        print("💾 [PersistenceController] Saving dog profile: \(profile.name)")
        
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: Keys.dogProfile)
            
            // Update in-memory profile
            currentDogProfile = profile
            
            // Update last sync date
            updateLastSyncDate()
            
            print("✅ [PersistenceController] Dog profile saved successfully")
            return true
            
        } catch {
            print("❌ [PersistenceController] Failed to save dog profile: \(error)")
            return false
        }
    }
    
    func loadDogProfile() -> DogProfile? {
        print("💾 [PersistenceController] Loading dog profile")
        
        guard let data = userDefaults.data(forKey: Keys.dogProfile) else {
            print("💾 [PersistenceController] No dog profile data found")
            return nil
        }
        
        do {
            let profile = try JSONDecoder().decode(DogProfile.self, from: data)
            print("✅ [PersistenceController] Dog profile loaded: \(profile.name)")
            return profile
            
        } catch {
            print("❌ [PersistenceController] Failed to load dog profile: \(error)")
            return nil
        }
    }
    
    func deleteDogProfile() -> Bool {
        print("💾 [PersistenceController] Deleting dog profile")
        
        userDefaults.removeObject(forKey: Keys.dogProfile)
        currentDogProfile = nil
        
        print("✅ [PersistenceController] Dog profile deleted")
        return true
    }
    
    // MARK: - App Settings Management
    func saveAppSettings(_ settings: AppSettings) -> Bool {
        print("💾 [PersistenceController] Saving app settings")
        
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: Keys.appSettings)
            
            // Update in-memory settings
            appSettings = settings
            
            print("✅ [PersistenceController] App settings saved successfully")
            return true
            
        } catch {
            print("❌ [PersistenceController] Failed to save app settings: \(error)")
            return false
        }
    }
    
    func loadAppSettings() -> AppSettings {
        print("💾 [PersistenceController] Loading app settings")
        
        guard let data = userDefaults.data(forKey: Keys.appSettings) else {
            print("💾 [PersistenceController] No app settings found, using defaults")
            return AppSettings.default
        }
        
        do {
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            print("✅ [PersistenceController] App settings loaded")
            return settings
            
        } catch {
            print("❌ [PersistenceController] Failed to load app settings: \(error), using defaults")
            return AppSettings.default
        }
    }
    
    // MARK: - Step Data Management
    func saveStepDataHistory(_ stepData: [StepData]) -> Bool {
        print("💾 [PersistenceController] Saving step data history: \(stepData.count) entries")
        
        do {
            let data = try JSONEncoder().encode(stepData)
            userDefaults.set(data, forKey: Keys.stepDataHistory)
            
            updateLastSyncDate()
            
            print("✅ [PersistenceController] Step data history saved successfully")
            return true
            
        } catch {
            print("❌ [PersistenceController] Failed to save step data history: \(error)")
            return false
        }
    }
    
    func loadStepDataHistory() -> [StepData] {
        print("💾 [PersistenceController] Loading step data history")
        
        guard let data = userDefaults.data(forKey: Keys.stepDataHistory) else {
            print("💾 [PersistenceController] No step data history found")
            return []
        }
        
        do {
            let stepData = try JSONDecoder().decode([StepData].self, from: data)
            print("✅ [PersistenceController] Step data history loaded: \(stepData.count) entries")
            return stepData
            
        } catch {
            print("❌ [PersistenceController] Failed to load step data history: \(error)")
            return []
        }
    }
    
    // MARK: - Walk Session Management
    func saveWalkSessions(_ sessions: [WalkSession]) -> Bool {
        print("💾 [PersistenceController] Saving walk sessions: \(sessions.count) entries")
        
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: Keys.walkSessions)
            
            updateLastSyncDate()
            
            print("✅ [PersistenceController] Walk sessions saved successfully")
            return true
            
        } catch {
            print("❌ [PersistenceController] Failed to save walk sessions: \(error)")
            return false
        }
    }
    
    func loadWalkSessions() -> [WalkSession] {
        print("💾 [PersistenceController] Loading walk sessions")
        
        guard let data = userDefaults.data(forKey: Keys.walkSessions) else {
            print("💾 [PersistenceController] No walk sessions found")
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([WalkSession].self, from: data)
            print("✅ [PersistenceController] Walk sessions loaded: \(sessions.count) entries")
            return sessions
            
        } catch {
            print("❌ [PersistenceController] Failed to load walk sessions: \(error)")
            return []
        }
    }
    
    // MARK: - Utility Methods
    func clearAllData() -> Bool {
        print("💾 [PersistenceController] Clearing all saved data")
        
        userDefaults.removeObject(forKey: Keys.dogProfile)
        userDefaults.removeObject(forKey: Keys.stepDataHistory)
        userDefaults.removeObject(forKey: Keys.onboardingCompleted)
        
        // Reset to default settings but keep app version
        let currentVersion = appSettings.appVersion
        appSettings = AppSettings.default
        appSettings.appVersion = currentVersion
        _ = saveAppSettings(appSettings)
        
        currentDogProfile = nil
        
        print("✅ [PersistenceController] All data cleared")
        return true
    }
    
    func updateLastSyncDate() {
        var updatedSettings = appSettings
        updatedSettings.lastSyncDate = Date()
        _ = saveAppSettings(updatedSettings)
    }
    
    // MARK: - Onboarding Management
    func markOnboardingCompleted() {
        print("💾 [PersistenceController] Marking onboarding as completed")
        
        var updatedSettings = appSettings
        updatedSettings.onboardingCompleted = true
        _ = saveAppSettings(updatedSettings)
        
        userDefaults.set(true, forKey: Keys.onboardingCompleted)
    }
    
    func isOnboardingCompleted() -> Bool {
        return appSettings.onboardingCompleted || userDefaults.bool(forKey: Keys.onboardingCompleted)
    }
    

    
    // MARK: - Helper Methods
    private func getBreedMultiplier(for breedName: String) -> Double {
        let multipliers: [String: Double] = [
            "Labrador Retriever": 1.4,
            "Golden Retriever": 1.4,
            "German Shepherd": 1.3,
            "French Bulldog": 2.0,
            "Chihuahua": 4.0,
            "Great Dane": 0.9,
            "Mixed Breed": 1.5
        ]
        return multipliers[breedName] ?? 1.5
    }
    
    private func getBreedGoal(for breedName: String, age: Int) -> Int {
        let baseGoals: [String: Int] = [
            "Labrador Retriever": 12000,
            "Golden Retriever": 12000,
            "German Shepherd": 10000,
            "French Bulldog": 5000,
            "Chihuahua": 3000,
            "Great Dane": 8000,
            "Mixed Breed": 8000
        ]
        
        let baseGoal = baseGoals[breedName] ?? 8000
        
        // Adjust for age
        let ageMultiplier: Double
        switch age {
        case 0...1: ageMultiplier = 0.6  // Puppy
        case 2...7: ageMultiplier = 1.0  // Adult
        case 8...12: ageMultiplier = 0.8 // Senior
        default: ageMultiplier = 0.6     // Very senior
        }
        
        return Int(Double(baseGoal) * ageMultiplier)
    }
}

// MARK: - Persistence Controller Extensions
extension PersistenceController {
    

    
    /// Exports all data for debugging
    func exportDataSummary() -> String {
        var summary = "=== Doggysteps Data Summary ===\n\n"
        
        // App Settings
        summary += "📱 App Settings:\n"
        summary += "- Onboarding Completed: \(appSettings.onboardingCompleted)\n"
        summary += "- Motion Enabled: \(appSettings.motionEnabled)\n"
        summary += "- Preferred Units: \(appSettings.preferredUnits.displayName)\n"
        summary += "- App Version: \(appSettings.appVersion)\n"
        if let lastSync = appSettings.lastSyncDate {
            summary += "- Last Sync: \(lastSync)\n"
        }
        summary += "\n"
        
        // Dog Profile
        if let profile = currentDogProfile {
            summary += "🐕 Dog Profile:\n"
            summary += "- Name: \(profile.name)\n"
            summary += "- Breed: \(profile.breedName)\n"
            summary += "- Body Condition: \(profile.bodyConditionDescription)\n"
            summary += "- Created: \(profile.createdAt)\n"
            summary += "\n"
        } else {
            summary += "🐕 No dog profile saved\n\n"
        }
        
        // Step Data
        let stepData = loadStepDataHistory()
        summary += "📊 Step Data: \(stepData.count) entries\n"
        if let latest = stepData.first {
            summary += "- Latest: \(latest.formattedDate) - \(latest.estimatedDogSteps) steps\n"
        }
        
        return summary
    }
} 