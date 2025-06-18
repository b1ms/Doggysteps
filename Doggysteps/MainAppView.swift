//
//  MainAppView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 Modern Tab Navigation with Black & White Minimalist Theme
 
 Features:
 ✅ Bottom tab navigation with 3 main views
 ✅ Today view (main dashboard)
 ✅ History view (step tracking history)
 ✅ Start Dog Walk view (workout tracking)
 ✅ Black & white minimalist design
 ✅ Clean monochromatic styling
 */

import SwiftUI

// MARK: - Main App View
struct MainAppView: View {
    
    // MARK: - Properties
    @State private var selectedTab: TabSelection = .today
    @StateObject private var homeViewModel = HomeViewModel()
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Today Tab
            TodayView()
                .environmentObject(homeViewModel)
                .tabItem {
                    Image(systemName: selectedTab == .today ? "house.fill" : "house")
                    Text("Today")
                }
                .tag(TabSelection.today)
            
            // History Tab
            HistoryView()
                .environmentObject(homeViewModel)
                .tabItem {
                    Image(systemName: selectedTab == .history ? "calendar.circle.fill" : "calendar.circle")
                    Text("History")
                }
                .tag(TabSelection.history)
            
            // Start Dog Walk Tab
            StartDogWalkView()
                .environmentObject(homeViewModel)
                .tabItem {
                    Image(systemName: selectedTab == .startWalk ? "figure.walk.circle.fill" : "figure.walk.circle")
                    Text("Start Dog Walk")
                }
                .tag(TabSelection.startWalk)
        }
        .accentColor(.primary)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Helper Methods
    private func setupTabBarAppearance() {
        // Minimalist tab bar styling
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.systemGray5
        
        // Selected tab styling - black
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.label
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        // Normal tab styling - gray
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray2
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray2,
            .font: UIFont.systemFont(ofSize: 12, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
        case .history: return "calendar.circle"
        case .startWalk: return "figure.walk.circle"
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