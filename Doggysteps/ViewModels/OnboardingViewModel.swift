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
    @Published var currentStep: OnboardingStep = .welcome
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
    }
    
    // MARK: - Public Methods
    func moveToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .permissions
                print("🐕 [OnboardingViewModel] Moving to permissions step")
                
            case .permissions:
                currentStep = .breedSelection
                print("🐕 [OnboardingViewModel] Moving to breed selection step")
                
            case .breedSelection:
                currentStep = .dogName
                print("🐕 [OnboardingViewModel] Moving to dog name step")
                
            case .dogName:
                currentStep = .dogGender
                print("🐕 [OnboardingViewModel] Moving to dog gender step")
                
            case .dogGender:
                currentStep = .bodyCondition
                print("🐕 [OnboardingViewModel] Moving to body condition step")
                
            case .bodyCondition:
                completeOnboarding()
            }
        }
    }
    
    func moveToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break // Can't go back from welcome
                
            case .permissions:
                currentStep = .welcome
                print("🐕 [OnboardingViewModel] Moving back to welcome step")
                
            case .breedSelection:
                currentStep = .permissions
                print("🐕 [OnboardingViewModel] Moving back to permissions step")
                
            case .dogName:
                currentStep = .breedSelection
                print("🐕 [OnboardingViewModel] Moving back to breed selection step")
                
            case .dogGender:
                currentStep = .dogName
                print("🐕 [OnboardingViewModel] Moving back to dog name step")
                
            case .bodyCondition:
                currentStep = .dogGender
                print("🐕 [OnboardingViewModel] Moving back to dog gender step")
            }
        }
    }
    
    func selectBreed(_ breedName: String) {
        selectedBreed = breedName
        print("🐕 [OnboardingViewModel] Selected breed: \(breedName)")
        
        // Auto-advance to dog name step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        switch currentStep {
        case .welcome:
            return true
            
        case .permissions:
            return true // For now, assume permissions are handled
            
        case .breedSelection:
            return !selectedBreed.isEmpty
            
        case .dogName:
            return !dogName.isEmpty
            
        case .dogGender:
            return true // Gender is always selected (has default)
            
        case .bodyCondition:
            return true // Body condition is always selected (has default)
        }
    }
    
    // MARK: - Private Methods
    private func checkOnboardingStatus() {
        let hasCompletedOnboarding = persistenceController.isOnboardingCompleted()
        
        if hasCompletedOnboarding {
            print("🐕 [OnboardingViewModel] User has already completed onboarding")
            isOnboardingComplete = true
        } else {
            print("🐕 [OnboardingViewModel] Starting fresh onboarding flow")
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
        currentStep = .welcome
        isOnboardingComplete = false
        
        print("✅ [OnboardingViewModel] Onboarding reset completed")
    }
}

// MARK: - Onboarding Step Enum
enum OnboardingStep: CaseIterable {
    case welcome
    case permissions
    case breedSelection
    case dogName
    case dogGender
    case bodyCondition
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Doggysteps"
        case .permissions:
            return "Health Permissions"
        case .breedSelection:
            return "Choose Breed"
        case .dogName:
            return "Dog's Name"
        case .dogGender:
            return "Dog's Gender"
        case .bodyCondition:
            return "Body Condition"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Track your dog's daily steps and activity"
        case .permissions:
            return "We need access to your health data to track steps"
        case .breedSelection:
            return "Select your dog's breed for accurate step calculations"
        case .dogName:
            return "What's your dog's name?"
        case .dogGender:
            return "Is your dog a boy or girl?"
        case .bodyCondition:
            return "What does your dog's body look like?"
        }
    }
} 