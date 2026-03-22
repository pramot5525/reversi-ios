import Foundation
import Combine

enum Player: Int {
    case black = 1
    case white = -1

    var opposite: Player {
        self == .black ? .white : .black
    }

    var name: String {
        self == .black ? "Black" : "White"
    }

    var symbol: String {
        self == .black ? "⚫" : "⚪"
    }
}

enum CellState: Int {
    case empty = 0
    case black = 1
    case white = -1
}

struct Position: Equatable {
    let row: Int
    let col: Int
}

class ReversiGame: ObservableObject {
    static let boardSize = 8

    @Published var board: [[CellState]]
    @Published var currentPlayer: Player = .black
    @Published var gameOver: Bool = false
    @Published var winner: Player? = nil
    @Published var blackCount: Int = 2
    @Published var whiteCount: Int = 2
    @Published var validMoves: [Position] = []
    @Published var isAIThinking: Bool = false

    /// Set this to a player to make the AI control that side (.white by default)
    var aiPlayer: Player? = .white

    private let directions: [(Int, Int)] = [
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1),           (0, 1),
        (1, -1),  (1, 0),  (1, 1)
    ]

    init() {
        board = Array(repeating: Array(repeating: CellState.empty, count: Self.boardSize), count: Self.boardSize)
        setupInitialPieces()
        updateValidMoves()
    }

    private func setupInitialPieces() {
        let mid = Self.boardSize / 2
        board[mid - 1][mid - 1] = .white
        board[mid - 1][mid] = .black
        board[mid][mid - 1] = .black
        board[mid][mid] = .white
    }

    func reset() {
        board = Array(repeating: Array(repeating: CellState.empty, count: Self.boardSize), count: Self.boardSize)
        currentPlayer = .black
        gameOver = false
        winner = nil
        setupInitialPieces()
        updateCounts()
        updateValidMoves()
        triggerAIMoveIfNeeded()
    }

    func placePiece(row: Int, col: Int) {
        guard !gameOver else { return }
        guard board[row][col] == .empty else { return }

        let flipped = flippedPieces(row: row, col: col, player: currentPlayer)
        guard !flipped.isEmpty else { return }

        let cellState: CellState = currentPlayer == .black ? .black : .white
        board[row][col] = cellState
        for pos in flipped {
            board[pos.row][pos.col] = cellState
        }

        currentPlayer = currentPlayer.opposite
        updateCounts()

        // Check if next player has valid moves
        let nextMoves = allValidMoves(for: currentPlayer)
        if nextMoves.isEmpty {
            // Pass turn back
            currentPlayer = currentPlayer.opposite
            let originalMoves = allValidMoves(for: currentPlayer)
            if originalMoves.isEmpty {
                // Neither player can move — game over
                gameOver = true
                if blackCount > whiteCount {
                    winner = .black
                } else if whiteCount > blackCount {
                    winner = .white
                } else {
                    winner = nil // draw
                }
            }
        }

        updateValidMoves()
        triggerAIMoveIfNeeded()
    }

    // MARK: - AI

    private func triggerAIMoveIfNeeded() {
        guard !gameOver, currentPlayer == aiPlayer else { return }
        isAIThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performAIMove()
            self?.isAIThinking = false
        }
    }

    private func performAIMove() {
        guard !gameOver, currentPlayer == aiPlayer else { return }
        let moves = allValidMoves(for: currentPlayer)
        guard !moves.isEmpty else { return }

        // Greedy: pick the move that flips the most pieces
        let best = moves.max(by: {
            flippedPieces(row: $0.row, col: $0.col, player: currentPlayer).count <
            flippedPieces(row: $1.row, col: $1.col, player: currentPlayer).count
        })!
        placePiece(row: best.row, col: best.col)
    }

    func isValidMove(row: Int, col: Int) -> Bool {
        validMoves.contains(where: { $0.row == row && $0.col == col })
    }

    private func updateValidMoves() {
        validMoves = allValidMoves(for: currentPlayer)
    }

    private func allValidMoves(for player: Player) -> [Position] {
        var moves: [Position] = []
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                if board[row][col] == .empty && !flippedPieces(row: row, col: col, player: player).isEmpty {
                    moves.append(Position(row: row, col: col))
                }
            }
        }
        return moves
    }

    private func flippedPieces(row: Int, col: Int, player: Player) -> [Position] {
        var allFlipped: [Position] = []
        let playerCell: CellState = player == .black ? .black : .white
        let opponentCell: CellState = player == .black ? .white : .black

        for (dr, dc) in directions {
            var flipped: [Position] = []
            var r = row + dr
            var c = col + dc

            while r >= 0 && r < Self.boardSize && c >= 0 && c < Self.boardSize && board[r][c] == opponentCell {
                flipped.append(Position(row: r, col: c))
                r += dr
                c += dc
            }

            if !flipped.isEmpty && r >= 0 && r < Self.boardSize && c >= 0 && c < Self.boardSize && board[r][c] == playerCell {
                allFlipped.append(contentsOf: flipped)
            }
        }

        return allFlipped
    }

    private func updateCounts() {
        var b = 0, w = 0
        for row in board {
            for cell in row {
                if cell == .black { b += 1 }
                else if cell == .white { w += 1 }
            }
        }
        blackCount = b
        whiteCount = w
    }
}
