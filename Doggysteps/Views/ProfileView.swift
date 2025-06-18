//
//  ProfileView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Phase 6 Complete: ProfileView for Dog Profile Management
 
 Features Implemented:
 ✅ View current dog profile information
 ✅ Edit dog name with validation
 ✅ Edit dog breed with searchable picker
 ✅ Edit dog age with picker interface
 ✅ Real-time validation and error handling
 ✅ Beautiful, modern iOS design
 ✅ Integration with PersistenceController
 ✅ Automatic saving with feedback
 ✅ Cancel/Save workflow with confirmations
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
                VStack(spacing: 24) {
                    headerSection
                    
                    if let profile = homeViewModel.dogProfile {
                        if isEditing {
                            editingSection
                        } else {
                            profileInfoSection(profile)
                        }
                        
                        actionButtonsSection
                    } else {
                        if isEditing {
                            editingSection
                        } else {
                            createProfileSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dog Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        if isEditing && hasChanges {
                            showingSaveConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                if homeViewModel.dogProfile != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Cancel" : "Edit") {
                            toggleEditing()
                        }
                        .foregroundStyle(isEditing ? .red : .blue)
                    }
                }
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
        }
        .onAppear {
            print("🐕 [ProfileView] View appeared")
            homeViewModel.loadDogProfile()
            setupEditingFields()
            print("🐕 [ProfileView] Initial state - hasProfile: \(homeViewModel.dogProfile != nil), isEditing: \(isEditing)")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Dog avatar
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            if let profile = homeViewModel.dogProfile {
                VStack(spacing: 4) {
                    Text(profile.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                                    Text("\(profile.breedName) • \(profile.bodyCondition.rawValue)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    Text("Create Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Tell us about your dog")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func profileInfoSection(_ profile: DogProfile) -> some View {
        VStack(spacing: 20) {
            // Profile information cards
            profileInfoCard(
                title: "Name",
                value: profile.name,
                icon: "tag.fill",
                color: .blue
            )
            
            profileInfoCard(
                title: "Breed",
                value: profile.breedName,
                icon: "pawprint.fill",
                color: .green
            )
            
            profileInfoCard(
                title: "Body Condition",
                value: profile.bodyCondition.rawValue,
                icon: "heart.fill",
                color: .orange
            )
            
            // Profile stats
            profileStatsSection(profile)
        }
    }
    
    private func profileInfoCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private func profileStatsSection(_ profile: DogProfile) -> some View {
        VStack(spacing: 16) {
            Text("Profile Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Created:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(profile.createdAt, style: .date)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Last Updated:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(profile.updatedAt, style: .relative)
                        .fontWeight(.medium)
                }
                
                if let breedInfo = profile.breedInfo {
                    Divider()
                    
                    HStack {
                        Text("Breed Info:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(breedInfo.size)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Energy Level:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(breedInfo.energyLevel)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Step Multiplier:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f", breedInfo.stepMultiplier))x")
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(.quaternary.opacity(0.5))
            .cornerRadius(12)
        }
    }
    
    private var editingSection: some View {
        VStack(spacing: 24) {
            Text("Edit Profile")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dog's Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    TextField("Enter your dog's name", text: $editingName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // Breed field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Breed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Button(action: {
                        showingBreedPicker = true
                    }) {
                        HStack {
                            Text(editingBreed.isEmpty ? "Select breed" : editingBreed)
                                .foregroundStyle(editingBreed.isEmpty ? .secondary : .primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.quaternary.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
                
                // Body Condition field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body Condition")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Picker("Body Condition", selection: $editingBodyCondition) {
                        ForEach(DogBodyCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue)
                                .tag(condition)
                        }
                    }
                    .pickerStyle(.segmented)
                    .background(.quaternary.opacity(0.3))
                    .cornerRadius(8)
                }
            }
            
            // Validation errors
            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(validationErrors, id: \.self) { error in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding()
                .background(.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Save button
            Button(action: {
                print("🐕 [ProfileView] Save button tapped, canSave: \(canSave)")
                saveChanges()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(homeViewModel.dogProfile == nil ? "Create Profile" : "Save Changes")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? .blue : .gray)
                .cornerRadius(12)
            }
            .disabled(!canSave)
        }
    }
    
    private var createProfileSection: some View {
        VStack(spacing: 24) {
            Text("Welcome to Doggysteps!")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Let's create your dog's profile to get personalized step tracking and activity recommendations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Create Profile") {
                    print("🐕 [ProfileView] Create Profile button tapped")
                    isEditing = true
                    setupEditingFields()
                    print("🐕 [ProfileView] isEditing set to: \(isEditing)")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                

            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if homeViewModel.dogProfile != nil && !isEditing {
                VStack(spacing: 12) {
                    
                    Button("Delete Profile") {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Development section
            developmentSection
        }
    }
    
    private var developmentSection: some View {
        VStack(spacing: 12) {
            Text("Development")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Reset Onboarding") {
                showingResetOnboardingConfirmation = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
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
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(breed.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedBreed == breed.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Breed")
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

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .cornerRadius(10)
        .padding(.horizontal)
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