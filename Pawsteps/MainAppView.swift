//
//  MainAppView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Translucent Tab Navigation (Weather App Style)
 
 Features:
 ✅ Bottom tab navigation with translucent styling
 ✅ Today view (main dashboard)
 ✅ History view (step tracking history)  
 ✅ Start Dog Walk view (workout tracking)
 ✅ Triangle indicator for active tab
 ✅ SF Symbols icons without text
 ✅ Translucent background effect
 */

import SwiftUI

// MARK: - Main App View
struct MainAppView: View {
    
    // MARK: - Properties
    @State private var selectedTab: TabSelection = .today
    @State private var previousTab: TabSelection = .today
    @StateObject private var homeViewModel = HomeViewModel()
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            // Custom Tab Container with sliding animation
            ZStack {
                // Content views with sliding transitions
                Group {
                    if selectedTab == .today {
                        TodayView()
                            .environmentObject(homeViewModel)
                            .transition(slideTransition(for: .today))
                    }
                    
                    if selectedTab == .history {
                        HistoryView()
                            .environmentObject(homeViewModel)
                            .transition(slideTransition(for: .history))
                    }
                    
                    if selectedTab == .startWalk {
                        StartDogWalkView()
                            .environmentObject(homeViewModel)
                            .transition(slideTransition(for: .startWalk))
                    }
                }
            }
            .clipped()
            
            // Custom Navigation Bar Overlay - positioned at bottom
            customNavigationBar
        }
        .onAppear {
            // Hide the default tab bar
            UITabBar.appearance().isHidden = true
        }
    }
    
    // MARK: - Animation Methods
    private func slideTransition(for tab: TabSelection) -> AnyTransition {
        let slideDirection = getSlideDirection(from: previousTab, to: tab)
        
        return AnyTransition.asymmetric(
            insertion: .move(edge: slideDirection.insertion),
            removal: .move(edge: slideDirection.removal)
        )
        .combined(with: .opacity)
    }
    
    private func getSlideDirection(from previousTab: TabSelection, to newTab: TabSelection) -> (insertion: Edge, removal: Edge) {
        let tabs = TabSelection.allCases
        let previousIndex = tabs.firstIndex(of: previousTab) ?? 0
        let newIndex = tabs.firstIndex(of: newTab) ?? 0
        
        if newIndex > previousIndex {
            // Moving right (next tab)
            return (insertion: .trailing, removal: .leading)
        } else {
            // Moving left (previous tab)
            return (insertion: .leading, removal: .trailing)
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        VStack(spacing: 0) {
            // Navigation bar with solid background
            HStack(spacing: 0) {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticService.shared.selection()
                        
                        // Update previous tab and animate to new tab
                        previousTab = selectedTab
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                }
            }
            .frame(height: 50)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    // MARK: - Helper Methods
}

// MARK: - Tab Selection Enum
enum TabSelection: String, CaseIterable {
    case today = "today"
    case startWalk = "startWalk"
    case history = "history"
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .history: return "History"
        case .startWalk: return "Start Dog Walk"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "house"
        case .history: return "calendar"
        case .startWalk: return "figure.walk"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .today: return "house.fill"
        case .history: return "calendar.circle.fill"
        case .startWalk: return "figure.walk.circle.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    MainAppView()
} 