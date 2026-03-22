import SwiftUI

struct DiscView: View {
    let state: CellState

    @State private var displayedState: CellState = .empty
    @State private var isFlipping: Bool = false
    @State private var showDisc: Bool = false

    private var discColor: Color {
        displayedState == .black ? .black : .white
    }

    private var edgeColor: Color {
        displayedState == .black ? Color(white: 0.25) : Color(white: 0.85)
    }

    var body: some View {
        ZStack {
            if showDisc {
                // Disc with gradient for 3D feel
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [discColor.opacity(0.9), discColor],
                            center: .init(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(edgeColor, lineWidth: 1.5)
                    )
                    .overlay(
                        // Specular highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    center: .init(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 12
                                )
                            )
                            .scaleEffect(0.5)
                            .offset(x: -4, y: -4)
                    )
                    .padding(5)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 2)
                    .rotation3DEffect(
                        .degrees(isFlipping ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: state) { oldValue, newValue in
            if oldValue == .empty && newValue != .empty {
                // New piece — pop in
                displayedState = newValue
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    showDisc = true
                }
            } else if oldValue != .empty && newValue != .empty && oldValue != newValue {
                // Flip — smooth Y-axis rotation
                withAnimation(.easeInOut(duration: 0.4)) {
                    isFlipping = true
                } completion: {
                    displayedState = newValue
                    isFlipping = false
                }
            } else if newValue == .empty {
                // Reset — shrink out
                withAnimation(.easeIn(duration: 0.15)) {
                    showDisc = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    displayedState = .empty
                    isFlipping = false
                }
            }
        }
        .onAppear {
            if state != .empty {
                displayedState = state
                showDisc = true
            }
        }
    }
}

struct CellView: View {
    let state: CellState
    let isValidMove: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.1, green: 0.55, blue: 0.2))
                    .border(Color.black.opacity(0.25), width: 0.5)

                if isValidMove {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        .padding(8)
                }

                DiscView(state: state)
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
    }
}
