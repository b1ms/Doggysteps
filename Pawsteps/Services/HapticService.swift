import UIKit
import SwiftUI

/// HapticService provides standardized haptic feedback throughout the app
class HapticService {
    static let shared = HapticService()
    
    private init() {}
    
    /// Light haptic feedback for subtle interactions like selections
    func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Medium haptic feedback for button taps and confirmations
    func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Heavy haptic feedback for important actions and completions
    func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    /// Success haptic feedback for successful operations
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Warning haptic feedback for warnings or cautions
    func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Error haptic feedback for errors or failures
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Selection haptic feedback for item selections
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

/// Extension to make it easy to add haptic feedback to SwiftUI Views
extension View {
    /// Adds haptic feedback to any view when tapped
    func hapticFeedback(_ type: HapticFeedbackType = .medium) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticService.shared.light()
            case .medium:
                HapticService.shared.medium()
            case .heavy:
                HapticService.shared.heavy()
            case .success:
                HapticService.shared.success()
            case .warning:
                HapticService.shared.warning()
            case .error:
                HapticService.shared.error()
            case .selection:
                HapticService.shared.selection()
            }
        }
    }
}

/// Types of haptic feedback available
enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}

/// Button style that automatically adds haptic feedback
struct HapticButtonStyle: ButtonStyle {
    let hapticType: HapticFeedbackType
    
    init(_ hapticType: HapticFeedbackType = .medium) {
        self.hapticType = hapticType
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    switch hapticType {
                    case .light:
                        HapticService.shared.light()
                    case .medium:
                        HapticService.shared.medium()
                    case .heavy:
                        HapticService.shared.heavy()
                    case .success:
                        HapticService.shared.success()
                    case .warning:
                        HapticService.shared.warning()
                    case .error:
                        HapticService.shared.error()
                    case .selection:
                        HapticService.shared.selection()
                    }
                }
            }
    }
}

/// Extension to make it easy to apply haptic button style
extension Button {
    func hapticStyle(_ type: HapticFeedbackType = .medium) -> some View {
        self.buttonStyle(HapticButtonStyle(type))
    }
} 