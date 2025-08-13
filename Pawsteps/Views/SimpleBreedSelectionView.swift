//
//  SimpleBreedSelectionView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI

// MARK: - Simple Breed Selection View
struct SimpleBreedSelectionView: View {
    
    // MARK: - Properties
    @State private var searchText = ""
    @State private var selectedBreedName = ""
    
    // Callback for when breed is selected
    let onBreedSelected: (String) -> Void
    
    // MARK: - Properties
    private let breedService = BreedService.shared
    @State private var isLoading = true
    @State private var allBreeds: [BreedInfo] = []
    
    private var filteredBreeds: [BreedInfo] {
        if searchText.isEmpty {
            return allBreeds
        } else {
            return breedService.searchBreeds(query: searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 32) {
            // Header
            headerSection
            
            // Content
            if isLoading {
                loadingView
            } else {
                // Search
                searchSection
                
                // Breed List
                breedListSection
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(Color(.systemBackground))
        .onAppear {
            loadBreeds()
        }
    }
    
    // MARK: - View Components
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading breeds...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Modern paw icon
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 100, height: 100)
                .background(.blue.opacity(0.1))
                .cornerRadius(25)
            
            VStack(spacing: 12) {
                Text("Choose Your Dog's Breed")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us calculate accurate step counts for your furry friend")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(.body))
            
            TextField("Search breeds...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var breedListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredBreeds, id: \.self) { breed in
                    breedRow(breed)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func breedRow(_ breed: BreedInfo) -> some View {
        HStack(spacing: 16) {
            // Breed icon
            Image(systemName: "pawprint.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(breed.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(breed.size) • \(breed.movement.energyLevel.description) Energy")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if selectedBreedName == breed.name {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(selectedBreedName == breed.name ? .blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(16)
        .onTapGesture {
            selectBreed(breed)
        }
    }
    
    // MARK: - Actions
    private func loadBreeds() {
        print("🐕 [SimpleBreedSelectionView] Loading breeds from BreedService")
        
        // Simulate loading to show the breeds are being prepared
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                allBreeds = breedService.getAllBreeds()
                isLoading = false
            }
            print("✅ [SimpleBreedSelectionView] Loaded \(allBreeds.count) breeds from JSON")
        }
    }
    
    private func selectBreed(_ breed: BreedInfo) {
        print("🐕 [SimpleBreedSelectionView] Selected breed: \(breed.name)")
        
        // Haptic feedback
        HapticService.shared.selection()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedBreedName = breed.name
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onBreedSelected(breed.name)
            print("✅ [SimpleBreedSelectionView] Breed selection completed")
        }
    }
}

// MARK: - Preview
#Preview {
    SimpleBreedSelectionView { breed in
        print("Selected: \(breed)")
    }
} 