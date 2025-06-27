//
//  HistoryView.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

/*
 History View - Modern Fitness App UI
 
 Features:
 ✅ Clean modern design matching TodayView
 ✅ Monthly navigation with modern styling
 ✅ Daily step counts with clean progress indicators
 ✅ Card-based metrics layout
 ✅ Detailed step breakdown with modern styling
 ✅ Weekly summary statistics
 ✅ Consistent with TodayView aesthetics
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
                    // Top header with month navigation
                    topHeader
                    
                    // Weekly summary section
                    weeklySummarySection
                    
                    // Calendar section
                    calendarSection
                    
                    // Selected day details
                    if showingDayDetail {
                        dayDetailSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer(minLength: 60) // Space for bottom navigation
                }
                .padding(.horizontal, 20)
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
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack {
            // Month navigation
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Month and year
            Text(monthYearString)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    // MARK: - Weekly Summary Section
    private var weeklySummarySection: some View {
        VStack(spacing: 12) {
            // Week range
            Text(weekRangeString)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            // Total steps
            VStack(spacing: 6) {
                Text(formatStepCount(weeklyTotalSteps))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("steps this week")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Weekly metrics
            HStack(spacing: 12) {
                Text(String(format: "%.1f mi", weeklyTotalDistance))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("|")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(weeklyActiveTime)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("|")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(weeklyWalkCount) walks")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: 12) {
            // Day headers
            HStack {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(calendarDays, id: \.self) { date in
                    dayCell(for: date)
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Day Cell
    private func dayCell(for date: Date) -> some View {
        let stepData = getStepData(for: date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let hasCompletedGoal = stepData?.goalProgressPercentage ?? 0 >= 100
        let hasWalk = stepData != nil && stepData!.estimatedDogSteps > 0
        
        return Button(action: {
            selectedDate = date
            withAnimation(.easeInOut(duration: 0.3)) {
                showingDayDetail = stepData != nil
            }
        }) {
                         VStack(spacing: 4) {
                 // Day number
                 Text("\(Calendar.current.component(.day, from: date))")
                     .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                     .foregroundColor(isCurrentMonth ? .primary : .secondary)
                 
                 // Activity indicators
                 HStack(spacing: 2) {
                     if hasCompletedGoal {
                         Image(systemName: "flame.fill")
                             .font(.system(size: 10))
                             .foregroundColor(.orange)
                     } else if hasWalk {
                         Image(systemName: "heart.fill")
                             .font(.system(size: 10))
                             .foregroundColor(.red)
                     }
                 }
                 .frame(height: 12)
                 
                 // Progress indicator
                 if let stepData = stepData {
                     let progress = Double(stepData.goalProgressPercentage) / 100.0
                     Circle()
                         .fill(progress >= 1.0 ? .green : progress >= 0.5 ? .yellow : .orange)
                         .frame(width: 4, height: 4)
                         .opacity(progress > 0 ? 1.0 : 0.3)
                 } else {
                     Circle()
                         .fill(Color(.systemGray4))
                         .frame(width: 4, height: 4)
                         .opacity(0.3)
                 }
             }
             .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isToday ? .blue : 
                                isSelected ? .blue : .clear, 
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Day Detail Section
    private var dayDetailSection: some View {
        VStack(spacing: 16) {
            if let stepData = getStepData(for: selectedDate) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text(selectedDateString)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if stepData.goalProgressPercentage >= 100 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.orange)
                                Text("Goal Reached!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                                         // Large step count
                     VStack(spacing: 6) {
                         Text(formatStepCount(stepData.estimatedDogSteps))
                             .font(.system(size: 36, weight: .bold, design: .rounded))
                             .foregroundColor(.primary)
                         
                         Text("steps")
                             .font(.system(size: 16, weight: .medium))
                             .foregroundColor(.secondary)
                     }
                    
                    // Progress bar
                    progressBar(for: stepData)
                    
                    // Metrics grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        // Distance metric
                        metricCard(
                            icon: "location.fill",
                            title: "Distance",
                            value: String(format: "%.1f mi", stepData.distanceInKilometers * 0.621371),
                            backgroundColor: .blue.opacity(0.1),
                            iconColor: .blue
                        )
                        
                        // Active time metric
                        metricCard(
                            icon: "clock.fill",
                            title: "Active Time",
                            value: estimatedActiveTime(for: stepData),
                            backgroundColor: .green.opacity(0.1),
                            iconColor: .green
                        )
                        
                        // Human steps metric
                        metricCard(
                            icon: "person.fill",
                            title: "Human Steps",
                            value: formatStepCount(stepData.humanSteps),
                            backgroundColor: .orange.opacity(0.1),
                            iconColor: .orange
                        )
                        
                        // Walk sessions metric
                        metricCard(
                            icon: "figure.walk",
                            title: "Walk Sessions",
                            value: "\(estimatedWalkCount(for: stepData))",
                            backgroundColor: .purple.opacity(0.1),
                            iconColor: .purple
                        )
                    }
                                 }
                 .padding(20)
                 .background(Color(.systemGray6))
                 .cornerRadius(16)
             }
         }
         .padding(.top, 4)
     }
    
    // MARK: - Progress Bar
    private func progressBar(for stepData: StepData) -> some View {
        let goalSteps = stepData.goalSteps
        let progress = min(Double(stepData.estimatedDogSteps) / Double(goalSteps), 1.0)
        
        return VStack(spacing: 12) {
            // Progress text
            HStack {
                Text("\(Int(progress * 100))% of goal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(formatStepCount(goalSteps)) goal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: progress >= 1.0 ? [.green, .green] : [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Metric Card
    private func metricCard(
        icon: String,
        title: String,
        value: String,
        backgroundColor: Color,
        iconColor: Color
    ) -> some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)
            
            // Value and title
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(12)
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
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: startOfWeek)) – \(formatter.string(from: endOfWeek))"
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    private var dayHeaders: [String] {
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
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
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes) min"
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
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(remainingMinutes) min"
    }
    
    private func estimatedWalkCount(for stepData: StepData) -> Int {
        return max(1, stepData.estimatedDogSteps / 2000)
    }
    
    private func formatStepCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.3f", thousands).replacingOccurrences(of: ".000", with: ",000")
                .replacingOccurrences(of: "000", with: ",000")
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(HomeViewModel())
} 