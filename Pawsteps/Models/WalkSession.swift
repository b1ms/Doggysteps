//
//  WalkSession.swift
//  Doggysteps
//
//  Created by Bimsara on 08/06/2025.
//

import Foundation

// MARK: - Walk Session Model
struct WalkSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var humanSteps: Int
    var estimatedDogSteps: Int
    var distanceInMeters: Double
    var breedName: String
    var breedMultiplier: Double
    var isActive: Bool
    var usedHealthKit: Bool
    var dataSource: String // "CoreMotion", "HealthKit", or "Hybrid"
    
    init(breedName: String, breedMultiplier: Double) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.duration = 0
        self.humanSteps = 0
        self.estimatedDogSteps = 0
        self.distanceInMeters = 0
        self.breedName = breedName
        self.breedMultiplier = breedMultiplier
        self.isActive = true
        self.usedHealthKit = false
        self.dataSource = "CoreMotion"
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var distanceInKilometers: Double {
        return distanceInMeters / 1000.0
    }
    
    var averagePace: String {
        guard duration > 0 && distanceInMeters > 0 else { return "--'--\"" }
        let paceSecondsPerKm = duration / distanceInKilometers
        let minutes = Int(paceSecondsPerKm) / 60
        let seconds = Int(paceSecondsPerKm) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var summary: String {
        return "\(estimatedDogSteps) dog steps in \(formattedDuration)"
    }
    
    var dataSourceDescription: String {
        switch dataSource {
        case "HealthKit":
            return "📱 HealthKit Data"
        case "CoreMotion":
            return "📲 Motion Sensors"
        case "Hybrid":
            return "🔄 HealthKit + Motion"
        default:
            return "📊 Step Tracking"
        }
    }
    
    var accuracyIndicator: String {
        return usedHealthKit ? "🎯 High Accuracy" : "⚡ Real-time Tracking"
    }
} 