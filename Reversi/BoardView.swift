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
                            action: {
                                game.placePiece(row: row, col: col)
                            }
                        )
                    }
                }
            }
        }
        .border(Color(red: 0.3, green: 0.5, blue: 0.2), width: 3)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
