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
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.pink)
                    .frame(width: 100, height: 100)
                    .background(.pink.opacity(0.1))
                    .cornerRadius(25)
                
                VStack(spacing: 12) {
                    Text("What does \(viewModel.dogName.isEmpty ? "your dog" : viewModel.dogName)'s body look like?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("This helps us calculate more accurate step estimates")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Body condition options
            VStack(spacing: 20) {
                ForEach(DogBodyCondition.allCases, id: \.self) { condition in
                    bodyConditionOption(condition)
                }
            }
        }
        .onAppear {
            selectedCondition = viewModel.selectedBodyCondition
        }
    }
    
    private func bodyConditionOption(_ condition: DogBodyCondition) -> some View {
        Button(action: {
            selectCondition(condition)
        }) {
            VStack(spacing: 20) {
                // Dog silhouette representation
                HStack(spacing: 24) {
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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(condition.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Selection indicator
                if selectedCondition == condition {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Selected")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedCondition == condition ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                selectedCondition == condition ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dogSilhouette(isSelected: Bool, condition: DogBodyCondition, index: Int) -> some View {
        VStack(spacing: 6) {
            // Head
            Circle()
                .frame(width: 16, height: 16)
            
            // Body - varies based on condition
            RoundedRectangle(cornerRadius: 6)
                .frame(
                    width: bodyWidth(condition: condition, index: index),
                    height: 24
                )
            
            // Legs
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .frame(width: 2, height: 10)
                }
            }
        }
        .foregroundColor(isSelected ? .blue : .gray.opacity(0.4))
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
        let baseWidths: [CGFloat] = [20, 28, 36] // skinny, normal, chubby
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