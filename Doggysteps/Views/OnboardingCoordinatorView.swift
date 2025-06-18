//
//  OnboardingCoordinatorView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI

// MARK: - Onboarding Coordinator View
struct OnboardingCoordinatorView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showingDogProfileForm = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress indicator
                progressIndicator
                
                // Current step content
                currentStepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
                // Navigation buttons
                navigationButtons
            }
            .padding()
        }
        .onAppear {
            print("🐕 [OnboardingCoordinatorView] Onboarding coordinator appeared")
        }
        .sheet(isPresented: $showingDogProfileForm) {
            DogProfileFormView(viewModel: viewModel)
        }
    }
    
    // MARK: - View Components
    private var progressIndicator: some View {
        HStack {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(stepIndex(step) <= stepIndex(viewModel.currentStep) ? .blue : .gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if step != OnboardingStep.allCases.last {
                    Rectangle()
                        .fill(stepIndex(step) < stepIndex(viewModel.currentStep) ? .blue : .gray.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
            
        case .permissions:
            PermissionsStepView()
            
        case .breedSelection:
            SimpleBreedSelectionView { breedName in
                viewModel.selectBreed(breedName)
            }
            
        case .dogName:
            DogNameStepView(viewModel: viewModel)
            
        case .dogGender:
            DogGenderStepView(viewModel: viewModel)
            
        case .bodyCondition:
            DogBodyConditionStepView(viewModel: viewModel)
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            // Back button
            if viewModel.currentStep != .welcome {
                Button(action: {
                    viewModel.moveToPreviousStep()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(.blue)
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next/Continue button
            if viewModel.currentStep != .bodyCondition {
                Button(action: {
                    viewModel.moveToNextStep()
                }) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canProceedFromCurrentStep())
                .opacity(viewModel.canProceedFromCurrentStep() ? 1.0 : 0.5)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Helper Methods
    private func stepIndex(_ step: OnboardingStep) -> Int {
        OnboardingStep.allCases.firstIndex(of: step) ?? 0
    }
}

// MARK: - Welcome Step View
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App icon
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 16) {
                Text("Welcome to Doggysteps")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Track your dog's daily steps and activity based on your walking data")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Permissions Step View
struct PermissionsStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red.gradient)
            
            VStack(spacing: 16) {
                Text("Health Permissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("We need access to your Health app to track your walking data and estimate your dog's steps")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                PermissionRow(icon: "figure.walk", title: "Steps", description: "Daily step count")
                PermissionRow(icon: "location", title: "Distance", description: "Walking distance")
            }
            .padding()
            .background(.gray.opacity(0.2))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Dog Name Step View
struct DogNameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "textformat.alt")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 16) {
                Text("What's your dog's name?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("This helps us personalize your experience")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TextField("Enter your dog's name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .onChange(of: name) { _, newValue in
                        viewModel.updateDogName(newValue)
                    }
            }
            .padding()
            .background(.gray.opacity(0.2))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
        .onAppear {
            name = viewModel.dogName
        }
    }
}

// MARK: - Dog Gender Step View
struct DogGenderStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
            
            VStack(spacing: 16) {
                Text("Is \(viewModel.dogName.isEmpty ? "your dog" : viewModel.dogName) a boy or girl?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us use the right pronouns")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(DogGender.allCases, id: \.self) { gender in
                    Button(action: {
                        viewModel.selectGender(gender)
                        
                        // Auto-advance after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.moveToNextStep()
                        }
                    }) {
                        HStack {
                            Text(gender.emoji)
                                .font(.title)
                            
                            Text(gender.rawValue)
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if viewModel.selectedGender == gender {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title2)
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedGender == gender ? .blue.opacity(0.1) : .gray.opacity(0.2))
                                .stroke(viewModel.selectedGender == gender ? .blue : .clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}



// MARK: - Dog Profile Form View (Sheet)
struct DogProfileFormView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Dog Profile Form")
                    .font(.title)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Dog Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingCoordinatorView()
} 