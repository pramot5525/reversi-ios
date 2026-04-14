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
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
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

    @Environment(\.colorScheme) private var colorScheme

    private var bgColor: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.35, blue: 0.22)
            : Color(red: 0.45, green: 0.75, blue: 0.35)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.green.opacity(0.15)
            : Color.green.opacity(0.3)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(bgColor)
                    .border(borderColor, width: 0.5)

                if isValidMove {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .padding(6)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                                .padding(6)
                        )
                }

                AnimalPieceView(state: state, game: game)
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
    }
}
