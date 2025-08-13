//
//  WalkActivityAttributes.swift
//  Doggysteps
//
//  Created by Assistant on 07/01/2025.
//

import Foundation
import ActivityKit

// MARK: - Walk Activity Attributes
struct WalkActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data that changes during the walk
        var duration: TimeInterval
        var humanSteps: Int
        var dogSteps: Int
        var distance: Double // in meters
        var pace: String
        var lastUpdated: Date
        
        init(duration: TimeInterval = 0, humanSteps: Int = 0, dogSteps: Int = 0, distance: Double = 0, pace: String = "--'--\"") {
            self.duration = duration
            self.humanSteps = humanSteps
            self.dogSteps = dogSteps
            self.distance = distance
            self.pace = pace
            self.lastUpdated = Date()
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
            return distance / 1000.0
        }
        
        var formattedDistance: String {
            if distanceInKilometers >= 1.0 {
                return String(format: "%.2f km", distanceInKilometers)
            } else {
                return String(format: "%.0f m", distance)
            }
        }
    }
    
    // Static data that doesn't change during the walk
    var dogName: String
    var breedName: String
    var walkStartTime: Date
    var activityId: String
    
    init(dogName: String, breedName: String, walkStartTime: Date = Date()) {
        self.dogName = dogName
        self.breedName = breedName
        self.walkStartTime = walkStartTime
        self.activityId = UUID().uuidString
    }
} 