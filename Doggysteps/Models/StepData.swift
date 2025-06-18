//
//  StepData.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation
import CoreData

// MARK: - Health Data Model
struct HealthData {
    let date: Date
    let steps: Int
    let distanceInMeters: Double
    
    init(date: Date = Date(), steps: Int, distanceInMeters: Double = 0) {
        self.date = date
        self.steps = steps
        self.distanceInMeters = distanceInMeters
    }
}

// MARK: - Step Data Model
/// Represents daily step tracking data for both human and dog
struct StepData: Codable, Identifiable {
    
    // MARK: - Properties
    let id: UUID
    let date: Date
    let humanSteps: Int
    let estimatedDogSteps: Int
    let distanceInMeters: Double
    let breedName: String
    let breedMultiplier: Double
    let confidence: String
    let activityLevel: String
    let goalSteps: Int
    let createdAt: Date
    
    // MARK: - Initializers
    init(
        date: Date,
        humanSteps: Int,
        estimatedDogSteps: Int,
        distanceInMeters: Double = 0,
        breedName: String,
        breedMultiplier: Double,
        confidence: String = "Medium",
        activityLevel: String = "Moderate",
        goalSteps: Int = 6000
    ) {
        self.id = UUID()
        self.date = date
        self.humanSteps = humanSteps
        self.estimatedDogSteps = estimatedDogSteps
        self.distanceInMeters = distanceInMeters
        self.breedName = breedName
        self.breedMultiplier = breedMultiplier
        self.confidence = confidence
        self.activityLevel = activityLevel
        self.goalSteps = goalSteps
        self.createdAt = Date()
        
        print("📊 [StepData] Created step data: \(estimatedDogSteps) dog steps from \(humanSteps) human steps (\(breedName))")
    }
    
    // MARK: - Computed Properties
    var distanceInKilometers: Double {
        return distanceInMeters / 1000.0
    }
    
    var distanceInMiles: Double {
        return distanceInMeters / 1609.34
    }
    
    var goalProgress: Double {
        guard goalSteps > 0 else { return 0 }
        return Double(estimatedDogSteps) / Double(goalSteps)
    }
    
    var goalProgressPercentage: Int {
        return Int(goalProgress * 100)
    }
    
    var stepRatio: Double {
        guard humanSteps > 0 else { return 0 }
        return Double(estimatedDogSteps) / Double(humanSteps)
    }
    
    var isGoalMet: Bool {
        return estimatedDogSteps >= goalSteps
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var summary: String {
        return "\(estimatedDogSteps) steps • \(String(format: "%.1f", distanceInKilometers))km • \(goalProgressPercentage)% of goal"
    }
    
    var activityEmoji: String {
        switch activityLevel.lowercased() {
        case "very low": return "😴"
        case "low": return "🚶"
        case "moderate": return "🏃"
        case "high": return "🏃‍♂️"
        case "very high": return "⚡"
        default: return "🐕"
        }
    }
    
    var confidenceEmoji: String {
        switch confidence.lowercased() {
        case "high": return "✅"
        case "medium": return "⚠️"
        case "low": return "❓"
        default: return "💭"
        }
    }
    
    var goalStatusDescription: String {
        if isGoalMet {
            return "Goal achieved! 🎉"
        } else if goalProgressPercentage >= 80 {
            return "Almost there! 💪"
        } else if goalProgressPercentage >= 50 {
            return "Good progress 👍"
        } else {
            return "Needs more activity 🚶‍♂️"
        }
    }
    
    var detailedSummary: String {
        return """
        🐕 \(breedName): \(estimatedDogSteps) steps
        👤 Human: \(humanSteps) steps (×\(String(format: "%.1f", breedMultiplier)))
        📍 Distance: \(String(format: "%.2f", distanceInKilometers)) km
        🎯 Goal: \(goalProgressPercentage)% of \(goalSteps) steps
        📊 Activity: \(activityEmoji) \(activityLevel)
        🔍 Confidence: \(confidenceEmoji) \(confidence)
        """
    }
    
    // MARK: - Methods
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    func isThisWeek() -> Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func isYesterday() -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    func daysSinceDate() -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
    
    func compareActivityWith(_ other: StepData) -> ComparisonResult {
        if estimatedDogSteps > other.estimatedDogSteps {
            return .orderedDescending
        } else if estimatedDogSteps < other.estimatedDogSteps {
            return .orderedAscending
        } else {
            return .orderedSame
        }
    }
}

// MARK: - Step Data Extensions
extension StepData {
    
    /// Creates step data from HealthData using StepEstimationService
    @MainActor
    static func createFromHealthData(
        healthData: HealthData,
        breedName: String,
        bodyCondition: DogBodyCondition = .justRight,
        stepEstimationService: StepEstimationService? = nil
    ) -> StepData {
        let service = stepEstimationService ?? StepEstimationService.shared
        let estimation = service.estimateDogSteps(
            healthData: healthData,
            breedName: breedName
        )
        
        let dailyGoal = service.calculateDailyGoal(
            for: breedName,
            bodyCondition: bodyCondition
        )
        
        return StepData(
            date: healthData.date,
            humanSteps: healthData.steps,
            estimatedDogSteps: estimation.estimatedDogSteps,
            distanceInMeters: healthData.distanceInMeters,
            breedName: breedName,
            breedMultiplier: estimation.breedMultiplier,
            confidence: estimation.confidence.description,
            activityLevel: estimation.activityLevel.description,
            goalSteps: dailyGoal
        )
    }
    
    /// Creates step data from DogStepEstimation
    static func createFromEstimation(
        estimation: DogStepEstimation,
        date: Date = Date(),
        distanceInMeters: Double = 0
    ) -> StepData {
        return StepData(
            date: date,
            humanSteps: estimation.humanSteps,
            estimatedDogSteps: estimation.estimatedDogSteps,
            distanceInMeters: distanceInMeters,
            breedName: estimation.breedName,
            breedMultiplier: estimation.breedMultiplier,
            confidence: estimation.confidence.description,
            activityLevel: estimation.activityLevel.description,
            goalSteps: estimation.recommendedGoal
        )
    }
    
    /// Creates step data from basic inputs (legacy support)
    @MainActor
    static func create(
        humanSteps: Int,
        breedName: String,
        bodyCondition: DogBodyCondition = .justRight
    ) -> StepData {
        // Use the estimation service for better accuracy
        let stepEstimationService = StepEstimationService.shared
        let estimation = stepEstimationService.estimateDogSteps(
            humanSteps: humanSteps,
            breedName: breedName
        )
        
        let dailyGoal = stepEstimationService.calculateDailyGoal(
            for: breedName,
            bodyCondition: bodyCondition
        )
        
        return StepData(
            date: Date(),
            humanSteps: humanSteps,
            estimatedDogSteps: estimation.estimatedDogSteps,
            breedName: breedName,
            breedMultiplier: estimation.breedMultiplier,
            confidence: estimation.confidence.description,
            activityLevel: estimation.activityLevel.description,
            goalSteps: dailyGoal
        )
    }
    
    /// Get step multiplier for breed (simplified)
    private static func getMultiplierForBreed(_ breedName: String) -> Double {
        let multipliers: [String: Double] = [
            "Labrador Retriever": 1.4,
            "Golden Retriever": 1.4,
            "German Shepherd": 1.3,
            "French Bulldog": 2.0,
            "Bulldog": 2.2,
            "Poodle": 1.6,
            "Beagle": 1.8,
            "Rottweiler": 1.2,
            "Yorkshire Terrier": 3.0,
            "Dachshund": 2.5,
            "Siberian Husky": 1.1,
            "Boxer": 1.3,
            "Boston Terrier": 2.1,
            "Shih Tzu": 2.8,
            "Cocker Spaniel": 1.7,
            "Border Collie": 1.2,
            "Chihuahua": 4.0,
            "Great Dane": 0.9,
            "Pomeranian": 3.5,
            "Australian Shepherd": 1.2,
            "Mixed Breed": 1.5
        ]
        
        return multipliers[breedName] ?? 1.5
    }
    
    /// Get daily goal for breed (simplified)
    private static func getGoalForBreed(_ breedName: String, age: Int) -> Int {
        let sizeGoals: [String: Int] = [
            "Toy": 3000,
            "Small": 5000,
            "Medium": 8000,
            "Large": 12000,
            "Extra Large": 10000
        ]
        
        // Simplified size mapping
        let breedSizes: [String: String] = [
            "Labrador Retriever": "Large",
            "Golden Retriever": "Large",
            "German Shepherd": "Large",
            "French Bulldog": "Small",
            "Bulldog": "Medium",
            "Poodle": "Medium",
            "Beagle": "Medium",
            "Rottweiler": "Large",
            "Yorkshire Terrier": "Toy",
            "Dachshund": "Small",
            "Siberian Husky": "Large",
            "Boxer": "Large",
            "Boston Terrier": "Small",
            "Shih Tzu": "Toy",
            "Cocker Spaniel": "Medium",
            "Border Collie": "Medium",
            "Chihuahua": "Toy",
            "Great Dane": "Extra Large",
            "Pomeranian": "Toy",
            "Australian Shepherd": "Medium",
            "Mixed Breed": "Medium"
        ]
        
        let size = breedSizes[breedName] ?? "Medium"
        let baseGoal = sizeGoals[size] ?? 6000
        
        // Age adjustment
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

 