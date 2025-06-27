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
            // Pixel-style paw icon
            VStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 50, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.pixelBrown)
                
                // Pixel decorative elements
                HStack(spacing: 2) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(Color.pixelDarkGreen)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding()
            .background(Color.pixelBeige)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pixelDarkBeige, lineWidth: 2)
            )
            
            VStack(spacing: 8) {
                Text("CHOOSE YOUR DOG'S BREED")
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.pixelBrown)
                
                Text("This helps us calculate accurate step counts")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Color.pixelBrown.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.pixelBrown.opacity(0.6))
                .font(.system(.body, design: .monospaced))
            
            TextField("Search breeds...", text: $searchText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.pixelBrown)
        }
        .padding()
        .background(Color.pixelBeige.opacity(0.8))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.pixelDarkBeige, lineWidth: 1)
        )
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
                .foregroundStyle(Color.pixelDarkGreen)
                .font(.system(.body, design: .monospaced))
                .frame(width: 24)
            
            Text(breed)
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Color.pixelBrown)
            
            Spacer()
            
            if selectedBreedName == breed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.pixelDarkGreen)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
        .background(selectedBreedName == breed ? Color.pixelBeige : Color.pixelBeige.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedBreedName == breed ? Color.pixelDarkGreen : Color.pixelDarkBeige.opacity(0.5), lineWidth: 1)
        )
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