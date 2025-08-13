//
//  PawstepsLiveActivity.swift
//  PawstepsWidgets
//
//  Created by Assistant on 07/01/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PawstepsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.dogName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Walking")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("\(context.state.humanSteps)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Human Steps")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Link(destination: URL(string: "doggysteps://open")!) {
                            Text("Open App")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        Link(destination: URL(string: "doggysteps://stopwalk")!) {
                            Text("Stop Walk")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("Walking")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } minimal: {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WalkActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact Header
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "figure.walk")
                        .foregroundStyle(Color.blue)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Walking with \(context.attributes.dogName)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    
                    Text(context.attributes.breedName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Compact Live indicator
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.red)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.1))
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Compact Action buttons with working links
            HStack(spacing: 8) {
                Link(destination: URL(string: "doggysteps://open")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "app.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Open App")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                
                Link(destination: URL(string: "doggysteps://stopwalk")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Stop Walk")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Compact Metric View Component
struct CompactMetricView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 10, weight: .semibold))
            }
            
            VStack(spacing: 1) {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview Support
extension WalkActivityAttributes {
    static var preview: WalkActivityAttributes {
        WalkActivityAttributes(dogName: "Buddy", breedName: "Golden Retriever")
    }
}

#Preview("Lock Screen", as: .content, using: WalkActivityAttributes.preview) {
    PawstepsLiveActivity()
} contentStates: {
    WalkActivityAttributes.ContentState(
        duration: 1845, // 30 minutes 45 seconds
        humanSteps: 2543,
        dogSteps: 3821,
        distance: 1250.5, // 1.25 km
        pace: "12'34\""
    )
}

