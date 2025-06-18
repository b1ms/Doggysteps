//
//  StepEstimationService.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation
import Combine

// MARK: - Step Estimation Service Protocol
@MainActor
protocol StepEstimationServiceProtocol {
    func estimateDogSteps(humanSteps: Int, breedName: String) -> DogStepEstimation
    func estimateDogSteps(healthData: HealthData, breedName: String) -> DogStepEstimation
    func calculateDailyGoal(for breedName: String, bodyCondition: DogBodyCondition) -> Int
    func analyzeActivityLevel(steps: Int, for breedName: String) -> ActivityLevel
}

// MARK: - Dog Step Estimation Model
struct DogStepEstimation {
    let humanSteps: Int
    let estimatedDogSteps: Int
    let breedMultiplier: Double
    let breedName: String
    let confidence: EstimationConfidence
    let activityLevel: ActivityLevel
    let recommendedGoal: Int
    let timestamp: Date
    
    // MARK: - Computed Properties
    var stepRatio: Double {
        guard humanSteps > 0 else { return 0 }
        return Double(estimatedDogSteps) / Double(humanSteps)
    }
    
    var estimationAccuracy: String {
        switch confidence {
        case .high: return "Very Accurate"
        case .medium: return "Good Estimate"
        case .low: return "Approximate"
        }
    }
    
    var summary: String {
        return "Estimated \(estimatedDogSteps) dog steps from \(humanSteps) human steps (\(breedName), \(stepRatio.formatted(.number.precision(.fractionLength(1))))x multiplier)"
    }
}

// MARK: - Supporting Enums
enum EstimationConfidence: String, CaseIterable {
    case high = "High"
    case medium = "Medium" 
    case low = "Low"
    
    var description: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .high: return "✅"
        case .medium: return "⚠️"
        case .low: return "❓"
        }
    }
}

enum ActivityLevel: String, CaseIterable {
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    
    var description: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .veryLow: return "😴"
        case .low: return "🚶"
        case .moderate: return "🏃"
        case .high: return "🏃‍♂️"
        case .veryHigh: return "⚡"
        }
    }
    
    var goalMultiplier: Double {
        switch self {
        case .veryLow: return 0.5
        case .low: return 0.7
        case .moderate: return 1.0
        case .high: return 1.3
        case .veryHigh: return 1.6
        }
    }
}

// MARK: - Activity Trend
enum ActivityTrend: String, CaseIterable {
    case increasing = "Increasing"
    case stable = "Stable"
    case decreasing = "Decreasing"
    
    var emoji: String {
        switch self {
        case .increasing: return "📈"
        case .stable: return "➡️"
        case .decreasing: return "📉"
        }
    }
}

// MARK: - Estimation Insights
enum EstimationInsight: Hashable {
    case goalAchievement(String)
    case improvementNeeded(String)
    case lowActivity(String)
    case trendPositive(String)
    case trendNegative(String)
    case trendStable(String)
    
    var message: String {
        switch self {
        case .goalAchievement(let message),
             .improvementNeeded(let message),
             .lowActivity(let message),
             .trendPositive(let message),
             .trendNegative(let message),
             .trendStable(let message):
            return message
        }
    }
    
    var type: String {
        switch self {
        case .goalAchievement: return "Goal Achievement"
        case .improvementNeeded: return "Improvement Needed"
        case .lowActivity: return "Low Activity"
        case .trendPositive: return "Positive Trend"
        case .trendNegative: return "Negative Trend"
        case .trendStable: return "Stable Trend"
        }
    }
}

// MARK: - Codable Step Estimation (for persistence)
struct CodableStepEstimation: Codable {
    let humanSteps: Int
    let estimatedDogSteps: Int
    let breedMultiplier: Double
    let breedName: String
    let confidence: String
    let activityLevel: String
    let recommendedGoal: Int
    let timestamp: Date
    
    init(from estimation: DogStepEstimation) {
        self.humanSteps = estimation.humanSteps
        self.estimatedDogSteps = estimation.estimatedDogSteps
        self.breedMultiplier = estimation.breedMultiplier
        self.breedName = estimation.breedName
        self.confidence = estimation.confidence.rawValue
        self.activityLevel = estimation.activityLevel.rawValue
        self.recommendedGoal = estimation.recommendedGoal
        self.timestamp = estimation.timestamp
    }
    
    func toDogStepEstimation() -> DogStepEstimation {
        return DogStepEstimation(
            humanSteps: humanSteps,
            estimatedDogSteps: estimatedDogSteps,
            breedMultiplier: breedMultiplier,
            breedName: breedName,
            confidence: EstimationConfidence(rawValue: confidence) ?? .medium,
            activityLevel: ActivityLevel(rawValue: activityLevel) ?? .moderate,
            recommendedGoal: recommendedGoal,
            timestamp: timestamp
        )
    }
}

// MARK: - Step Estimation Service Implementation
@MainActor
class StepEstimationService: StepEstimationServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published private(set) var recentEstimations: [DogStepEstimation] = []
    @Published private(set) var dailyAverage: Double = 0
    
    private let breedService = BreedService.shared
    private let maxRecentEstimations = 10
    
    // Base step goals by breed size (steps per day)
    private let baseStepGoals: [String: Int] = [
        "Toy": 3000,
        "Small": 5000,
        "Medium": 8000,
        "Large": 12000,
        "Extra Large": 10000
    ]
    
    // MARK: - Initialization
    init() {
        print("🐕 [StepEstimationService] Initializing step estimation service")
        loadHistoricalData()
    }
    
    // MARK: - Public Methods
    func estimateDogSteps(humanSteps: Int, breedName: String) -> DogStepEstimation {
        print("🐕 [StepEstimationService] Estimating dog steps - Human: \(humanSteps), Breed: \(breedName)")
        
        guard let breedInfo = breedService.getBreedByName(breedName) else {
            print("⚠️ [StepEstimationService] Breed '\(breedName)' not found, using default estimation")
            return createDefaultEstimation(humanSteps: humanSteps, breedName: breedName)
        }
        
        // Calculate estimated dog steps
        let estimatedSteps = breedInfo.calculateDogSteps(from: humanSteps)
        
        // Determine confidence based on breed data quality and step count
        let confidence = calculateConfidence(humanSteps: humanSteps, breedInfo: breedInfo)
        
        // Analyze activity level
        let activityLevel = analyzeActivityLevel(steps: estimatedSteps, for: breedName)
        
        // Calculate recommended daily goal
        let recommendedGoal = calculateDailyGoal(for: breedName, bodyCondition: .justRight) // Default body condition
        
        let estimation = DogStepEstimation(
            humanSteps: humanSteps,
            estimatedDogSteps: estimatedSteps,
            breedMultiplier: breedInfo.stepMultiplier,
            breedName: breedName,
            confidence: confidence,
            activityLevel: activityLevel,
            recommendedGoal: recommendedGoal,
            timestamp: Date()
        )
        
        // Store estimation
        addToRecentEstimations(estimation)
        
        print("✅ [StepEstimationService] \(estimation.summary)")
        return estimation
    }
    
    func estimateDogSteps(healthData: HealthData, breedName: String) -> DogStepEstimation {
        print("🐕 [StepEstimationService] Estimating dog steps from health data - Date: \(healthData.date), Steps: \(healthData.steps)")
        
        let estimation = estimateDogSteps(humanSteps: healthData.steps, breedName: breedName)
        
        // Enhanced confidence based on distance data
        let enhancedEstimation = enhanceEstimationWithDistance(estimation, distance: healthData.distanceInMeters)
        
        return enhancedEstimation
    }
    
    func calculateDailyGoal(for breedName: String, bodyCondition: DogBodyCondition) -> Int {
        print("🐕 [StepEstimationService] Calculating daily goal for \(breedName), body condition: \(bodyCondition.rawValue)")
        
        guard let breedInfo = breedService.getBreedByName(breedName) else {
            print("⚠️ [StepEstimationService] Using default goal for unknown breed")
            return 6000 // Default goal
        }
        
        // Get base goal for breed size
        let baseGoal = baseStepGoals[breedInfo.size] ?? 6000
        
        // Adjust for body condition (overweight dogs may need more exercise, underweight may need less)
        let bodyConditionMultiplier: Double
        switch bodyCondition {
        case .skinny: bodyConditionMultiplier = 0.8  // Less exercise needed, focus on nutrition
        case .justRight: bodyConditionMultiplier = 1.0  // Normal exercise
        case .chubby: bodyConditionMultiplier = 1.2  // More exercise needed for weight management
        }
        
        // Adjust for energy level
        let energyMultiplier: Double
        switch breedInfo.energyLevel.lowercased() {
        case "low": energyMultiplier = 0.7
        case "moderate": energyMultiplier = 1.0
        case "high": energyMultiplier = 1.3
        case "very high": energyMultiplier = 1.5
        default: energyMultiplier = 1.0
        }
        
        let adjustedGoal = Int(Double(baseGoal) * bodyConditionMultiplier * energyMultiplier)
        
        print("✅ [StepEstimationService] Daily goal: \(adjustedGoal) steps (base: \(baseGoal), body condition: \(bodyConditionMultiplier), energy: \(energyMultiplier))")
        
        return adjustedGoal
    }
    
    func analyzeActivityLevel(steps: Int, for breedName: String) -> ActivityLevel {
        let dailyGoal = calculateDailyGoal(for: breedName, bodyCondition: .justRight) // Default body condition for analysis
        let goalPercentage = Double(steps) / Double(dailyGoal)
        
        let level: ActivityLevel
        switch goalPercentage {
        case 0..<0.3:
            level = .veryLow
        case 0.3..<0.6:
            level = .low
        case 0.6..<1.2:
            level = .moderate
        case 1.2..<1.8:
            level = .high
        default:
            level = .veryHigh
        }
        
        print("🐕 [StepEstimationService] Activity level: \(level.description) (\(String(format: "%.1f", goalPercentage * 100))% of goal)")
        
        return level
    }
    
    // MARK: - Private Methods
    private func createDefaultEstimation(humanSteps: Int, breedName: String) -> DogStepEstimation {
        let defaultMultiplier = 1.5
        let estimatedSteps = Int(Double(humanSteps) * defaultMultiplier)
        
        return DogStepEstimation(
            humanSteps: humanSteps,
            estimatedDogSteps: estimatedSteps,
            breedMultiplier: defaultMultiplier,
            breedName: breedName,
            confidence: .low,
            activityLevel: .moderate,
            recommendedGoal: 6000,
            timestamp: Date()
        )
    }
    
    private func calculateConfidence(humanSteps: Int, breedInfo: BreedInfo) -> EstimationConfidence {
        // Higher confidence for well-known breeds and reasonable step counts
        let stepCountScore: Double
        switch humanSteps {
        case 1000...20000: stepCountScore = 1.0  // Normal range
        case 500...1000, 20000...30000: stepCountScore = 0.7  // Slightly outside normal
        default: stepCountScore = 0.3  // Very low or very high
        }
        
        // Confidence based on breed data completeness
        let breedScore: Double = breedInfo.description.isEmpty ? 0.7 : 1.0
        
        let totalScore = (stepCountScore + breedScore) / 2.0
        
        switch totalScore {
        case 0.8...1.0: return .high
        case 0.5...0.8: return .medium
        default: return .low
        }
    }
    
    private func enhanceEstimationWithDistance(_ estimation: DogStepEstimation, distance: Double) -> DogStepEstimation {
        // Use distance data to validate step estimation
        let averageStepLength = distance > 0 ? distance / Double(estimation.humanSteps) : 0.65 // Default 65cm
        
        // Typical human step length is 60-80cm
        let confidenceAdjustment: EstimationConfidence
        if averageStepLength >= 0.5 && averageStepLength <= 1.0 {
            confidenceAdjustment = estimation.confidence // Keep current confidence
        } else {
            // Adjust confidence down if step length seems unusual
            confidenceAdjustment = estimation.confidence == .high ? .medium : estimation.confidence
        }
        
        return DogStepEstimation(
            humanSteps: estimation.humanSteps,
            estimatedDogSteps: estimation.estimatedDogSteps,
            breedMultiplier: estimation.breedMultiplier,
            breedName: estimation.breedName,
            confidence: confidenceAdjustment,
            activityLevel: estimation.activityLevel,
            recommendedGoal: estimation.recommendedGoal,
            timestamp: estimation.timestamp
        )
    }
    
    private func addToRecentEstimations(_ estimation: DogStepEstimation) {
        recentEstimations.append(estimation)
        
        // Keep only recent estimations
        if recentEstimations.count > maxRecentEstimations {
            recentEstimations.removeFirst()
        }
        
        // Update daily average
        updateDailyAverage()
        
        // Auto-save data 
        saveEstimationData()
    }
    
    private func updateDailyAverage() {
        guard !recentEstimations.isEmpty else {
            dailyAverage = 0
            return
        }
        
        let total = recentEstimations.reduce(0) { $0 + $1.estimatedDogSteps }
        dailyAverage = Double(total) / Double(recentEstimations.count)
        
        print("📊 [StepEstimationService] Updated daily average: \(String(format: "%.0f", dailyAverage)) steps")
    }
    
    private func loadHistoricalData() {
        // Load from UserDefaults for now (can be enhanced with Core Data later)
        if let data = UserDefaults.standard.data(forKey: "recentStepEstimations"),
           let savedEstimations = try? JSONDecoder().decode([CodableStepEstimation].self, from: data) {
            
            recentEstimations = savedEstimations.map { $0.toDogStepEstimation() }
            updateDailyAverage()
            
            print("📊 [StepEstimationService] Loaded \(recentEstimations.count) historical estimations")
        } else {
            print("📊 [StepEstimationService] No historical data found")
        }
    }
    
    func saveEstimationData() {
        let codableEstimations = recentEstimations.map { CodableStepEstimation(from: $0) }
        
        if let data = try? JSONEncoder().encode(codableEstimations) {
            UserDefaults.standard.set(data, forKey: "recentStepEstimations")
            print("💾 [StepEstimationService] Saved \(codableEstimations.count) estimations")
        }
    }
    
    func getWeeklyAverage() -> Double {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyEstimations = recentEstimations.filter { $0.timestamp >= oneWeekAgo }
        
        guard !weeklyEstimations.isEmpty else { return 0 }
        
        let total = weeklyEstimations.reduce(0) { $0 + $1.estimatedDogSteps }
        return Double(total) / Double(weeklyEstimations.count)
    }
    
    func getActivityTrend() -> ActivityTrend {
        guard recentEstimations.count >= 3 else { return .stable }
        
        let recent = Array(recentEstimations.suffix(3))
        let firstSteps = recent.first?.estimatedDogSteps ?? 0
        let lastSteps = recent.last?.estimatedDogSteps ?? 0
        
        let percentChange = Double(lastSteps - firstSteps) / Double(firstSteps) * 100
        
        switch percentChange {
        case 10...: return .increasing
        case ..<(-10): return .decreasing
        default: return .stable
        }
    }
    
    func getBreedMultiplier(for breedName: String) -> Double {
        guard let breedInfo = breedService.getBreedByName(breedName) else {
            print("⚠️ [StepEstimationService] Breed '\(breedName)' not found, using default multiplier")
            return 1.5 // Default multiplier
        }
        
        return breedInfo.stepMultiplier
    }
    
    func getEstimationInsights(for breedName: String) -> [EstimationInsight] {
        var insights: [EstimationInsight] = []
        
        let weeklyAvg = getWeeklyAverage()
        let dailyGoal = calculateDailyGoal(for: breedName, bodyCondition: .justRight)
        
        // Goal achievement insight
        if weeklyAvg >= Double(dailyGoal) * 0.8 {
            insights.append(.goalAchievement("Great job! Your dog is meeting their activity goals"))
        } else if weeklyAvg >= Double(dailyGoal) * 0.5 {
            insights.append(.improvementNeeded("Your dog could use a bit more activity"))
        } else {
            insights.append(.lowActivity("Consider increasing daily walks for better health"))
        }
        
        // Trend insight
        let trend = getActivityTrend()
        switch trend {
        case .increasing:
            insights.append(.trendPositive("Activity levels are improving! Keep it up!"))
        case .decreasing:
            insights.append(.trendNegative("Activity has decreased recently"))
        case .stable:
            insights.append(.trendStable("Activity levels are consistent"))
        }
        
        return insights
    }
}

// MARK: - Singleton Instance
extension StepEstimationService {
    static let shared = StepEstimationService()
}

 