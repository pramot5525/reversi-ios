import SwiftUI

struct BoardView: View {
    @ObservedObject var game: ReversiGame

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<ReversiGame.boardSize, id: \.self) { row in
                HStack(spacing: 0) {
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.mintAccent.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
    }
}
