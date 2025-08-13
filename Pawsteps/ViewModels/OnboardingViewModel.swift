//
//  OnboardingViewModel.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation
import SwiftUI

// MARK: - Onboarding View Model
@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStep: OnboardingStep = .dogName
    @Published var dogName: String = ""
    @Published var selectedBreed: String = ""
    @Published var selectedGender: DogGender = .boy
    @Published var selectedBodyCondition: DogBodyCondition = .justRight
    @Published var isOnboardingComplete: Bool = false
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Initialization
    init() {
        print("🐕 [OnboardingViewModel] Initializing onboarding view model")
        checkOnboardingStatus()
        
        // Debug: Print initial state
        print("🐕 [OnboardingViewModel] Initial state - dogName: '\(dogName)', selectedBreed: '\(selectedBreed)', currentStep: \(currentStep)")
    }
    
    // MARK: - Public Methods
    func moveToNextStep() {
        print("🐕 [OnboardingViewModel] moveToNextStep called from step: \(currentStep)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .dogName:
                currentStep = .breedSelection
                print("🐕 [OnboardingViewModel] Moving to breed selection step")
                
            case .breedSelection:
                currentStep = .dogGender
                print("🐕 [OnboardingViewModel] Moving to dog gender step")
                
            case .dogGender:
                currentStep = .bodyCondition
                print("🐕 [OnboardingViewModel] Moving to body condition step")
                
            case .bodyCondition:
                completeOnboarding()
            }
        }
        
        print("🐕 [OnboardingViewModel] After transition - new step: \(currentStep), dogName: '\(dogName)', canProceed: \(canProceedFromCurrentStep())")
    }
    
    func moveToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .dogName:
                break // Can't go back from first step
                
            case .breedSelection:
                currentStep = .dogName
                print("🐕 [OnboardingViewModel] Moving back to dog name step")
                
            case .dogGender:
                currentStep = .breedSelection
                print("🐕 [OnboardingViewModel] Moving back to breed selection step")
                
            case .bodyCondition:
                currentStep = .dogGender
                print("🐕 [OnboardingViewModel] Moving back to dog gender step")
            }
        }
    }
    
    func selectBreed(_ breedName: String) {
        selectedBreed = breedName
        print("🐕 [OnboardingViewModel] Selected breed: \(breedName)")
        
        // Auto-advance to dog gender step
        print("🐕 [OnboardingViewModel] Scheduling auto-advance from breed selection to dog gender step in 0.5 seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🐕 [OnboardingViewModel] Auto-advance from breed selection executing")
            self.moveToNextStep()
        }
    }
    
    func selectGender(_ gender: DogGender) {
        selectedGender = gender
        print("🐕 [OnboardingViewModel] Selected gender: \(gender.rawValue)")
    }
    
    func updateDogName(_ name: String) {
        dogName = name
        print("🐕 [OnboardingViewModel] Updated dog name: \(name)")
    }
    
    func selectBodyCondition(_ bodyCondition: DogBodyCondition) {
        selectedBodyCondition = bodyCondition
        print("🐕 [OnboardingViewModel] Selected body condition: \(bodyCondition.rawValue)")
    }
    
    func canProceedFromCurrentStep() -> Bool {
        let canProceed: Bool
        
        switch currentStep {
        case .dogName:
            canProceed = !dogName.isEmpty
            
        case .breedSelection:
            canProceed = !selectedBreed.isEmpty
            
        case .dogGender:
            canProceed = true // Gender is always selected (has default)
            
        case .bodyCondition:
            canProceed = true // Body condition is always selected (has default)
        }
        
        print("🐕 [OnboardingViewModel] canProceedFromCurrentStep(\(currentStep)): \(canProceed) - dogName: '\(dogName)', selectedBreed: '\(selectedBreed)'")
        return canProceed
    }
    
    // MARK: - Private Methods
    private func checkOnboardingStatus() {
        let hasCompletedOnboarding = persistenceController.isOnboardingCompleted()
        let existingProfile = persistenceController.currentDogProfile
        
        print("🐕 [OnboardingViewModel] Checking onboarding status - completed: \(hasCompletedOnboarding), hasProfile: \(existingProfile != nil)")
        
        if hasCompletedOnboarding {
            print("🐕 [OnboardingViewModel] User has already completed onboarding")
            isOnboardingComplete = true
        } else {
            print("🐕 [OnboardingViewModel] Starting fresh onboarding flow")
            
            // Check if there's existing profile data that should NOT be used in onboarding
            if let profile = existingProfile {
                print("⚠️ [OnboardingViewModel] Found existing profile data: \(profile.name) - this might cause issues")
                // Don't pre-populate from existing data during onboarding
            }
        }
    }
    
    private func completeOnboarding() {
        print("🐕 [OnboardingViewModel] Completing onboarding flow")
        
        // Save dog profile using PersistenceController
        saveDogProfile()
        
        // Mark onboarding as complete
        persistenceController.markOnboardingCompleted()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingComplete = true
        }
        
        print("✅ [OnboardingViewModel] Onboarding completed successfully")
    }
    
    private func saveDogProfile() {
        // Create a proper DogProfile object
        let dogProfile = DogProfile(
            name: dogName,
            breedName: selectedBreed,
            gender: selectedGender,
            bodyCondition: selectedBodyCondition
        )
        
        // Save using PersistenceController
        let success = persistenceController.saveDogProfile(dogProfile)
        
        if success {
            print("✅ [OnboardingViewModel] Dog profile saved successfully: \(dogName) (\(selectedBreed), \(selectedGender.rawValue), \(selectedBodyCondition.rawValue))")
        } else {
            print("❌ [OnboardingViewModel] Failed to save dog profile")
        }
    }
    
    // MARK: - Reset Methods (for development/testing)
    func resetOnboarding() {
        print("🐕 [OnboardingViewModel] Resetting onboarding flow")
        
        // Clear all data using PersistenceController
        _ = persistenceController.clearAllData()
        
        dogName = ""
        selectedBreed = ""
        selectedGender = .boy
        selectedBodyCondition = .justRight
        currentStep = .dogName
        isOnboardingComplete = false
        
        print("✅ [OnboardingViewModel] Onboarding reset completed")
    }
    
    // MARK: - Fresh Start Method
    func ensureFreshStart() {
        print("🐕 [OnboardingViewModel] Ensuring fresh onboarding start")
        
        // Only reset state if we haven't completed onboarding
        if !persistenceController.isOnboardingCompleted() {
            dogName = ""
            selectedBreed = ""
            selectedGender = .boy
            selectedBodyCondition = .justRight
            currentStep = .dogName
            isOnboardingComplete = false
            
            print("🐕 [OnboardingViewModel] Fresh start ensured - reset to initial state")
        }
    }
}

// MARK: - Onboarding Step Enum
enum OnboardingStep: CaseIterable {
    case dogName
    case breedSelection
    case dogGender
    case bodyCondition
    
    var title: String {
        switch self {
        case .dogName:
            return "Dog's Name"
        case .breedSelection:
            return "Choose Breed"
        case .dogGender:
            return "Dog's Gender"
        case .bodyCondition:
            return "Body Condition"
        }
    }
    
    var description: String {
        switch self {
        case .dogName:
            return "What's your dog's name?"
        case .breedSelection:
            return "Select your dog's breed for accurate step calculations"
        case .dogGender:
            return "Is your dog a boy or girl?"
        case .bodyCondition:
            return "What does your dog's body look like?"
        }
    }
} 