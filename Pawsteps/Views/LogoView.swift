//
//  LogoView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI

// MARK: - Logo View Component
struct LogoView: View {
    var body: some View {
        Text("D O G G Y S T E P S")
            .font(.system(size: 16, weight: .medium, design: .default))
            .foregroundColor(.primary)
            .tracking(3)
    }
}

// MARK: - Preview
#Preview {
    LogoView()
        .preferredColorScheme(.light)
} 