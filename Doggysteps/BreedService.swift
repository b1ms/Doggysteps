//
//  BreedService.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation

// MARK: - Breed Service
/// Service for managing dog breed data and operations
class BreedService {
    
    // MARK: - Properties
    static let shared = BreedService()
    private var breeds: [BreedInfo] = []
    
    // MARK: - Initialization
    private init() {
        print("🐕 [BreedService] Initializing breed service")
        loadBreedData()
    }
    
    // MARK: - Public Methods
    func getAllBreeds() -> [BreedInfo] {
        print("🐕 [BreedService] Loading \(breeds.count) breeds")
        return breeds
    }
    
    func searchBreeds(query: String) -> [BreedInfo] {
        guard !query.isEmpty else {
            print("🐕 [BreedService] Empty search query, returning all breeds")
            return breeds
        }
        
        let filteredBreeds = breeds.filter { breed in
            breed.name.localizedCaseInsensitiveContains(query) ||
            breed.description.localizedCaseInsensitiveContains(query) ||
            breed.size.localizedCaseInsensitiveContains(query)
        }
        
        print("🐕 [BreedService] Found \(filteredBreeds.count) breeds matching '\(query)'")
        return filteredBreeds
    }
    
    func getBreedByName(_ name: String) -> BreedInfo? {
        return breeds.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
    
    // MARK: - Private Methods
    private func loadBreedData() {
        print("🐕 [BreedService] Loading breed data")
        
        breeds = [
            BreedInfo(name: "Labrador Retriever", stepMultiplier: 1.4, description: "Friendly, outgoing, and active dogs", size: "Large", energyLevel: "High"),
            BreedInfo(name: "Golden Retriever", stepMultiplier: 1.4, description: "Intelligent, friendly, and devoted dogs", size: "Large", energyLevel: "High"),
            BreedInfo(name: "German Shepherd", stepMultiplier: 1.3, description: "Confident, courageous, and smart working dogs", size: "Large", energyLevel: "High"),
            BreedInfo(name: "French Bulldog", stepMultiplier: 2.0, description: "Playful, alert, and adaptable", size: "Small", energyLevel: "Moderate"),
            BreedInfo(name: "Bulldog", stepMultiplier: 2.2, description: "Calm, courageous, and friendly", size: "Medium", energyLevel: "Low"),
            BreedInfo(name: "Poodle", stepMultiplier: 1.6, description: "Intelligent, active, and elegant dogs", size: "Medium", energyLevel: "High"),
            BreedInfo(name: "Beagle", stepMultiplier: 1.8, description: "Friendly, curious, and merry hounds", size: "Medium", energyLevel: "High"),
            BreedInfo(name: "Rottweiler", stepMultiplier: 1.2, description: "Loyal, loving, and confident guardians", size: "Large", energyLevel: "Moderate"),
            BreedInfo(name: "Yorkshire Terrier", stepMultiplier: 3.0, description: "Brave, determined, and energetic toy dogs", size: "Toy", energyLevel: "High"),
            BreedInfo(name: "Dachshund", stepMultiplier: 2.5, description: "Friendly and curious hounds", size: "Small", energyLevel: "Moderate"),
            BreedInfo(name: "Siberian Husky", stepMultiplier: 1.1, description: "Outgoing, mischievous, and loyal working dogs", size: "Large", energyLevel: "Very High"),
            BreedInfo(name: "Boxer", stepMultiplier: 1.3, description: "Fun-loving, bright, and active family dogs", size: "Large", energyLevel: "High"),
            BreedInfo(name: "Boston Terrier", stepMultiplier: 2.1, description: "Friendly, bright, and amusing companions", size: "Small", energyLevel: "Moderate"),
            BreedInfo(name: "Shih Tzu", stepMultiplier: 2.8, description: "Friendly, outgoing, and affectionate toy dogs", size: "Toy", energyLevel: "Low"),
            BreedInfo(name: "Cocker Spaniel", stepMultiplier: 1.7, description: "Gentle, smart, and happy sporting dogs", size: "Medium", energyLevel: "High"),
            BreedInfo(name: "Border Collie", stepMultiplier: 1.2, description: "Remarkably bright, energetic, and athletic", size: "Medium", energyLevel: "Very High"),
            BreedInfo(name: "Chihuahua", stepMultiplier: 4.0, description: "Graceful, alert, and swift-moving tiny dogs", size: "Toy", energyLevel: "High"),
            BreedInfo(name: "Great Dane", stepMultiplier: 0.9, description: "Friendly, patient, and dependable gentle giants", size: "Extra Large", energyLevel: "Moderate"),
            BreedInfo(name: "Pomeranian", stepMultiplier: 3.5, description: "Inquisitive, bold, and lively toy dogs", size: "Toy", energyLevel: "High"),
            BreedInfo(name: "Australian Shepherd", stepMultiplier: 1.2, description: "Smart, work-oriented, and exuberant", size: "Medium", energyLevel: "Very High"),
            BreedInfo(name: "Mixed Breed", stepMultiplier: 1.5, description: "A wonderful mix with unique characteristics", size: "Medium", energyLevel: "Moderate")
        ]
        
        print("✅ [BreedService] Loaded \(breeds.count) breeds successfully")
    }
}

// MARK: - Breed Info Structure
struct BreedInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let stepMultiplier: Double
    let description: String
    let size: String
    let energyLevel: String
    
    var displayName: String {
        return "\(name) (\(size))"
    }
    
    var summary: String {
        return "\(name) • \(size) • \(energyLevel) Energy"
    }
    
    func calculateDogSteps(from humanSteps: Int) -> Int {
        let estimatedSteps = Double(humanSteps) * stepMultiplier
        print("🐕 [BreedInfo] \(name): \(Int(estimatedSteps)) dog steps from \(humanSteps) human steps")
        return Int(estimatedSteps)
    }
} 