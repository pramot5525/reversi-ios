import Foundation

// MARK: - Piece Option (any emoji!)

struct EmojiCategory: Identifiable {
    let id: String
    var name: String { id }
    let emojis: [PieceOption]
}

struct PieceOption: Equatable, Identifiable {
    let id: String
    var emoji: String { id }
    
    /// Unicode name for search (e.g. "DOG FACE" -> "dog face")
    var unicodeName: String {
        guard let scalar = id.unicodeScalars.first else { return "" }
        return scalar.properties.name?.lowercased() ?? ""
    }
    
    // All emoji categories, generated from Unicode ranges
    static let categories: [EmojiCategory] = buildCategories()
    
    static let allPieces: [PieceOption] = categories.flatMap(\.emojis)
    
    static let defaultPlayer = PieceOption(id: "🦫")
    static let defaultAI = PieceOption(id: "🦎")
    
    private static func buildCategories() -> [EmojiCategory] {
        // (category name, Unicode ranges)
        let specs: [(String, [ClosedRange<UInt32>])] = [
            ("Smileys", [0x1F600...0x1F64F]),
            ("People", [0x1F466...0x1F487, 0x1F9B0...0x1F9B9, 0x1F9D0...0x1F9FF]),
            ("Animals", [0x1F400...0x1F43F, 0x1F980...0x1F9AE]),
            ("Plants", [0x1F330...0x1F343, 0x1F490...0x1F4AE, 0x1F3F5...0x1F3F5]),
            ("Food", [0x1F344...0x1F37F, 0x1F950...0x1F97F, 0x1F9C0...0x1F9CF]),
            ("Travel", [0x1F680...0x1F6FF]),
            ("Activities", [0x1F3A0...0x1F3CF, 0x26BD...0x26BE, 0x1F94A...0x1F94F]),
            ("Objects", [0x1F4A0...0x1F4FF, 0x1F500...0x1F5FF]),
            ("Symbols", [0x2600...0x26FF, 0x2700...0x27BF, 0x1F300...0x1F32F]),
            ("Hearts", [0x2764...0x2764, 0x1F493...0x1F49F, 0x1FA70...0x1FA7C]),
            ("Flags", [0x1F1E0...0x1F1FF]),
            ("Extras", [0x1F900...0x1F94F, 0x1FA80...0x1FAFF]),
        ]
        
        var result: [EmojiCategory] = []
        var seen = Set<String>()
        
        for (name, ranges) in specs {
            var pieces: [PieceOption] = []
            for range in ranges {
                for value in range {
                    guard let scalar = Unicode.Scalar(value) else { continue }
                    let props = scalar.properties
                    guard props.isEmoji && props.isEmojiPresentation else { continue }
                    let str = String(scalar)
                    guard !seen.contains(str) else { continue }
                    seen.insert(str)
                    pieces.append(PieceOption(id: str))
                }
            }
            if !pieces.isEmpty {
                result.append(EmojiCategory(id: name, emojis: pieces))
            }
        }
        
        return result
    }
}

enum Player: Int {
    case black = 1
    case white = -1

    var opposite: Player {
        self == .black ? .white : .black
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

    var notation: String {
        let colLetter = String(UnicodeScalar("A".unicodeScalars.first!.value + UInt32(col))!)
        return "\(colLetter)\(row + 1)"
    }
}

struct MoveRecord: Identifiable {
    let id = UUID()
    let player: Player
    let position: Position
    let timestamp: Date
}

struct GameSnapshot {
    let board: [[CellState]]
    let currentPlayer: Player
    let gameOver: Bool
    let winner: Player?
    let blackCount: Int
    let whiteCount: Int
}

@MainActor
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
    @Published var moveHistory: [MoveRecord] = []

    // Piece for each player (any emoji!)
    @Published var player1Piece: PieceOption = .defaultPlayer
    @Published var player2Piece: PieceOption = .defaultAI

    private var undoStack: [GameSnapshot] = []

    // Player 2 is always AI
    private let aiPlayer: Player = .white

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
    
    func pieceForPlayer(_ player: Player) -> PieceOption {
        player == .black ? player1Piece : player2Piece
    }
    
    func pieceForCell(_ state: CellState) -> String {
        switch state {
        case .black: return player1Piece.emoji
        case .white: return player2Piece.emoji
        case .empty: return ""
        }
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
        isAIThinking = false
        moveHistory = []
        undoStack = []
        setupInitialPieces()
        updateCounts()
        updateValidMoves()
    }

    private func saveSnapshot() {
        undoStack.append(GameSnapshot(
            board: board, currentPlayer: currentPlayer,
            gameOver: gameOver, winner: winner,
            blackCount: blackCount, whiteCount: whiteCount
        ))
    }

    var canUndo: Bool { !undoStack.isEmpty && !isAIThinking }

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        board = snapshot.board
        currentPlayer = snapshot.currentPlayer
        gameOver = snapshot.gameOver
        winner = snapshot.winner
        blackCount = snapshot.blackCount
        whiteCount = snapshot.whiteCount
        if !moveHistory.isEmpty { moveHistory.removeLast() }
        // If we undid an AI move too, undo the player's move as well
        if currentPlayer == aiPlayer, let prev = undoStack.popLast() {
            board = prev.board
            currentPlayer = prev.currentPlayer
            gameOver = prev.gameOver
            winner = prev.winner
            blackCount = prev.blackCount
            whiteCount = prev.whiteCount
            if !moveHistory.isEmpty { moveHistory.removeLast() }
        }
        updateValidMoves()
    }

    func placePiece(row: Int, col: Int) {
        guard !gameOver else { return }
        guard row >= 0 && row < Self.boardSize && col >= 0 && col < Self.boardSize else { return }
        guard board[row][col] == .empty else { return }

        let flipped = flippedPieces(row: row, col: col, player: currentPlayer)
        guard !flipped.isEmpty else { return }

        saveSnapshot()
        moveHistory.append(MoveRecord(player: currentPlayer, position: Position(row: row, col: col), timestamp: Date()))

        // Speak the piece sound
        SoundManager.shared.speakPiece(pieceForPlayer(currentPlayer))
        
        let cellState: CellState = currentPlayer == .black ? .black : .white
        board[row][col] = cellState
        for pos in flipped {
            board[pos.row][pos.col] = cellState
        }

        currentPlayer = currentPlayer.opposite
        updateCounts()

        let nextMoves = allValidMoves(for: currentPlayer)
        if nextMoves.isEmpty {
            currentPlayer = currentPlayer.opposite
            let originalMoves = allValidMoves(for: currentPlayer)
            if originalMoves.isEmpty {
                gameOver = true
                if blackCount > whiteCount {
                    winner = .black
                    SoundManager.shared.speakWinner(player1Piece)
                    // Player wins  earn coins based on difficulty
                    Task { @MainActor in
                        EmojiUnlockManager.shared.recordWin(difficulty: GameSettings.shared.aiDifficulty)
                    }
                } else if whiteCount > blackCount {
                    winner = .white
                    SoundManager.shared.speakWinner(player2Piece)
                } else {
                    winner = nil
                }
            }
        }

        updateValidMoves()
        triggerAIMoveIfNeeded()
    }

    // MARK: - AI (Player 2)

    private func triggerAIMoveIfNeeded() {
        guard !gameOver, currentPlayer == aiPlayer else { return }
        isAIThinking = true
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            self.performAIMove()
            self.isAIThinking = false
        }
    }

    private func performAIMove() {
        guard !gameOver, currentPlayer == aiPlayer else { return }
        let moves = allValidMoves(for: currentPlayer)
        guard !moves.isEmpty else { return }

        let chosen: Position
        switch GameSettings.shared.aiDifficulty {
        case .easy:
            // Random move
            chosen = moves.randomElement()!
        case .medium:
            // Greedy: pick the move that flips the most pieces
            chosen = moves.max(by: {
                flippedPieces(row: $0.row, col: $0.col, player: currentPlayer).count <
                flippedPieces(row: $1.row, col: $1.col, player: currentPlayer).count
            })!
        case .hard:
            // Minimax with corner/edge weighting
            chosen = bestMoveHard(moves: moves)
        }
        placePiece(row: chosen.row, col: chosen.col)
    }

    // MARK: - Hard AI (positional weights + lookahead)

    private static let positionWeights: [[Int]] = [
        [100, -20,  10,   5,   5,  10, -20, 100],
        [-20, -40,  -5,  -5,  -5,  -5, -40, -20],
        [ 10,  -5,   5,   3,   3,   5,  -5,  10],
        [  5,  -5,   3,   3,   3,   3,  -5,   5],
        [  5,  -5,   3,   3,   3,   3,  -5,   5],
        [ 10,  -5,   5,   3,   3,   5,  -5,  10],
        [-20, -40,  -5,  -5,  -5,  -5, -40, -20],
        [100, -20,  10,   5,   5,  10, -20, 100],
    ]

    private func bestMoveHard(moves: [Position]) -> Position {
        var bestScore = Int.min
        var bestMove = moves[0]

        for move in moves {
            let score = evaluateMove(move, player: currentPlayer, depth: 3)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }

    private func evaluateMove(_ move: Position, player: Player, depth: Int) -> Int {
        // Simulate the move on a copy
        var simBoard = board
        let flipped = flippedPieces(row: move.row, col: move.col, player: player)
        let cellState: CellState = player == .black ? .black : .white

        simBoard[move.row][move.col] = cellState
        for pos in flipped {
            simBoard[pos.row][pos.col] = cellState
        }

        // Score = positional weight of placed piece + flipped pieces' weights
        var score = Self.positionWeights[move.row][move.col]
        for pos in flipped {
            score += Self.positionWeights[pos.row][pos.col]
        }

        // Simple lookahead: subtract opponent's best response
        if depth > 0 {
            let opponent = player.opposite
            let opponentMoves = allValidMovesOn(board: simBoard, for: opponent)
            if !opponentMoves.isEmpty {
                let opponentBest = opponentMoves.map { m -> Int in
                    let f = flippedPiecesOn(board: simBoard, row: m.row, col: m.col, player: opponent)
                    var s = Self.positionWeights[m.row][m.col]
                    for p in f { s += Self.positionWeights[p.row][p.col] }
                    return s
                }.max() ?? 0
                score -= opponentBest
            }
        }

        return score
    }

    private func allValidMovesOn(board: [[CellState]], for player: Player) -> [Position] {
        var moves: [Position] = []
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                if board[row][col] == .empty && !flippedPiecesOn(board: board, row: row, col: col, player: player).isEmpty {
                    moves.append(Position(row: row, col: col))
                }
            }
        }
        return moves
    }

    private func flippedPiecesOn(board: [[CellState]], row: Int, col: Int, player: Player) -> [Position] {
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
