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
    @StateObject private var homeViewModel = HomeViewModel()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main TabView
            TabView(selection: $selectedTab) {
                // Today Tab
                TodayView()
                    .environmentObject(homeViewModel)
                    .tabItem {
                        EmptyView()
                    }
                    .tag(TabSelection.today)
                
                // History Tab
                HistoryView()
                    .environmentObject(homeViewModel)
                    .tabItem {
                        EmptyView()
                    }
                    .tag(TabSelection.history)
                
                // Start Dog Walk Tab
                StartDogWalkView()
                    .environmentObject(homeViewModel)
                    .tabItem {
                        EmptyView()
                    }
                    .tag(TabSelection.startWalk)
            }
            
            // Custom Navigation Bar Overlay
            VStack {
                Spacer()
                customNavigationBar
            }
        }
        .onAppear {
            // Hide the default tab bar
            UITabBar.appearance().isHidden = true
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        VStack(spacing: 0) {
            // Navigation bar with clear background (floating effect)
            HStack(spacing: 0) {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                }
            }
            .background(Color.clear) // Clear background for floating effect
            
            // Triangle indicator underneath the SF symbols, pointing up toward them
            HStack {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    if tab == selectedTab {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.primary)
                    } else {
                        Color.clear
                            .frame(height: 8)
                    }
                    
                    if tab != TabSelection.allCases.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, getTabHorizontalPadding())
            .padding(.top, 2)
            .padding(.bottom, 8)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Helper Methods
    private func getTabHorizontalPadding() -> CGFloat {
        // Calculate padding to align triangle with tab icons
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth
        let tabWidth = availableWidth / CGFloat(TabSelection.allCases.count)
        return (tabWidth / 2) - 4 // 4 is half the triangle width
    }
}

// MARK: - Tab Selection Enum
enum TabSelection: String, CaseIterable {
    case today = "today"
    case history = "history"
    case startWalk = "startWalk"
    
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