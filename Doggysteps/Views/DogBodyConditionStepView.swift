//
//  DogBodyConditionStepView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI

struct DogBodyConditionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedCondition: DogBodyCondition?
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            VStack(spacing: 16) {
                Text("What does \(viewModel.dogName)'s body look like?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
            }
            
            // Body condition options
            VStack(spacing: 20) {
                ForEach(DogBodyCondition.allCases, id: \.self) { condition in
                    bodyConditionOption(condition)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
        .onAppear {
            selectedCondition = viewModel.selectedBodyCondition
        }
    }
    
    private func bodyConditionOption(_ condition: DogBodyCondition) -> some View {
        VStack(spacing: 12) {
            // Dog silhouette representation
            HStack(spacing: 20) {
                // Show 3 dog silhouettes with different emphasis
                ForEach(0..<3, id: \.self) { index in
                    dogSilhouette(
                        isSelected: shouldHighlightSilhouette(condition: condition, index: index),
                        condition: condition,
                        index: index
                    )
                }
            }
            .padding(.vertical, 16)
            
            // Condition title and description
            VStack(spacing: 8) {
                Text(condition.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(condition.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(selectedCondition == condition ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            selectedCondition == condition ? Color.blue : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .onTapGesture {
            selectCondition(condition)
        }
    }
    
    private func dogSilhouette(isSelected: Bool, condition: DogBodyCondition, index: Int) -> some View {
        // Simple dog shape representation
        VStack(spacing: 4) {
            // Head
            Circle()
                .frame(width: 20, height: 20)
            
            // Body - varies based on condition
            RoundedRectangle(cornerRadius: 8)
                .frame(
                    width: bodyWidth(condition: condition, index: index),
                    height: 30
                )
            
            // Legs
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .frame(width: 3, height: 12)
                }
            }
        }
        .foregroundColor(isSelected ? .blue : .gray.opacity(0.4))
    }
    
    private func shouldHighlightSilhouette(condition: DogBodyCondition, index: Int) -> Bool {
        switch condition {
        case .skinny:
            return index == 0
        case .justRight:
            return index == 1
        case .chubby:
            return index == 2
        }
    }
    
    private func bodyWidth(condition: DogBodyCondition, index: Int) -> CGFloat {
        let baseWidths: [CGFloat] = [25, 35, 45] // skinny, normal, chubby
        return baseWidths[index]
    }
    
    private func selectCondition(_ condition: DogBodyCondition) {
        selectedCondition = condition
        viewModel.selectBodyCondition(condition)
        
        // Auto-advance after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            viewModel.moveToNextStep()
        }
    }
}

#Preview {
    DogBodyConditionStepView(viewModel: OnboardingViewModel())
} 