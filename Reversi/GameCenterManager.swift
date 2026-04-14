import GameKit

@MainActor
class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    static let leaderboardID = "com.reversi.totalwins"

    @Published var isAuthenticated = false
    @Published var playerName: String = ""

    private init() {}

    // MARK: - Authentication

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error {
                    print("Game Center auth error: \(error.localizedDescription)")
                    return
                }

                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.playerName = GKLocalPlayer.local.displayName

                    // Submit current wins to leaderboard
                    let wins = EmojiUnlockManager.shared.totalWins
                    self?.submitScore(wins)

                    // Sync saved game data from Game Center
                    await EmojiUnlockManager.shared.syncFromGameCenter()
                }
            }
        }
    }

    // MARK: - Leaderboard

    func submitScore(_ wins: Int) {
        guard isAuthenticated else { return }
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    wins,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.leaderboardID]
                )
            } catch {
                print("Failed to submit score: \(error)")
            }
        }
    }

    func showLeaderboard() {
        guard isAuthenticated else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.keyWindow?.rootViewController else { return }
        let gcVC = GKGameCenterViewController(leaderboardID: Self.leaderboardID, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = GameCenterDismisser.shared
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(gcVC, animated: true)
    }
}

// Helper to dismiss Game Center view controller
class GameCenterDismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismisser()

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
