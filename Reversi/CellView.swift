import SwiftUI

struct AnimalPieceView: View {
    let state: CellState
    let game: ReversiGame

    @State private var displayedState: CellState = .empty
    @State private var showPiece: Bool = false
    @State private var isFlipping: Bool = false

    private var pieceText: String {
        game.pieceForCell(displayedState)
    }

    var body: some View {
        ZStack {
            if showPiece {
                Text(pieceText)
                    .font(.system(size: 28))
                    .scaleEffect(isFlipping ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isFlipping ? 180 : 0))
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: state) { oldValue, newValue in
            if oldValue == .empty && newValue != .empty {
                displayedState = newValue
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    showPiece = true
                }
            } else if oldValue != .empty && newValue != .empty && oldValue != newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlipping = true
                } completion: {
                    displayedState = newValue
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFlipping = false
                    }
                }
            } else if newValue == .empty {
                withAnimation(.easeIn(duration: 0.15)) {
                    showPiece = false
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
                showPiece = true
            }
        }
    }
}

struct CellView: View {
    let state: CellState
    let isValidMove: Bool
    let game: ReversiGame
    let action: () -> Void

    @State private var pulse = false

    private let bgColor = Color(red: 0.75, green: 0.93, blue: 0.80)

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(bgColor)
                    .border(Color.green.opacity(0.2), width: 0.5)

                if isValidMove {
                    Circle()
                        .fill(Color.mintDark.opacity(pulse ? 0.25 : 0.08))
                        .padding(9)
                        .scaleEffect(pulse ? 1.0 : 0.72)
                        .animation(
                            .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                            value: pulse
                        )
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }

                AnimalPieceView(state: state, game: game)
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
    }
}
