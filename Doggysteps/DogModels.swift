//
//  DogModels.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation

// MARK: - Supporting Enums
/// Dog breed size categories
enum BreedSize: String, Codable, CaseIterable {
    case toy = "Toy"
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var description: String {
        return rawValue
    }
}

/// Dog energy level categories
enum EnergyLevel: String, Codable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    
    var description: String {
        return rawValue
    }
    
    /// Emoji representation for UI
    var emoji: String {
        switch self {
        case .low: return "😴"
        case .moderate: return "🚶"
        case .high: return "🏃"
        case .veryHigh: return "⚡"
        }
    }
}

// MARK: - Breed Model
/// Represents a dog breed with step calculation multiplier
struct Breed: Codable, Identifiable, Hashable, Equatable {
    
    // MARK: - Properties
    let id: UUID
    var name: String
    var stepMultiplier: Double // Multiplier to convert human steps to dog steps
    var description: String
    var size: BreedSize
    var energyLevel: EnergyLevel
    
    // MARK: - Initializers
    init(name: String, stepMultiplier: Double, description: String = "", size: BreedSize = .medium, energyLevel: EnergyLevel = .moderate) {
        self.id = UUID()
        self.name = name
        self.stepMultiplier = stepMultiplier
        self.description = description
        self.size = size
        self.energyLevel = energyLevel
        
        print("🐕 [Breed] Created breed: \(name) with step multiplier: \(stepMultiplier)")
    }
    
    // MARK: - Static Properties
    /// Default breed for mixed or unknown breeds
    static let mixedBreed = Breed(
        name: "Mixed Breed",
        stepMultiplier: 1.5,
        description: "A wonderful mix of different breeds",
        size: .medium,
        energyLevel: .moderate
    )
    
    /// Unknown breed fallback
    static let unknown = Breed(
        name: "Unknown",
        stepMultiplier: 1.5,
        description: "Breed not specified",
        size: .medium,
        energyLevel: .moderate
    )
    
    // MARK: - Computed Properties
    /// Returns a formatted display name with size
    var displayName: String {
        return "\(name) (\(size.description))"
    }
    
    /// Returns breed information summary
    var summary: String {
        return "\(name) • \(size.description) • \(energyLevel.description) Energy"
    }
}

// MARK: - Dog Model
/// Represents a dog profile with basic information needed for step tracking
struct Dog: Codable, Identifiable {
    
    // MARK: - Properties
    let id: UUID
    var name: String
    var breed: Breed
    var age: Int // Age in years
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializers
    init(name: String, breed: Breed, age: Int) {
        self.id = UUID()
        self.name = name
        self.breed = breed
        self.age = age
        self.createdAt = Date()
        self.updatedAt = Date()
        
        print("🐕 [Dog] Created new dog profile: \(name), breed: \(breed.name), age: \(age)")
    }
    
    // MARK: - Methods
    /// Updates the dog's profile information
    mutating func updateProfile(name: String? = nil, breed: Breed? = nil, age: Int? = nil) {
        if let name = name {
            self.name = name
            print("🐕 [Dog] Updated name to: \(name)")
        }
        
        if let breed = breed {
            self.breed = breed
            print("🐕 [Dog] Updated breed to: \(breed.name)")
        }
        
        if let age = age {
            self.age = age
            print("🐕 [Dog] Updated age to: \(age)")
        }
        
        self.updatedAt = Date()
        print("✅ [Dog] Profile updated successfully")
    }
    
    /// Calculates estimated dog steps based on human steps
    func estimatedStepsFromHumanSteps(_ humanSteps: Int) -> Int {
        let estimatedSteps = Double(humanSteps) * breed.stepMultiplier
        print("🐕 [Dog] Estimated \(Int(estimatedSteps)) dog steps from \(humanSteps) human steps (multiplier: \(breed.stepMultiplier))")
        return Int(estimatedSteps)
    }
    
    // MARK: - Computed Properties
    /// Returns a display-friendly age string
    var ageDescription: String {
        return age == 1 ? "1 year old" : "\(age) years old"
    }
    
    /// Returns a formatted profile summary
    var profileSummary: String {
        return "\(name) • \(breed.name) • \(ageDescription)"
    }
}

// MARK: - Equatable Conformance
extension Dog: Equatable {
    static func == (lhs: Dog, rhs: Dog) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.breed == rhs.breed &&
               lhs.age == rhs.age
    }
} 