import SwiftUI

// MARK: - Theme

/// Central source of truth for the glossy mint visual language.
/// Existing `mint*` colors remain defined in ContentView.swift; this enum adds
/// the richer gradient endpoints and named gradients introduced by the redesign.
enum Theme {
    // Richer gradient endpoints
    static let mintRich  = Color(red: 0.24, green: 0.82, blue: 0.48) // #3ED17A
    static let mintDeep  = Color(red: 0.12, green: 0.48, blue: 0.28) // #1F7A48
    static let mintPale  = Color(red: 0.92, green: 1.00, blue: 0.95) // #EAFFF2
    static let boardHigh = Color(red: 0.28, green: 0.77, blue: 0.50) // #48C47F
    static let boardLow  = Color(red: 0.17, green: 0.57, blue: 0.35) // #2B9159

    // MARK: Named gradients
    static let buttonGradient = LinearGradient(
        colors: [mintRich, mintDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardGradient = LinearGradient(
        colors: [.white, mintPale],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cellGradient = LinearGradient(
        colors: [.white, Color(red: 0.91, green: 0.98, blue: 0.93)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cellSelectedGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 1.00, blue: 0.90),
                 Color(red: 0.68, green: 0.94, blue: 0.77)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let boardGradient = LinearGradient(
        colors: [boardHigh, boardLow],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Background gradient stops (consumed by AnimatedBackground)
    static let bgColors: [Color] = [
        Color(red: 0.89, green: 0.98, blue: 0.92),
        Color(red: 0.76, green: 0.94, blue: 0.82),
        Color(red: 0.75, green: 0.92, blue: 0.90),
        Color(red: 0.83, green: 0.95, blue: 0.87)
    ]
}
