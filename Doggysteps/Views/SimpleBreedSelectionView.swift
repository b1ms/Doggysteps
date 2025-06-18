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
    
    // MARK: - Breed Data
    private let breeds = [
        "Labrador Retriever", "Golden Retriever", "German Shepherd", 
        "French Bulldog", "Bulldog", "Poodle", "Beagle", "Rottweiler",
        "Yorkshire Terrier", "Dachshund", "Siberian Husky", "Boxer",
        "Boston Terrier", "Shih Tzu", "Cocker Spaniel", "Border Collie",
        "Chihuahua", "Great Dane", "Pomeranian", "Australian Shepherd",
        "Mixed Breed"
    ]
    
    private var filteredBreeds: [String] {
        if searchText.isEmpty {
            return breeds
        } else {
            return breeds.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection
            
            // Search
            searchSection
            
            // Breed List
            breedListSection
            
            Spacer()
        }
        .padding()
        .onAppear {
            print("🐕 [SimpleBreedSelectionView] Breed selection view appeared")
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("Choose Your Dog's Breed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("This helps us calculate accurate step counts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search breeds...", text: $searchText)
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var breedListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredBreeds, id: \.self) { breed in
                    breedRow(breed)
                }
            }
        }
        .frame(maxHeight: 400)
    }
    
    private func breedRow(_ breed: String) -> some View {
        HStack {
            Image(systemName: "pawprint")
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(breed)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if selectedBreedName == breed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(selectedBreedName == breed ? .blue.opacity(0.1) : .clear)
        .cornerRadius(12)
        .onTapGesture {
            selectBreed(breed)
        }
    }
    
    // MARK: - Actions
    private func selectBreed(_ breed: String) {
        print("🐕 [SimpleBreedSelectionView] Selected breed: \(breed)")
        selectedBreedName = breed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onBreedSelected(breed)
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