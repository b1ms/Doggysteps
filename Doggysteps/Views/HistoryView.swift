//
//  HistoryView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 History View - Minimalist Black & White Calendar
 
 Features:
 ✅ Clean calendar-style weekly view
 ✅ Monthly navigation with minimal arrow buttons
 ✅ Daily step counts with subtle progress indicators
 ✅ Detailed step breakdown for selected day
 ✅ Weekly summary statistics in monochrome
 */

import SwiftUI

// MARK: - History View
struct HistoryView: View {
    
    // MARK: - Properties
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingDayDetail = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with month navigation
                    monthHeaderSection
                    
                    // Weekly summary
                    weeklySummarySection
                    
                    // Calendar grid
                    calendarSection
                    
                    // Selected day details
                    if showingDayDetail {
                        dayDetailSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var monthHeaderSection: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60) // Safe area spacing
            
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.light)
                    .foregroundStyle(.primary)
                    .tracking(0.5)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var weeklySummarySection: some View {
        VStack(spacing: 16) {
            Text(weekRangeString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .tracking(0.3)
            
            VStack(spacing: 8) {
                Text(formatLargeNumber(weeklyTotalSteps))
                    .font(.title)
                    .fontWeight(.ultraLight)
                    .foregroundStyle(.primary)
                
                Text("total steps this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                
                Text("\(String(format: "%.2f", weeklyTotalDistance)) mi • \(weeklyActiveTime) • \(weeklyWalkCount) walks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
                .fill(Color(.systemGray6).opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private var calendarSection: some View {
        VStack(spacing: 20) {
            // Day headers
            HStack {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 20)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(calendarDays, id: \.self) { date in
                    dayCell(for: date)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    private func dayCell(for date: Date) -> some View {
        let stepData = getStepData(for: date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
        
        return Button(action: {
            selectedDate = date
            withAnimation(.easeInOut(duration: 0.3)) {
                showingDayDetail = stepData != nil
            }
        }) {
            VStack(spacing: 6) {
                // Day number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isCurrentMonth ? .primary : Color.secondary.opacity(0.5))
                
                // Progress indicator
                if let stepData = stepData {
                    Circle()
                        .fill(stepData.goalProgressPercentage >= 100 ? .primary : Color.secondary.opacity(0.5))
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 44, height: 56)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(0.3))
                    }
                }
                .overlay(
                    Group {
                        if isToday {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                        }
                    }
                )
            )
        }
    }
    
    private var dayDetailSection: some View {
        VStack(spacing: 16) {
            if let stepData = getStepData(for: selectedDate) {
                VStack(spacing: 20) {
                    // Selected date header
                    Text(selectedDateString)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(stepData.goalProgressPercentage)% of goal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        
                        ProgressView(value: Double(stepData.goalProgressPercentage) / 100.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                            .scaleEffect(y: 2)
                    }
                    
                    // Step details
                    VStack(spacing: 12) {
                        Text("\(formatLargeNumber(stepData.estimatedDogSteps)) steps")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .foregroundStyle(.primary)
                        
                        Text(String(format: "%.2f mi", stepData.distanceInKilometers * 0.621371))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Text(estimatedActiveTime(for: stepData))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(estimatedWalkCount(for: stepData)) walks")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Activity chart for the day (placeholder)
                    dayActivityChart
                }
                .padding(20)
                .background(.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
    
    private var dayActivityChart: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Activity Throughout Day")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            // Simple bar chart showing hourly activity
            HStack(spacing: 2) {
                ForEach(0..<24) { hour in
                    Rectangle()
                        .fill(.secondary.opacity(Double.random(in: 0.1...0.6)))
                        .frame(height: CGFloat.random(in: 10...40))
                        .cornerRadius(2)
                }
            }
            
            HStack {
                Text("00")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.6))
                
                Spacer()
                
                Text("12")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.6))
                
                Spacer()
                
                Text("24")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        
        return "\(formatter.string(from: startOfWeek)) – \(formatter.string(from: endOfWeek))"
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d MMM"
        return formatter.string(from: selectedDate)
    }
    
    private var dayHeaders: [String] {
        return ["M", "T", "W", "T", "F", "S", "S"]
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let range = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<32
        
        var days: [Date] = []
        
        // Add days from previous month to fill the first week
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysFromPreviousMonth = (firstWeekday + 5) % 7 // Adjust for Monday start
        
        for i in (1...daysFromPreviousMonth).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Add days of current month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Add days from next month to fill the last week
        let totalCells = 42 // 6 weeks × 7 days
        let remainingCells = totalCells - days.count
        let lastDayOfMonth = days.last ?? currentMonth
        
        for i in 1...remainingCells {
            if let date = calendar.date(byAdding: .day, value: i, to: lastDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var weeklyTotalSteps: Int {
        return viewModel.weeklyStepData.reduce(0) { $0 + $1.estimatedDogSteps }
    }
    
    private var weeklyTotalDistance: Double {
        return viewModel.weeklyStepData.reduce(0) { $0 + $1.distanceInKilometers } * 0.621371
    }
    
    private var weeklyActiveTime: String {
        let totalMinutes = weeklyTotalSteps / 100
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
    
    private var weeklyWalkCount: Int {
        return viewModel.weeklyStepData.count
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func getStepData(for date: Date) -> StepData? {
        return viewModel.weeklyStepData.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private func estimatedActiveTime(for stepData: StepData) -> String {
        let minutes = stepData.estimatedDogSteps / 100
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
    
    private func estimatedWalkCount(for stepData: StepData) -> Int {
        return max(1, stepData.estimatedDogSteps / 2000)
    }
    
    private func formatLargeNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1f", thousands).replacingOccurrences(of: ".0", with: "") + "k"
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(HomeViewModel())
} 