import UIKit

@MainActor
enum HapticManager {
    static func tap() {
        guard GameSettings.shared.hapticsEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func place() {
        guard GameSettings.shared.hapticsEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    static func win() {
        guard GameSettings.shared.hapticsEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func lose() {
        guard GameSettings.shared.hapticsEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.error)
    }

    static func warning() {
        guard GameSettings.shared.hapticsEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }
}
