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

// MARK: - Glossy Modifiers

/// White→pale-mint gradient surface with soft shadow and a glossy top highlight.
struct GlossyCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
        )
    }
}

/// Glossy gradient button surface with tinted shadow and top highlight.
struct GlossyButton: ViewModifier {
    var cornerRadius: CGFloat = 14
    var gradient: LinearGradient = Theme.buttonGradient
    var shadowColor: Color = Theme.mintDeep
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: shadowColor.opacity(0.40), radius: 8, y: 4)
        )
    }
}

/// Frosted tinted capsule for badges. Uses a true SwiftUI material so it
/// adapts to the backdrop and light/dark mode, with a subtle color wash.
struct GlassChip: ViewModifier {
    var tint: Color
    func body(content: Content) -> some View {
        content
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(Capsule().fill(tint.opacity(0.18)))
            }
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
            )
    }
}

/// Solid-color capsule with a glossy top highlight (for the turn indicator chip).
struct GlossyPill: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content.background(
            Capsule()
                .fill(color)
                .overlay(
                    Capsule().fill(
                        LinearGradient(colors: [Color.white.opacity(0.35), Color.clear],
                                       startPoint: .top, endPoint: .center)
                    )
                )
                .shadow(color: color.opacity(0.40), radius: 6, y: 3)
        )
    }
}

extension View {
    func glossyCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlossyCard(cornerRadius: cornerRadius))
    }
    func glossyButton(cornerRadius: CGFloat = 14,
                      gradient: LinearGradient = Theme.buttonGradient,
                      shadowColor: Color = Theme.mintDeep) -> some View {
        modifier(GlossyButton(cornerRadius: cornerRadius, gradient: gradient, shadowColor: shadowColor))
    }
    func glassChip(tint: Color) -> some View {
        modifier(GlassChip(tint: tint))
    }
    func glossyPill(color: Color) -> some View {
        modifier(GlossyPill(color: color))
    }
}

// MARK: - Animated Background

/// Slowly drifting mint gradient. Falls back to a static gradient under Reduce Motion.
struct AnimatedBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: Theme.bgColors,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                // Oversize so rotation never exposes empty corners.
                .frame(width: geo.size.width * 1.5, height: geo.size.height * 1.5)
                .rotationEffect(.degrees(animate ? 18 : -18))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
