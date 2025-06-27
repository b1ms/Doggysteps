//
//  DogProfile.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation

// MARK: - Dog Gender Enum
enum DogGender: String, CaseIterable, Codable {
    case boy = "Boy"
    case girl = "Girl"
    
    var pronoun: String {
        switch self {
        case .boy: return "he"
        case .girl: return "she"
        }
    }
    
    var possessivePronoun: String {
        switch self {
        case .boy: return "his"
        case .girl: return "her"
        }
    }
    
    var emoji: String {
        switch self {
        case .boy: return "♂️"
        case .girl: return "♀️"
        }
    }
    
    var description: String {
        switch self {
        case .boy: return "He/him pronouns"
        case .girl: return "She/her pronouns"
        }
    }
}

// MARK: - Dog Body Condition Enum
enum DogBodyCondition: String, CaseIterable, Codable {
    case skinny = "A little skinny"
    case justRight = "Just right"
    case chubby = "A bit chubby"
    
    var description: String {
        switch self {
        case .skinny:
            return "Narrow waistline and you can clearly see ribs."
        case .justRight:
            return "Visible waistline with some fat cover but ribs are easy to feel."
        case .chubby:
            return "Waistline is not visible and ribs are tricky to feel."
        }
    }
    
    var emoji: String {
        switch self {
        case .skinny: return "🦴"
        case .justRight: return "💪"
        case .chubby: return "🍖"
        }
    }
}

// MARK: - Dog Profile
/// Represents a dog's profile information
struct DogProfile: Codable, Identifiable {
    
    // MARK: - Properties
    let id: UUID
    var name: String
    var breedName: String
    var gender: DogGender
    var bodyCondition: DogBodyCondition
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializers
    init(name: String, breedName: String, gender: DogGender, bodyCondition: DogBodyCondition) {
        self.id = UUID()
        self.name = name
        self.breedName = breedName
        self.gender = gender
        self.bodyCondition = bodyCondition
        self.createdAt = Date()
        self.updatedAt = Date()
        
        print("🐕 [DogProfile] Created profile for \(name) (\(breedName), \(gender.rawValue), \(bodyCondition.rawValue))")
    }
    
    // MARK: - Methods
    mutating func updateProfile(name: String? = nil, breedName: String? = nil, gender: DogGender? = nil, bodyCondition: DogBodyCondition? = nil) {
        if let name = name {
            self.name = name
            print("🐕 [DogProfile] Updated name to: \(name)")
        }
        
        if let breedName = breedName {
            self.breedName = breedName
            print("🐕 [DogProfile] Updated breed to: \(breedName)")
        }
        
        if let gender = gender {
            self.gender = gender
            print("🐕 [DogProfile] Updated gender to: \(gender.rawValue)")
        }
        
        if let bodyCondition = bodyCondition {
            self.bodyCondition = bodyCondition
            print("🐕 [DogProfile] Updated body condition to: \(bodyCondition.rawValue)")
        }
        
        self.updatedAt = Date()
        print("✅ [DogProfile] Profile updated successfully")
    }
    
    /// Calculate dog steps based on human steps using breed data
    func calculateDogSteps(from humanSteps: Int) -> Int {
        guard let breedInfo = BreedService.shared.getBreedByName(breedName) else {
            print("⚠️ [DogProfile] Breed '\(breedName)' not found, using default multiplier")
            return Int(Double(humanSteps) * 1.5) // Default multiplier
        }
        
        return breedInfo.calculateDogSteps(from: humanSteps)
    }
    
    // MARK: - Computed Properties
    var bodyConditionDescription: String {
        return "\(bodyCondition.rawValue) - \(bodyCondition.description)"
    }
    
    var summary: String {
        return "\(name) • \(breedName) • \(gender.rawValue) • \(bodyCondition.rawValue)"
    }
    
    var breedInfo: BreedInfo? {
        return BreedService.shared.getBreedByName(breedName)
    }
}

// MARK: - Equatable Conformance
extension DogProfile: Equatable {
    static func == (lhs: DogProfile, rhs: DogProfile) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.breedName == rhs.breedName &&
               lhs.gender == rhs.gender &&
               lhs.bodyCondition == rhs.bodyCondition
    }
} 