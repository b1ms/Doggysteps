//
//  ProfileView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 ProfileView - Modern Clean UI Design
 
 Features:
 ✅ Modern card-based layout matching TodayView
 ✅ Clean white background design
 ✅ Rounded corners and subtle shadows
 ✅ Consistent spacing and typography
 ✅ Colorful accent colors for different sections
 ✅ Beautiful metric cards for profile information
 */

import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    
    // MARK: - Properties
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var editingName: String = ""
    @State private var editingBreed: String = ""
    @State private var editingGender: DogGender = .boy
    @State private var editingBodyCondition: DogBodyCondition = .justRight
    @State private var searchBreedText: String = ""
    
    // UI state
    @State private var isEditing = false
    @State private var showingBreedPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingResetOnboardingConfirmation = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top header
                    topHeader
                    
                    // Profile content
                    VStack(spacing: 20) {
                        if let profile = homeViewModel.dogProfile {
                            if isEditing {
                                editingSection
                            } else {
                                profileInfoSection(profile)
                            }
                            
                            if !isEditing {
                                actionButtonsSection
                            }
                        } else {
                            if isEditing {
                                editingSection
                            } else {
                                createProfileSection
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60) // Space for bottom navigation
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingBreedPicker) {
            BreedPickerView(selectedBreed: $editingBreed, searchText: $searchBreedText)
        }
        .alert("Save Changes?", isPresented: $showingSaveConfirmation) {
            Button("Save") {
                saveChanges()
                dismiss()
            }
            Button("Discard") {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Do you want to save them before closing?")
        }
        .alert("Delete Profile?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                homeViewModel.deleteProfile()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your dog's profile and all associated data. This action cannot be undone.")
        }
        .alert("Reset Onboarding?", isPresented: $showingResetOnboardingConfirmation) {
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the app to show the onboarding flow again. Your current profile will be deleted.")
        }
        .onAppear {
            print("🐕 [ProfileView] View appeared")
            homeViewModel.loadDogProfile()
            setupEditingFields()
            print("🐕 [ProfileView] Initial state - hasProfile: \(homeViewModel.dogProfile != nil), isEditing: \(isEditing)")
        }
    }
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack {
            // Back button
            Button(action: {
                if isEditing && hasChanges {
                    showingSaveConfirmation = true
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Title
            Text("Dog Profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Edit/Save button
            if homeViewModel.dogProfile != nil {
                Button(action: {
                    if isEditing {
                        if canSave {
                            saveChanges()
                        } else {
                            toggleEditing()
                        }
                    } else {
                        toggleEditing()
                    }
                }) {
                    Text(isEditing ? (canSave ? "Save" : "Cancel") : "Edit")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isEditing ? (canSave ? .white : .primary) : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isEditing ? (canSave ? .blue : Color(.systemGray6)) : Color(.systemGray6))
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 20)
    }
    
    // MARK: - Profile Info Section
    private func profileInfoSection(_ profile: DogProfile) -> some View {
        VStack(spacing: 20) {
            // Profile header card
            profileHeaderCard(profile)
            
            // Profile metrics
            Text("Profile Details")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Profile info cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                profileMetricCard(
                    icon: "tag.fill",
                    title: "Name",
                    value: profile.name,
                    backgroundColor: .blue.opacity(0.1),
                    iconColor: .blue
                )
                
                profileMetricCard(
                    icon: "pawprint.fill",
                    title: "Breed",
                    value: profile.breedName,
                    backgroundColor: .green.opacity(0.1),
                    iconColor: .green
                )
                
                profileMetricCard(
                    icon: "heart.fill",
                    title: "Condition",
                    value: profile.bodyCondition.rawValue,
                    backgroundColor: .orange.opacity(0.1),
                    iconColor: .orange
                )
                
                profileMetricCard(
                    icon: "calendar",
                    title: "Created",
                    value: profile.createdAt.formatted(.dateTime.day().month(.abbreviated)),
                    backgroundColor: .purple.opacity(0.1),
                    iconColor: .purple
                )
            }
            
            // Breed details if available
            if let breedInfo = profile.breedInfo {
                breedDetailsSection(breedInfo)
            }
        }
    }
    
    // MARK: - Profile Header Card
    private func profileHeaderCard(_ profile: DogProfile) -> some View {
        VStack(spacing: 16) {
            // Dog avatar
            Circle()
                .fill(.brown.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Text("🐕")
                        .font(.system(size: 40))
                }
            
            // Dog name and breed
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(profile.breedName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Profile Metric Card
    private func profileMetricCard(
        icon: String,
        title: String,
        value: String,
        backgroundColor: Color,
        iconColor: Color
    ) -> some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)
            
            // Value and title
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Breed Details Section
    private func breedDetailsSection(_ breedInfo: BreedInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breed Information")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                breedDetailRow(label: "Size", value: breedInfo.size)
                Divider()
                breedDetailRow(label: "Energy Level", value: breedInfo.energyLevel)
                Divider()
                breedDetailRow(label: "Step Multiplier", value: String(format: "%.1fx", breedInfo.stepMultiplier))
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Breed Detail Row
    private func breedDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Editing Section
    private var editingSection: some View {
        VStack(spacing: 24) {
            Text(homeViewModel.dogProfile == nil ? "Create Profile" : "Edit Profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dog's Name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter your dog's name", text: $editingName)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Breed field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Breed")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingBreedPicker = true
                    }) {
                        HStack {
                            Text(editingBreed.isEmpty ? "Select breed" : editingBreed)
                                .font(.system(size: 16))
                                .foregroundColor(editingBreed.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // Body Condition field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body Condition")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Picker("Body Condition", selection: $editingBodyCondition) {
                        ForEach(DogBodyCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue)
                                .tag(condition)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // Validation errors
            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(validationErrors, id: \.self) { error in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(16)
                .background(.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Save button
            Button(action: {
                print("🐕 [ProfileView] Save button tapped, canSave: \(canSave)")
                saveChanges()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                    Text(homeViewModel.dogProfile == nil ? "Create Profile" : "Save Changes")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(canSave ? .blue : .gray)
                .cornerRadius(12)
            }
            .disabled(!canSave)
        }
    }
    
    // MARK: - Create Profile Section
    private var createProfileSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                // Dog avatar placeholder
                Circle()
                    .fill(.brown.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Text("🐕")
                            .font(.system(size: 50))
                    }
                
                VStack(spacing: 8) {
                    Text("Welcome to Doggysteps!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Let's create your dog's profile to get personalized step tracking and activity recommendations.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Button("Create Profile") {
                print("🐕 [ProfileView] Create Profile button tapped")
                isEditing = true
                setupEditingFields()
                print("🐕 [ProfileView] isEditing set to: \(isEditing)")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.blue)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Reset Onboarding") {
                showingResetOnboardingConfirmation = true
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.orange)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.orange.opacity(0.1))
            .cornerRadius(12)
            
            Button("Delete Profile") {
                showingDeleteConfirmation = true
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasChanges: Bool {
        guard let profile = homeViewModel.dogProfile else { 
            // For new profiles, consider it changed if any required field is filled
            return !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !editingBreed.isEmpty
        }
        return editingName != profile.name || 
               editingBreed != profile.breedName || 
               editingGender != profile.gender ||
               editingBodyCondition != profile.bodyCondition
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        let trimmedName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errors.append("Dog name is required")
        }
        
        if editingName.count > 50 {
            errors.append("Dog name must be 50 characters or less")
        }
        
        if editingBreed.isEmpty {
            errors.append("Please select a breed")
        }
        
        // Debug logging
        if !errors.isEmpty {
            print("🐕 [ProfileView] Validation errors: \(errors)")
            print("🐕 [ProfileView] Current fields - name: '\(editingName)', breed: '\(editingBreed)', bodyCondition: \(editingBodyCondition.rawValue)")
        }
        
        return errors
    }
    
    private var canSave: Bool {
        if homeViewModel.dogProfile == nil {
            // For new profiles, just check validation errors
            return validationErrors.isEmpty
        } else {
            // For existing profiles, check both validation and changes
            return validationErrors.isEmpty && hasChanges
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupEditingFields() {
        if let profile = homeViewModel.dogProfile {
            editingName = profile.name
            editingBreed = profile.breedName
            editingGender = profile.gender
            editingBodyCondition = profile.bodyCondition
            print("🐕 [ProfileView] Setup editing fields for existing profile: \(profile.name)")
        } else {
            editingName = ""
            editingBreed = ""
            editingGender = .boy
            editingBodyCondition = .justRight
            print("🐕 [ProfileView] Setup editing fields for new profile")
        }
    }
    
    private func toggleEditing() {
        if isEditing {
            setupEditingFields() // Reset changes
        }
        isEditing.toggle()
    }
    
    private func saveChanges() {
        let trimmedName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingProfile = homeViewModel.dogProfile {
            var updatedProfile = existingProfile
            updatedProfile.updateProfile(
                name: trimmedName,
                breedName: editingBreed,
                gender: editingGender,
                bodyCondition: editingBodyCondition
            )
            homeViewModel.saveDogProfile(updatedProfile)
        } else {
            let newProfile = DogProfile(
                name: trimmedName,
                breedName: editingBreed,
                gender: editingGender,
                bodyCondition: editingBodyCondition
            )
            homeViewModel.saveDogProfile(newProfile)
        }
        
        isEditing = false
        print("🐕 [ProfileView] Profile saved successfully, calling homeViewModel.loadDogProfile()")
        homeViewModel.loadDogProfile()
    }
    
    private func resetOnboarding() {
        print("🐕 [ProfileView] Resetting onboarding flow")
        
        // Clear all data using PersistenceController
        let success = PersistenceController.shared.clearAllData()
        
        if success {
            print("✅ [ProfileView] Onboarding reset successfully")
            // Close the profile view and let the app coordinator handle the transition
            dismiss()
        } else {
            print("❌ [ProfileView] Failed to reset onboarding")
        }
             }
     }

// MARK: - Breed Picker View
struct BreedPickerView: View {
    @Binding var selectedBreed: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    
    private let breedService = BreedService.shared
    
    var filteredBreeds: [BreedInfo] {
        if searchText.isEmpty {
            return breedService.getAllBreeds()
        } else {
            return breedService.searchBreeds(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search breeds...")
                
                List(filteredBreeds) { breed in
                    Button(action: {
                        selectedBreed = breed.name
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(breed.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(breed.summary)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if selectedBreed == breed.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color(.systemBackground))
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Select Breed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// MARK: - Profile View Model
@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published private(set) var dogProfile: DogProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Methods
    func loadProfile() {
        print("🐕 [ProfileViewModel] Loading dog profile")
        dogProfile = persistenceController.currentDogProfile
        
        if let profile = dogProfile {
            print("✅ [ProfileViewModel] Profile loaded: \(profile.name)")
        } else {
            print("💭 [ProfileViewModel] No profile found")
        }
    }
    
    func saveProfile(_ profile: DogProfile) {
        print("🐕 [ProfileViewModel] Saving profile: \(profile.name)")
        isLoading = true
        error = nil
        
        if persistenceController.saveDogProfile(profile) {
            dogProfile = profile
            print("✅ [ProfileViewModel] Profile saved successfully")
        } else {
            error = "Failed to save profile. Please try again."
            print("❌ [ProfileViewModel] Failed to save profile")
        }
        
        isLoading = false
    }
    
    func deleteProfile() {
        print("🐕 [ProfileViewModel] Deleting profile")
        isLoading = true
        
        if persistenceController.deleteDogProfile() {
            dogProfile = nil
            print("✅ [ProfileViewModel] Profile deleted successfully")
        } else {
            error = "Failed to delete profile. Please try again."
            print("❌ [ProfileViewModel] Failed to delete profile")
        }
        
        isLoading = false
    }
    

}

// MARK: - Preview
#Preview {
    ProfileView()
}