//
//  ContentView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    @State private var isInitialized = false
    
    var body: some View {
        HomeView()
            .onAppear {
                setupContentView()
            }
    }
    
    // MARK: - Private Methods
    private func setupContentView() {
        guard !isInitialized else { return }
        
        print("🏠 [ContentView] Main app content view setup started")
        
        // Phase 4 - Home & Dashboard complete
        print("🏠 [ContentView] Phase 4 - Home & Dashboard loaded")
        
        isInitialized = true
        print("✅ [ContentView] Main app content setup completed")
    }
}

#Preview {
    ContentView()
}
