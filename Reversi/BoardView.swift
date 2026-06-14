import SwiftUI

struct BoardView: View {
    @ObservedObject var game: ReversiGame

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<ReversiGame.boardSize, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<ReversiGame.boardSize, id: \.self) { col in
                        CellView(
                            state: game.board[row][col],
                            isValidMove: game.isValidMove(row: row, col: col),
                            game: game,
                            action: { game.placePiece(row: row, col: col) }
                        )
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.boardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: Theme.mintDeep.opacity(0.40), radius: 10, y: 5)
        )
    }
}
