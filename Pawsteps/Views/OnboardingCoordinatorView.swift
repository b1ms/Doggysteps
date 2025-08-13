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
    @State private var isTextFieldFocused = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Current step content
                ScrollView {
                    VStack(spacing: 32) {
                        currentStepView
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Space for navigation buttons
                }
                
                Spacer()
                
                // Navigation buttons - hide when text field is focused
                if !isTextFieldFocused {
                    navigationButtons
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            print("🐕 [OnboardingCoordinatorView] Onboarding coordinator appeared")
            print("🐕 [OnboardingCoordinatorView] Current step: \(viewModel.currentStep), dogName: '\(viewModel.dogName)', canProceed: \(viewModel.canProceedFromCurrentStep())")
            
            // Ensure we start fresh if this is a new onboarding session
            viewModel.ensureFreshStart()
        }
        .sheet(isPresented: $showingDogProfileForm) {
            DogProfileFormView(viewModel: viewModel)
        }
    }
    
    // MARK: - View Components
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            // Step counter
            Text("Step \(stepIndex(viewModel.currentStep) + 1) of \(OnboardingStep.allCases.count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .dogName:
            DogNameStepView(viewModel: viewModel, isParentTextFieldFocused: $isTextFieldFocused)
            
        case .breedSelection:
            SimpleBreedSelectionView { breedName in
                viewModel.selectBreed(breedName)
            }
            
        case .dogGender:
            DogGenderStepView(viewModel: viewModel)
            
        case .bodyCondition:
            DogBodyConditionStepView(viewModel: viewModel)
        }
    }
    
    private var navigationButtons: some View {
        VStack(spacing: 16) {
            // Next/Continue button
            if viewModel.currentStep != .bodyCondition {
                            Button(action: {
                HapticService.shared.selection()
                viewModel.moveToNextStep()
            }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.canProceedFromCurrentStep())
                .opacity(viewModel.canProceedFromCurrentStep() ? 1.0 : 0.5)
            }
            
            // Back button
            if viewModel.currentStep != .dogName {
                Button(action: {
                    HapticService.shared.selection()
                    viewModel.moveToPreviousStep()
                }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Properties
    private var progressPercentage: Double {
        let currentIndex = stepIndex(viewModel.currentStep)
        let totalSteps = OnboardingStep.allCases.count
        return Double(currentIndex + 1) / Double(totalSteps)
    }
    
    // MARK: - Helper Methods
    private func stepIndex(_ step: OnboardingStep) -> Int {
        OnboardingStep.allCases.firstIndex(of: step) ?? 0
    }
}

// MARK: - Dog Name Step View (Modern Theme)
struct DogNameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var name = ""
    @FocusState private var isTextFieldFocused: Bool
    @Binding var isParentTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Welcome message
            VStack(spacing: 16) {
                Image("Mascot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    Text("Welcome to Pawsteps!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's get your furry friend set up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Header
            VStack(spacing: 24) {
                Image(systemName: "textformat.alt")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(width: 80, height: 80)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(20)
                
                VStack(spacing: 12) {
                    Text("What's your dog's name?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("This helps us personalize your experience")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Name input card
            VStack(spacing: 20) {
                TextField("Enter your dog's name", text: $name)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                    .onChange(of: name) { _, newValue in
                        viewModel.updateDogName(newValue)
                    }
                    .onChange(of: isTextFieldFocused) { _, newValue in
                        isParentTextFieldFocused = newValue
                    }

                if !name.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Perfect! We'll use \(name)'s name throughout the app")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .onAppear {
            name = viewModel.dogName
            print("🐕 [DogNameStepView] Appeared - viewModel.dogName: '\(viewModel.dogName)', local name: '\(name)'")
        }
    }
}

// MARK: - Dog Gender Step View (Modern Theme)
struct DogGenderStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 24) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(width: 100, height: 100)
                    .background(.purple.opacity(0.1))
                    .cornerRadius(25)
                
                VStack(spacing: 12) {
                    Text("Is \(viewModel.dogName.isEmpty ? "your dog" : viewModel.dogName) a boy or girl?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("This helps us use the right pronouns")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Gender options
            VStack(spacing: 16) {
                ForEach(DogGender.allCases, id: \.self) { gender in
                    Button(action: {
                        HapticService.shared.selection()
                        viewModel.selectGender(gender)
                        
                        // Auto-advance after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.moveToNextStep()
                        }
                    }) {
                        HStack(spacing: 16) {
                            Text(gender.emoji)
                                .font(.system(size: 32))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(gender.rawValue.capitalized)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(gender.description)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedGender == gender {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedGender == gender ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            viewModel.selectedGender == gender ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
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