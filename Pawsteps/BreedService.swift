//
//  BreedService.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation

// MARK: - Breed Service Error Types
enum BreedServiceError: Error, LocalizedError {
    case jsonFileNotFound
    case jsonParsingFailed(Error)
    case invalidJSONStructure
    
    var errorDescription: String? {
        switch self {
        case .jsonFileNotFound:
            return "breeds.json file not found in app bundle"
        case .jsonParsingFailed(let error):
            return "Failed to parse breeds.json: \(error.localizedDescription)"
        case .invalidJSONStructure:
            return "Invalid JSON structure in breeds.json"
        }
    }
}

// MARK: - Breed Service
/// Service for managing dog breed data and operations
class BreedService {
    
    // MARK: - Properties
    static let shared = BreedService()
    private var breeds: [BreedInfo] = []
    private var isLoaded = false
    
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
    
    /// Reload breed data from JSON file
    func reloadBreedData() {
        print("🐕 [BreedService] Reloading breed data")
        loadBreedData()
    }
    
    // MARK: - Private Methods
    private func loadBreedData() {
        print("🐕 [BreedService] Loading breed data from JSON file")
        
        do {
            let breedData = try loadBreedsFromJSON()
            self.breeds = breedData
            self.isLoaded = true
            print("✅ [BreedService] Loaded \(breeds.count) breeds successfully from JSON")
        } catch {
            print("❌ [BreedService] Failed to load breeds from JSON: \(error)")
            // Fall back to basic breeds to ensure app doesn't crash
            loadFallbackBreeds()
        }
    }
    
    private func loadBreedsFromJSON() throws -> [BreedInfo] {
        // Get the path to the breeds.json file in the app bundle
        guard let path = Bundle.main.path(forResource: "breeds", ofType: "json") else {
            throw BreedServiceError.jsonFileNotFound
        }
        
        // Read the JSON file
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        // Parse the JSON data
        let jsonBreeds: [JSONBreed]
        do {
            jsonBreeds = try JSONDecoder().decode([JSONBreed].self, from: jsonData)
        } catch {
            throw BreedServiceError.jsonParsingFailed(error)
        }
        
        // Convert JSON breed objects to BreedInfo objects
        let breedInfos = jsonBreeds.map { jsonBreed in
            BreedInfo(
                name: jsonBreed.name,
                description: jsonBreed.description,
                size: jsonBreed.size,
                physical: jsonBreed.physical,
                movement: jsonBreed.movement,
                ageFactors: jsonBreed.ageFactors
            )
        }
        
        return breedInfos
    }
    
    private func loadFallbackBreeds() {
        print("🐕 [BreedService] Loading fallback breed data")
        
        // Minimal fallback breeds to ensure app functionality
        breeds = [
            BreedInfo(
                name: "Mixed Breed",
                description: "A wonderful mix with unique characteristics",
                size: "Medium",
                physical: PhysicalCharacteristics(averageLegLengthCm: 26, averageWeightKg: 20, bodyType: .athletic),
                movement: MovementCharacteristics(energyLevel: .moderate),
                ageFactors: AgeFactors(puppyMultiplier: 1.15, adultMultiplier: 1.0, seniorMultiplier: 1.05)
            ),
            BreedInfo(
                name: "Labrador Retriever",
                description: "Friendly, outgoing, and active dogs",
                size: "Large",
                physical: PhysicalCharacteristics(averageLegLengthCm: 28, averageWeightKg: 30, bodyType: .athletic),
                movement: MovementCharacteristics(energyLevel: .high),
                ageFactors: AgeFactors(puppyMultiplier: 1.15, adultMultiplier: 1.0, seniorMultiplier: 1.05)
            ),
            BreedInfo(
                name: "Golden Retriever",
                description: "Intelligent, friendly, and devoted dogs",
                size: "Large",
                physical: PhysicalCharacteristics(averageLegLengthCm: 28, averageWeightKg: 30, bodyType: .athletic),
                movement: MovementCharacteristics(energyLevel: .high),
                ageFactors: AgeFactors(puppyMultiplier: 1.15, adultMultiplier: 1.0, seniorMultiplier: 1.05)
            ),
            BreedInfo(
                name: "German Shepherd",
                description: "Confident, courageous, and smart working dogs",
                size: "Large",
                physical: PhysicalCharacteristics(averageLegLengthCm: 32, averageWeightKg: 35, bodyType: .athletic),
                movement: MovementCharacteristics(energyLevel: .high),
                ageFactors: AgeFactors(puppyMultiplier: 1.1, adultMultiplier: 1.0, seniorMultiplier: 1.05)
            ),
            BreedInfo(
                name: "French Bulldog",
                description: "Playful, alert, and adaptable",
                size: "Small",
                physical: PhysicalCharacteristics(averageLegLengthCm: 18, averageWeightKg: 12, bodyType: .compact),
                movement: MovementCharacteristics(energyLevel: .moderate),
                ageFactors: AgeFactors(puppyMultiplier: 1.15, adultMultiplier: 1.0, seniorMultiplier: 1.05)
            )
        ]
        
        self.isLoaded = true
        print("✅ [BreedService] Loaded \(breeds.count) fallback breeds")
    }
}

// MARK: - Body Type Enum
enum BodyType: String, Codable, CaseIterable {
    case compact = "compact"
    case athletic = "athletic"
    case elongated = "elongated"
    case heavy = "heavy"
    
    var description: String {
        return rawValue.capitalized
    }
}



// MARK: - Physical Characteristics
struct PhysicalCharacteristics: Codable, Hashable, Equatable {
    let averageLegLengthCm: Double
    let averageWeightKg: Double
    let bodyType: BodyType
}

// MARK: - Movement Characteristics
struct MovementCharacteristics: Codable, Hashable, Equatable {
    let energyLevel: EnergyLevel
}

// MARK: - Age Factors
struct AgeFactors: Codable, Hashable, Equatable {
    let puppyMultiplier: Double
    let adultMultiplier: Double
    let seniorMultiplier: Double
}

// MARK: - JSON Breed Structure
/// Temporary structure for parsing JSON breed data
private struct JSONBreed: Codable {
    let name: String
    let description: String
    let size: String
    let physical: PhysicalCharacteristics
    let movement: MovementCharacteristics
    let ageFactors: AgeFactors
}

// MARK: - Breed Info Structure
struct BreedInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let size: String
    let physical: PhysicalCharacteristics
    let movement: MovementCharacteristics
    let ageFactors: AgeFactors
    
    var displayName: String {
        return "\(name) (\(size))"
    }
    
    var summary: String {
        return "\(name) • \(size) • \(movement.energyLevel.description) Energy"
    }
    
    // Legacy property for compatibility
    var stepMultiplier: Double {
        return calculateStepMultiplier(dogAge: 3) // Default to adult age
    }
    
    // Legacy property for compatibility
    var energyLevel: String {
        return movement.energyLevel.description
    }
    
    func calculateDogSteps(from humanSteps: Int, dogAge: Int = 3) -> Int {
        let multiplier = calculateStepMultiplier(dogAge: dogAge)
        let estimatedSteps = Double(humanSteps) * multiplier
        print("🐕 [BreedInfo] \(name): \(Int(estimatedSteps)) dog steps from \(humanSteps) human steps (age: \(dogAge), multiplier: \(String(format: "%.2f", multiplier)))")
        return Int(estimatedSteps)
    }
    
    func calculateStepMultiplier(dogAge: Int) -> Double {
        // Base calculation from leg length
        let humanAverageStride = 65.0 // cm
        let dogStrideLength = physical.averageLegLengthCm * 1.6 // stride is ~1.6x leg length
        let baseMultiplier = humanAverageStride / dogStrideLength
        
        // Apply adjustments
        let energyAdjustment = getEnergyAdjustment(movement.energyLevel)
        let bodyTypeAdjustment = getBodyTypeAdjustment(physical.bodyType)
        let weightAdjustment = getWeightAdjustment(physical.averageWeightKg)
        let ageAdjustment = getAgeAdjustment(dogAge)
        
        let finalMultiplier = baseMultiplier * energyAdjustment * bodyTypeAdjustment * weightAdjustment * ageAdjustment
        
        print("🐕 [BreedInfo] \(name) multiplier calculation: base=\(String(format: "%.2f", baseMultiplier)), energy=\(String(format: "%.2f", energyAdjustment)), body=\(String(format: "%.2f", bodyTypeAdjustment)), weight=\(String(format: "%.2f", weightAdjustment)), age=\(String(format: "%.2f", ageAdjustment)), final=\(String(format: "%.2f", finalMultiplier))")
        
        return finalMultiplier
    }
    
    private func getEnergyAdjustment(_ energy: EnergyLevel) -> Double {
        switch energy {
        case .low: return 1.1      // More deliberate = more steps
        case .moderate: return 1.0  // Standard
        case .high: return 0.95     // More efficient = fewer steps
        case .veryHigh: return 0.9  // Very efficient
        }
    }
    
    private func getBodyTypeAdjustment(_ bodyType: BodyType) -> Double {
        switch bodyType {
        case .compact: return 1.15    // Short legs, more steps
        case .athletic: return 1.0    // Efficient movement
        case .elongated: return 0.9   // Long strides
        case .heavy: return 1.05      // Deliberate movement
        }
    }
    
    private func getWeightAdjustment(_ weight: Double) -> Double {
        switch weight {
        case 0..<5: return 1.2      // Very light, bouncy
        case 5..<15: return 1.1     // Light, quick steps
        case 15..<30: return 1.0    // Medium, standard
        case 30..<50: return 0.95   // Heavy, efficient
        default: return 0.9         // Very heavy, deliberate
        }
    }
    
    private func getAgeAdjustment(_ age: Int) -> Double {
        switch age {
        case 0...1: return ageFactors.puppyMultiplier
        case 2...7: return ageFactors.adultMultiplier
        default: return ageFactors.seniorMultiplier
        }
    }
} 