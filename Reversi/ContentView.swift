import SwiftUI

struct ContentView: View {
    @StateObject private var settings = GameSettings.shared
    @StateObject private var store = StoreManager.shared
    @StateObject private var unlockManager = EmojiUnlockManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GameTab()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
                .tag(0)

            TextToEmojiView()
                .tabItem {
                    Image(systemName: "text.bubble.fill")
                    Text("Text")
                }
                .tag(1)

            SettingsView(settings: settings)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .environmentObject(store)
        .environmentObject(unlockManager)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }
}

// MARK: - Game Tab

struct GameTab: View {
    @StateObject private var game = ReversiGame()
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    @State private var gameStarted = false
    @State private var playerSelection: PieceOption = .defaultPlayer

    private var aiPiece: PieceOption {
        let unlocked = PieceOption.allPieces.filter {
            unlockManager.isUnlocked($0) && $0.id != playerSelection.id
        }
        return unlocked.randomElement() ?? .defaultAI
    }

    var body: some View {
        if gameStarted {
            GameView(game: game, onBack: {
                withAnimation { gameStarted = false }
            })
        } else {
            EmojiSelectionView(
                selected: $playerSelection,
                onStart: {
                    game.player1Piece = playerSelection
                    game.player2Piece = aiPiece
                    game.reset()
                    withAnimation { gameStarted = true }
                }
            )
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    @StateObject private var gameCenter = GameCenterManager.shared

    var body: some View {
        NavigationView {
            List {
                // Coin & Collection Progress
                Section {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Coins")
                                .foregroundColor(.primary)
                            Text("\(unlockManager.coins)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Wins")
                                .foregroundColor(.primary)
                            Text("\(unlockManager.totalWins)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Image(systemName: "face.smiling.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Emoji Unlocked")
                                .foregroundColor(.primary)
                            Text("\(unlockManager.unlockedCount) / \(PieceOption.allPieces.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        ProgressView(value: Double(unlockManager.unlockedCount), total: Double(PieceOption.allPieces.count))
                            .frame(width: 80)
                    }
                } header: {
                    Text("Collection")
                } footer: {
                    Text("Win: Easy +2 | Medium +3 | Hard +5 coins")
                }

                // Game Center
                Section {
                    if gameCenter.isAuthenticated {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(gameCenter.playerName)
                                    .foregroundColor(.primary)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        Button {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                var topVC = rootVC
                                while let presented = topVC.presentedViewController { topVC = presented }
                                gameCenter.showLeaderboard()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "list.number")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Leaderboard")
                                    .foregroundColor(.primary)
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Not signed in")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Game Center")
                } footer: {
                    if !gameCenter.isAuthenticated {
                        Text("Sign in to Game Center in Settings to sync progress")
                    }
                }

                // Remove Ads
                Section {
                    if store.isAdsRemoved {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("Ads Removed")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Purchased")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            Task { await store.purchaseRemoveAds() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Remove Ads")
                                        .foregroundColor(.primary)
                                    if let product = store.removeAdsProduct {
                                        Text(product.displayPrice)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                Spacer()
                                if store.isPurchasing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(store.isPurchasing)

                        Button {
                            Task { await store.restorePurchases() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Restore Purchases")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } header: {
                    Text("Ads")
                }

                // Appearance
                Section {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button {
                            withAnimation { settings.appearanceMode = mode }
                        } label: {
                            HStack {
                                Image(systemName: mode == .dark ? "moon.fill" : mode == .light ? "sun.max.fill" : "circle.lefthalf.filled")
                                    .foregroundColor(mode == .dark ? .indigo : mode == .light ? .orange : .gray)
                                    .frame(width: 24)
                                Text(mode.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if settings.appearanceMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                }

                // Sound
                Section {
                    Toggle(isOn: $settings.soundEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(settings.soundEnabled ? .blue : .secondary)
                                .frame(width: 24)
                            Text("Sound Effects")
                        }
                    }
                } header: {
                    Text("Sound")
                }

                // AI Difficulty
                Section {
                    ForEach(AIDifficulty.allCases) { difficulty in
                        Button {
                            withAnimation {
                                settings.aiDifficulty = difficulty
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(difficulty.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("\(difficulty.description) — Win +\(difficulty.coinReward) coins")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if settings.aiDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("AI Difficulty")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Emoji Selection Screen

struct EmojiSelectionView: View {
    @Binding var selected: PieceOption
    let onStart: () -> Void
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    @StateObject private var rewardedAd = RewardedAdManager.shared
    @State private var searchText = ""
    @State private var showLockedAlert = false
    @State private var tappedLockedPiece: PieceOption?

    private var isSearching: Bool { !searchText.isEmpty }

    private var searchResults: [PieceOption] {
        let query = searchText.lowercased()
        return PieceOption.allPieces.filter { $0.unicodeName.contains(query) }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Title + coin badge
            HStack {
                Text("Emoji Reversi")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                // Coin badge
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(unlockManager.coins)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.yellow.opacity(0.15)))
                .foregroundColor(.orange)

                // Unlock progress badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption)
                    Text("\(unlockManager.unlockedCount)/\(PieceOption.allPieces.count)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.purple.opacity(0.15)))
                .foregroundColor(.purple)
            }
            .padding(.top, 8)

            // Selected preview
            HStack(spacing: 12) {
                Text(selected.emoji)
                    .font(.system(size: 48))
                VStack(alignment: .leading) {
                    Text("Your piece")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selected.unicodeName.capitalized)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            )

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search emoji...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )

            // Watch ad for coin button
            if !store.isAdsRemoved && rewardedAd.isAdReady {
                Button {
                    Task {
                        let earned = await rewardedAd.showAd()
                        if earned {
                            unlockManager.addCoins(1)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 14))
                        Text("Watch Ad")
                            .font(.system(size: 14, weight: .semibold))
                        Text("+1")
                            .font(.system(size: 14, weight: .bold))
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundColor(.orange)
                }
            }

            // Emoji grid
            ScrollView {
                if isSearching {
                    if searchResults.isEmpty {
                        Text("No emoji found")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                            ForEach(searchResults) { piece in
                                emojiButton(piece)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } else {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(PieceOption.categories) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                                    ForEach(category.emojis) { piece in
                                        emojiButton(piece)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            Button(action: onStart) {
                HStack {
                    Text(selected.emoji)
                    Text("Start Game!")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
            }

            if !store.isAdsRemoved {
                BannerAdView(adUnitID: AdConstants.bannerAdUnitID)
                    .frame(height: 50)
            }
        }
        .padding()
        // Tap locked emoji → offer to spend 1 coin to unlock it
        .alert("Locked Emoji", isPresented: $showLockedAlert) {
            if unlockManager.coins >= 1 {
                Button("Unlock for 1 Coin") {
                    if let piece = tappedLockedPiece {
                        if unlockManager.unlockWithCoin(piece) {
                            selected = piece
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let piece = tappedLockedPiece {
                if unlockManager.coins >= 1 {
                    Text("\(piece.emoji) is locked!\n\nYou have \(unlockManager.coins) coin\(unlockManager.coins == 1 ? "" : "s"). Spend 1 to unlock?")
                } else {
                    Text("\(piece.emoji) is locked!\n\nYou need coins to unlock emoji.\nWin a game or watch an ad to earn coins.")
                }
            }
        }
        // Unlock celebration
        .alert("Emoji Unlocked!", isPresented: $unlockManager.showUnlockAlert) {
            Button("Use It!") {
                if let piece = unlockManager.lastUnlockedEmoji {
                    selected = piece
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let piece = unlockManager.lastUnlockedEmoji {
                Text("You unlocked \(piece.emoji)!\n\(piece.unicodeName.capitalized)")
            }
        }
    }

    private func emojiButton(_ piece: PieceOption) -> some View {
        let isSelected = piece.id == selected.id
        let isLocked = !unlockManager.isUnlocked(piece)

        return Button {
            if isLocked {
                tappedLockedPiece = piece
                showLockedAlert = true
            } else {
                withAnimation(.spring(response: 0.25)) {
                    selected = piece
                }
                SoundManager.shared.speakEmoji(piece)
            }
        } label: {
            ZStack {
                Text(piece.emoji)
                    .font(.system(size: 28))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.blue.opacity(0.2) :
                                  isLocked ? Color.gray.opacity(0.15) :
                                  Color.gray.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .opacity(isLocked ? 0.35 : 1.0)

                // Lock icon overlay
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .offset(x: 14, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game View

struct GameView: View {
    @ObservedObject var game: ReversiGame
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Emoji Reversi")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                // Coin badge in game
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("\(unlockManager.coins)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.yellow.opacity(0.15)))
            }

            // Score
            HStack(spacing: 30) {
                PieceScoreBadge(
                    piece: game.player1Piece,
                    count: game.blackCount,
                    isActive: game.currentPlayer == .black && !game.gameOver,
                    label: "You"
                )
                PieceScoreBadge(
                    piece: game.player2Piece,
                    count: game.whiteCount,
                    isActive: game.currentPlayer == .white && !game.gameOver,
                    label: "AI"
                )
            }

            // Status (ZStack keeps layout stable)
            ZStack {
                Group {
                    if let winner = game.winner {
                        let piece = game.pieceForPlayer(winner)
                        let whoWon = winner == .black ? "You Win!" : "AI Wins!"
                        Text("\(piece.emoji) \(whoWon)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    } else {
                        Text("It's a Draw!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }
                .opacity(game.gameOver ? 1 : 0)

                HStack(spacing: 8) {
                    ProgressView()
                    Text("\(game.player2Piece.emoji) AI is thinking...")
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .opacity(!game.gameOver && game.isAIThinking ? 1 : 0)

                Text("\(game.player1Piece.emoji) Your Turn")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(!game.gameOver && !game.isAIThinking ? 1 : 0)
            }
            .frame(height: 30)

            // Board
            BoardView(game: game)
                .padding(.horizontal, 8)
                .allowsHitTesting(!game.isAIThinking)

            // New Game button
            Button(action: {
                withAnimation { game.reset() }
            }) {
                Label("New Game", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer()

            if !store.isAdsRemoved {
                BannerAdView(adUnitID: AdConstants.bannerAdUnitID)
                    .frame(height: 50)
            }
        }
        .padding()
        // Coins earned alert (from winning)
        .alert("Coins Earned!", isPresented: $unlockManager.showCoinEarnedAlert) {
            Button("OK") {}
        } message: {
            Text("+\(unlockManager.lastCoinsEarned) coin\(unlockManager.lastCoinsEarned == 1 ? "" : "s")!\nYou now have \(unlockManager.coins) coin\(unlockManager.coins == 1 ? "" : "s").")
        }
    }
}

struct PieceScoreBadge: View {
    let piece: PieceOption
    let count: Int
    let isActive: Bool
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(piece.emoji)
                .font(.system(size: 32))
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.green.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - Text to Emoji View

/// Uses NLEmbedding (Apple's word embeddings) for smart semantic text→emoji matching.
struct TextToEmojiView: View {
    @State private var inputText = ""
    @State private var emojiResult: [(String, String)] = [] // (emoji, source word)
    @State private var isReading = false
    @State private var isConverting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Type your message")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("AI-powered")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.purple)
                    }

                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                // Convert button
                Button {
                    isConverting = true
                    Task.detached {
                        let result = EmojiMatcher.shared.convert(inputText)
                        await MainActor.run {
                            emojiResult = result
                            isConverting = false
                        }
                    }
                } label: {
                    HStack {
                        if isConverting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text("Convert to Emoji")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isConverting)

                // Result
                if !emojiResult.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Result")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                            Spacer()

                            Button {
                                readAllEmoji()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isReading ? "stop.circle.fill" : "play.circle.fill")
                                    Text(isReading ? "Stop" : "Read All")
                                }
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(isReading ? Color.red.opacity(0.15) : Color.blue.opacity(0.15)))
                                .foregroundColor(isReading ? .red : .blue)
                            }

                            Button {
                                UIPasteboard.general.string = emojiResult.map(\.0).joined(separator: " ")
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                                .foregroundColor(.green)
                            }
                        }

                        ScrollView {
                            Text(emojiResult.map(\.0).joined(separator: " "))
                                .font(.system(size: 36))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 8)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                                ForEach(Array(emojiResult.enumerated()), id: \.offset) { _, pair in
                                    VStack(spacing: 2) {
                                        Text(pair.0)
                                            .font(.system(size: 28))
                                        Text(pair.1)
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Text to Emoji")
        }
    }

    private func readAllEmoji() {
        if isReading {
            SoundManager.shared.stop()
            isReading = false
            return
        }

        let names = emojiResult.map { pair in
            if let scalar = pair.0.unicodeScalars.first,
               let name = scalar.properties.name {
                return name.lowercased()
            }
            return pair.1
        }

        let fullText = names.joined(separator: ", ")
        isReading = true
        SoundManager.shared.speakText(fullText) {
            Task { @MainActor in
                self.isReading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
