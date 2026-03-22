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
                            action: {
                                game.placePiece(row: row, col: col)
                            }
                        )
                    }
                }
            }
        }
        .border(Color.black, width: 2)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
