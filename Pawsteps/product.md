Product Requirements Document (PRD)
Product Name: Doggysteps
Platform: iOS (SwiftUI)
Version: 1.0
Last Updated: 2025-06-08
Overview
Doggysteps is a step-tracking app designed specifically for dogs. It estimates a dog’s steps based on the human user's walking data (sourced from the Apple Health app) and a breed-specific step algorithm. The app encourages regular walks through smart reminders and provides users insights into their dog's activity level.

Goals
Estimate dog steps using Apple Health walking data.

Adjust calculations based on breed-specific movement profiles.

Provide reminders to ensure dogs are walked regularly.

Offer an intuitive SwiftUI-based user experience.

Key Features
1. Dog Breed Selection
Onboarding flow prompts user to select their dog’s breed.

Breed selection impacts step conversion algorithm.

Includes a searchable breed list and a “Mixed Breed” option with average values.

2. Dog Step Tracker
Syncs with Apple Health to retrieve walking data (user steps and distance).

Applies breed-specific algorithm to estimate dog steps.

Displays:

Estimated dog steps per day.

Distance walked.

Time spent walking.

Weekly and monthly progress.

3. Dog Walk Reminders
Customizable daily reminders to encourage walks.

Smart notifications based on user habits (e.g., suggest walk if no activity by 5 PM).

Optional integration with Apple Reminders.

Data Sources and Integrations
Apple HealthKit:

Read user walking data (steps, distance, and timestamps).

Requires user permission at onboarding.

Dog Breed Step Algorithm:

Mapping table of breed → average stride multiplier or step rate.

Will consider size, energy level, and gait differences across breeds.

User Flow
Onboarding:

Welcome screen → permissions for HealthKit → dog profile setup (name, breed, age).

Home Screen:

Daily step goal progress bar.

Steps and distance for today.

Comparison to average activity.

“Start a walk” button for optional manual tracking.

Dog Profile:

View/edit dog info (name, breed, age).

Option to reset step data.

Reminders:

Manage notification schedule.

Enable/disable smart reminders.

Technical Requirements
SwiftUI 3+

HealthKit integration

CoreData or CloudKit for local and synced data persistence

Notification framework for reminders

Optionally: machine learning support (future feature) to refine step estimation over time

Non-Functional Requirements
Responsive design for all iPhone sizes.

Battery-efficient background data sync.

GDPR/CCPA-compliant data handling and user privacy.

MVP Scope
Single dog profile

Manual breed selection

Static step conversion per breed

Basic walk reminder settings

HealthKit integration (read-only)






SwiftUI Architecture Overview

PawstepsApp (App Entry Point)
│
├── Views/
│   ├── Onboarding/
│   │   ├── WelcomeView
│   │   ├── PermissionsView
│   │   └── BreedSelectionView
│   ├── Main/
│   │   ├── HomeView
│   │   ├── ProfileView
│   │   └── ReminderSettingsView
│
├── ViewModels/
│   ├── OnboardingViewModel
│   ├── HomeViewModel
│   ├── ProfileViewModel
│   └── ReminderViewModel
│
├── Models/
│   ├── Dog.swift
│   ├── Breed.swift
│   └── StepData.swift
│
├── Services/
│   ├── HealthKitService.swift
│   ├── StepEstimationService.swift
│   └── NotificationService.swift
│
├── Data/
│   ├── BreedStepTable.json (or plist)
│   └── PersistenceController.swift (for CoreData/CloudKit)
│
└── Utilities/
    └── Extensions.swift


📄 1. Models
swift
Copy
Edit
// Dog.swift
struct Dog: Codable, Identifiable {
    let id: UUID
    var name: String
    var breed: Breed
    var age: Int
}

// Breed.swift
struct Breed: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var stepMultiplier: Double
}

// StepData.swift
struct StepData {
    let date: Date
    let humanSteps: Int
    let estimatedDogSteps: Int
    let distance: Double // in meters
}
