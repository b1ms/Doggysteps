//
//  BreedSelectionView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI

// MARK: - Breed Selection View
struct BreedSelectionView: View {
    
    // MARK: - Properties
    @State private var searchText = ""
    @State private var selectedBreed: BreedInfo?
    @State private var isLoading = true
    
    // Callback for when breed is selected
    let onBreedSelected: (BreedInfo) -> Void
    
    // MARK: - Computed Properties
    private var filteredBreeds: [BreedInfo] {
        let breeds = BreedService.shared.getAllBreeds()
        
        if searchText.isEmpty {
            return breeds
        } else {
            return BreedService.shared.searchBreeds(query: searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Search and List Section
                if isLoading {
                    loadingView
                } else {
                    breedListSection
                }
            }
            .navigationTitle("Choose Breed")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupView()
            }
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Dog icon
            Image(systemName: "pawprint.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue.gradient)
            
            // Instructions
            VStack(spacing: 8) {
                Text("Select your dog's breed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("This helps us calculate accurate step counts for your furry friend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
    
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
    
    private var breedListSection: some View {
        VStack(spacing: 0) {
            // Search bar
            searchSection
            
            // Breed list
            List(filteredBreeds, id: \.id) { breed in
                breedRow(breed)
                    .onTapGesture {
                        selectBreed(breed)
                    }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search breeds...")
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search breeds...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func breedRow(_ breed: BreedInfo) -> some View {
        HStack(spacing: 16) {
            // Breed icon based on size
            breedIcon(for: breed.size)
            
            // Breed info
            VStack(alignment: .leading, spacing: 4) {
                Text(breed.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(breed.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Size and energy level tags
                HStack(spacing: 8) {
                    tagView(text: breed.size, color: .blue)
                    tagView(text: breed.energyLevel, color: .green)
                }
            }
            
            Spacer()
            
            // Step multiplier indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("Step Rate")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(breed.stepMultiplier, specifier: "%.1f")x")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
            
            // Selection indicator
            if selectedBreed?.id == breed.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func breedIcon(for size: String) -> some View {
        let iconName: String
        let iconColor: Color
        
        switch size.lowercased() {
        case "toy": 
            iconName = "pawprint"
            iconColor = .purple
        case "small": 
            iconName = "pawprint.fill"
            iconColor = .orange
        case "medium": 
            iconName = "pawprint.circle"
            iconColor = .blue
        case "large": 
            iconName = "pawprint.circle.fill"
            iconColor = .green
        case "extra large":
            iconName = "pawprint.circle.fill"
            iconColor = .red
        default: 
            iconName = "pawprint"
            iconColor = .gray
        }
        
        return Image(systemName: iconName)
            .font(.title2)
            .foregroundStyle(iconColor.gradient)
            .frame(width: 32, height: 32)
    }
    
    private func tagView(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
    
    // MARK: - Actions
    private func setupView() {
        print("🐕 [BreedSelectionView] Setting up breed selection view")
        
        // Simulate loading to show the breeds are being prepared
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
            print("✅ [BreedSelectionView] Breeds loaded, showing selection interface")
        }
    }
    
    private func selectBreed(_ breed: BreedInfo) {
        print("🐕 [BreedSelectionView] Selected breed: \(breed.name)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedBreed = breed
        }
        
        // Provide haptic feedback
        HapticService.shared.selection()
        
        // Call the callback after a brief delay to show selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onBreedSelected(breed)
            print("✅ [BreedSelectionView] Breed selection completed")
        }
    }
}

// MARK: - Preview
#Preview {
    BreedSelectionView { breed in
        print("Selected breed: \(breed.name)")
    }
} 