import Foundation
import GameKit

/// Codable snapshot of player progress for Game Center cloud sync.
struct PlayerProgress: Codable {
    var unlockedEmojiIDs: [String]
    var totalWins: Int
    var coins: Int
}

@MainActor
class EmojiUnlockManager: ObservableObject {
    static let shared = EmojiUnlockManager()

    static let savedGameName = "reversi_progress"

    // Free emoji: all Animals category + a few extras
    static let freeEmojiIDs: Set<String> = {
        var ids = Set<String>()
        // All Animals (same ranges as ReversiGame.buildCategories)
        let animalRanges: [ClosedRange<UInt32>] = [0x1F400...0x1F43F, 0x1F980...0x1F9AE]
        for range in animalRanges {
            for value in range {
                guard let scalar = Unicode.Scalar(value) else { continue }
                let props = scalar.properties
                guard props.isEmoji && props.isEmojiPresentation else { continue }
                ids.insert(String(scalar))
            }
        }
        return ids
    }()

    @Published var unlockedEmojiIDs: Set<String>
    @Published var totalWins: Int
    @Published var coins: Int
    @Published var lastUnlockedEmoji: PieceOption?
    @Published var showUnlockAlert: Bool = false
    @Published var showCoinEarnedAlert: Bool = false
    @Published var lastCoinsEarned: Int = 0

    private let store = SQLiteStore.shared

    private init() {
        // Load from SQLite
        let savedIDs = store.loadUnlockedEmojiIDs()
        unlockedEmojiIDs = savedIDs.union(Self.freeEmojiIDs)
        totalWins = store.getInt(forKey: "totalWins")
        coins = store.getInt(forKey: "coins")
    }

    // MARK: - Check Status

    func isUnlocked(_ piece: PieceOption) -> Bool {
        Self.freeEmojiIDs.contains(piece.id) || unlockedEmojiIDs.contains(piece.id)
    }

    func isFree(_ piece: PieceOption) -> Bool {
        Self.freeEmojiIDs.contains(piece.id)
    }

    var lockedCount: Int {
        PieceOption.allPieces.filter { !isUnlocked($0) }.count
    }

    var unlockedCount: Int {
        PieceOption.allPieces.filter { isUnlocked($0) }.count
    }

    var allUnlocked: Bool {
        lockedCount == 0
    }

    // MARK: - Coins

    func addCoins(_ amount: Int) {
        coins += amount
        lastCoinsEarned = amount
        showCoinEarnedAlert = true
        save()
    }

    @discardableResult
    func unlockWithCoin(_ piece: PieceOption) -> Bool {
        guard coins >= 1 else { return false }
        guard !isUnlocked(piece) else { return false }

        coins -= 1
        unlockedEmojiIDs.insert(piece.id)
        lastUnlockedEmoji = piece
        showUnlockAlert = true
        save()
        return true
    }

    func recordWin(difficulty: AIDifficulty) {
        totalWins += 1
        let amount = difficulty.coinReward
        coins += amount
        lastCoinsEarned = amount
        showCoinEarnedAlert = true
        save()

        GameCenterManager.shared.submitScore(totalWins)
    }

    // MARK: - Local Persistence (SQLite)

    private func save() {
        store.saveUnlockedEmojiIDs(unlockedEmojiIDs)
        store.setInt(totalWins, forKey: "totalWins")
        store.setInt(coins, forKey: "coins")

        // Also push to Game Center cloud
        saveToGameCenter()
    }

    // MARK: - Game Center Cloud Sync

    /// Encode current progress as JSON Data.
    private func encodeProgress() -> Data? {
        let progress = PlayerProgress(
            unlockedEmojiIDs: Array(unlockedEmojiIDs),
            totalWins: totalWins,
            coins: coins
        )
        return try? JSONEncoder().encode(progress)
    }

    /// Decode progress from JSON Data.
    private func decodeProgress(from data: Data) -> PlayerProgress? {
        try? JSONDecoder().decode(PlayerProgress.self, from: data)
    }

    /// Save progress to Game Center saved games.
    func saveToGameCenter() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        guard let data = encodeProgress() else { return }

        Task {
            do {
                try await GKLocalPlayer.local.saveGameData(data, withName: Self.savedGameName)
            } catch {
                print("Failed to save to Game Center: \(error)")
            }
        }
    }

    /// Load and merge progress from Game Center saved games.
    func syncFromGameCenter() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        do {
            let savedGames = try await GKLocalPlayer.local.fetchSavedGames()
            let matching = savedGames.filter { $0.name == Self.savedGameName }

            if matching.count > 1 {
                // Resolve conflicts: merge all, then save resolved data
                var mergedProgress = currentProgress()
                for game in matching {
                    if let data = try? await game.loadData(),
                       let cloud = decodeProgress(from: data) {
                        mergedProgress = merge(local: mergedProgress, cloud: cloud)
                    }
                }
                applyProgress(mergedProgress)
                save()

                // Resolve the conflict in Game Center
                if let resolvedData = encodeProgress() {
                    try await GKLocalPlayer.local.resolveConflictingSavedGames(matching, with: resolvedData)
                }
            } else if let game = matching.first {
                let data = try await game.loadData()
                if let cloud = decodeProgress(from: data) {
                    let merged = merge(local: currentProgress(), cloud: cloud)
                    applyProgress(merged)
                    save()
                }
            }
        } catch {
            print("Failed to sync from Game Center: \(error)")
        }
    }

    private func currentProgress() -> PlayerProgress {
        PlayerProgress(
            unlockedEmojiIDs: Array(unlockedEmojiIDs),
            totalWins: totalWins,
            coins: coins
        )
    }

    /// Merge strategy: union emoji, max wins, max coins (never lose progress).
    private func merge(local: PlayerProgress, cloud: PlayerProgress) -> PlayerProgress {
        PlayerProgress(
            unlockedEmojiIDs: Array(Set(local.unlockedEmojiIDs).union(Set(cloud.unlockedEmojiIDs))),
            totalWins: max(local.totalWins, cloud.totalWins),
            coins: max(local.coins, cloud.coins)
        )
    }

    private func applyProgress(_ progress: PlayerProgress) {
        unlockedEmojiIDs = Set(progress.unlockedEmojiIDs).union(Self.freeEmojiIDs)
        totalWins = progress.totalWins
        coins = progress.coins
    }
}
