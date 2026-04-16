import SwiftUI

// MARK: - Theme

extension Color {
    // Light pastel green theme
    static let mintBG       = Color(red: 0.85, green: 0.96, blue: 0.88)
    static let mintBoard    = Color(red: 0.75, green: 0.93, blue: 0.80)
    static let mintCard     = Color.white
    static let mintAccent   = Color(red: 0.20, green: 0.70, blue: 0.40)
    static let mintDark     = Color(red: 0.15, green: 0.50, blue: 0.30)
    static let mintPurple   = Color(red: 0.45, green: 0.30, blue: 0.75)
    static let mintGold     = Color(red: 0.90, green: 0.70, blue: 0.10)

    // Keep legacy names for compatibility
    static let arcadeBG     = mintBG
    static let arcadeCard   = mintCard
    static let arcadeGreen  = mintAccent
    static let arcadeBlue   = Color(red: 0.20, green: 0.55, blue: 0.85)
    static let arcadeGold   = mintGold
    static let arcadePurple = mintPurple
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var settings = GameSettings.shared
    @StateObject private var store = StoreManager.shared
    @StateObject private var unlockManager = EmojiUnlockManager.shared
    var body: some View {
        GameTab()
            .background(Color.mintBG.ignoresSafeArea())
            .environmentObject(store)
            .environmentObject(unlockManager)
    }
}

// MARK: - Game Tab

struct GameTab: View {
    @StateObject private var game = ReversiGame()
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    @State private var gameStarted = false
    @State private var playerSelection: PieceOption = .defaultPlayer
    @State private var showSettings = false

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
            }, showSettings: $showSettings)
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: GameSettings.shared)
                    .environmentObject(StoreManager.shared)
                    .environmentObject(unlockManager)
            }
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

// MARK: - Emoji Selection (Home Screen)

struct EmojiSelectionView: View {
    @Binding var selected: PieceOption
    let onStart: () -> Void
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    @StateObject private var rewardedAd = RewardedAdManager.shared
    @State private var searchText = ""
    @State private var showLockedAlert = false
    @State private var tappedLockedPiece: PieceOption?
    @State private var pulse = false
    @State private var showSettings = false

    private var isSearching: Bool { !searchText.isEmpty }

    private var searchResults: [PieceOption] {
        PieceOption.allPieces.filter { $0.unicodeName.contains(searchText.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("REVERMOJI")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.mintPurple)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.mintPurple.opacity(0.6))
                    }
                    statBadge(icon: "dollarsign.circle.fill", value: "\(unlockManager.coins)", color: .mintGold)
                    statBadge(icon: "lock.open.fill", value: "\(unlockManager.unlockedCount)/\(PieceOption.allPieces.count)", color: .mintPurple)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // Selected piece card
            HStack(spacing: 14) {
                Text(selected.emoji)
                    .font(.system(size: 54))
                    .scaleEffect(pulse ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }

                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR PIECE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(2.5)
                        .foregroundColor(.mintDark.opacity(0.5))
                    Text(selected.unicodeName.capitalized)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                Spacer()

                if !store.isAdsRemoved && rewardedAd.isAdReady {
                    Button {
                        Task {
                            if await rewardedAd.showAd() { unlockManager.addCoins(1) }
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 18))
                            Text("+1 coin")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.mintGold)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.mintGold.opacity(0.10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mintGold.opacity(0.3), lineWidth: 1))
                        )
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                TextField("", text: $searchText,
                          prompt: Text("Search emoji...").foregroundColor(.gray.opacity(0.5)))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.4))
                    }.buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // Emoji grid
            ScrollView(showsIndicators: false) {
                if isSearching {
                    if searchResults.isEmpty {
                        Text("No emoji found")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        emojiGrid(searchResults)
                            .padding(.horizontal, 20)
                    }
                } else {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(PieceOption.categories) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.name.uppercased())
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .tracking(2.5)
                                    .foregroundColor(.mintDark.opacity(0.45))
                                    .padding(.leading, 2)
                                emojiGrid(category.emojis)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Text(selected.emoji).font(.system(size: 22))
                        Text("START GAME")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.mintDark)
                            .shadow(color: .mintDark.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 4)

                if !store.isAdsRemoved {
                    BannerAdView(adUnitID: AdConstants.bannerAdUnitID).frame(height: 50)
                }
            }
            .background(Color.mintBG)
        }
        .background(Color.mintBG.ignoresSafeArea())
        .alert("Locked Emoji", isPresented: $showLockedAlert) {
            if unlockManager.coins >= 1 {
                Button("Unlock for 1 Coin") {
                    if let piece = tappedLockedPiece, unlockManager.unlockWithCoin(piece) {
                        selected = piece
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let piece = tappedLockedPiece {
                Text(unlockManager.coins >= 1
                     ? "\(piece.emoji) is locked!\n\nYou have \(unlockManager.coins) coin\(unlockManager.coins == 1 ? "" : "s"). Spend 1 to unlock?"
                     : "\(piece.emoji) is locked!\n\nWin a game or watch an ad to earn coins.")
            }
        }
        .alert("Emoji Unlocked!", isPresented: $unlockManager.showUnlockAlert) {
            Button("Use It!") { if let p = unlockManager.lastUnlockedEmoji { selected = p } }
            Button("OK", role: .cancel) {}
        } message: {
            if let p = unlockManager.lastUnlockedEmoji {
                Text("You unlocked \(p.emoji)!\n\(p.unicodeName.capitalized)")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: GameSettings.shared)
                .environmentObject(store)
                .environmentObject(unlockManager)
        }
    }

    @ViewBuilder
    private func emojiGrid(_ pieces: [PieceOption]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
            ForEach(pieces) { piece in emojiButton(piece) }
        }
    }

    private func emojiButton(_ piece: PieceOption) -> some View {
        let isSelected = piece.id == selected.id
        let isLocked   = !unlockManager.isUnlocked(piece)

        return Button {
            if isLocked {
                tappedLockedPiece = piece
                showLockedAlert = true
            } else {
                withAnimation(.spring(response: 0.25)) { selected = piece }
                SoundManager.shared.speakEmoji(piece)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(piece.emoji)
                    .font(.system(size: 25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected
                                  ? Color.mintAccent.opacity(0.15)
                                  : Color.white.opacity(isLocked ? 0.4 : 0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.mintAccent : Color.clear, lineWidth: 1.5)
                    )
                    .shadow(color: isSelected ? .mintAccent.opacity(0.3) : .black.opacity(0.04), radius: 4)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .opacity(isLocked ? 0.35 : 1.0)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.gray.opacity(0.6))
                        .offset(x: -2, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func statBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11))
            Text(value).font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.10)))
    }
}

// MARK: - Game View

struct GameView: View {
    @ObservedObject var game: ReversiGame
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var unlockManager: EmojiUnlockManager
    let onBack: () -> Void
    @Binding var showSettings: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                // Top bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.mintPurple)
                    }

                    Spacer()

                    Text("REVERMOJI")
                        .font(.system(size: 18, weight: .heavy, design: .rounded).italic())
                        .foregroundColor(.mintPurple)

                    Spacer()

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.mintPurple.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Current turn + Live score
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CURRENT TURN")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)

                        if game.gameOver {
                            if let winner = game.winner {
                                let isPlayer = winner == .black
                                HStack(spacing: 6) {
                                    Text(game.pieceForPlayer(winner).emoji)
                                        .font(.system(size: 16))
                                    Text(isPlayer ? "YOU WIN!" : "AI WINS!")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(isPlayer ? Color.mintAccent : Color.red.opacity(0.7)))
                            } else {
                                Text("DRAW!")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.orange))
                            }
                        } else if game.isAIThinking {
                            HStack(spacing: 6) {
                                Text(game.player2Piece.emoji).font(.system(size: 16))
                                Text("AI THINKING...")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                ProgressView().scaleEffect(0.7).tint(.white)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.mintAccent))
                        } else {
                            HStack(spacing: 6) {
                                Text(game.player1Piece.emoji).font(.system(size: 16))
                                Text("\(game.player1Piece.unicodeName.uppercased())'S TURN")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.mintAccent))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("LIVE SCORE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            ScoreBox(emoji: game.player1Piece.emoji, count: game.blackCount)
                            ScoreBox(emoji: game.player2Piece.emoji, count: game.whiteCount)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Board
                BoardView(game: game)
                    .padding(.horizontal, 12)
                    .allowsHitTesting(!game.isAIThinking)

                // Resign button
                Button {
                    withAnimation {
                        game.gameOver = true
                        game.winner = .white
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("RESIGN")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mintDark)
                    )
                }
                .disabled(game.gameOver)
                .opacity(game.gameOver ? 0.5 : 1.0)
                .padding(.horizontal, 20)

                // New Game button (when game over)
                if game.gameOver {
                    Button {
                        withAnimation { game.reset() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .bold))
                            Text("NEW GAME")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mintAccent)
                        )
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !store.isAdsRemoved {
                BannerAdView(adUnitID: AdConstants.bannerAdUnitID)
                    .frame(height: 50)
                    .background(Color.mintBG)
            }
        }
        .background(Color.mintBG.ignoresSafeArea())
        .alert("Coins Earned!", isPresented: $unlockManager.showCoinEarnedAlert) {
            Button("OK") {}
        } message: {
            Text("+\(unlockManager.lastCoinsEarned) coin\(unlockManager.lastCoinsEarned == 1 ? "" : "s")!\nYou now have \(unlockManager.coins).")
        }
    }

}

// MARK: - Score Box

struct ScoreBox: View {
    let emoji: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji).font(.system(size: 18))
            Text("\(count)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
        )
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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Collection
                    settingsCard(title: "COLLECTION", accent: .mintGold,
                                 footer: "Win: Easy +2 / Medium +3 / Hard +5 coins") {
                        settingsRow(icon: "dollarsign.circle.fill", iconColor: .mintGold, title: "Coins") {
                            Text("\(unlockManager.coins)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.mintGold)
                        }
                        rowDivider()
                        settingsRow(icon: "trophy.fill", iconColor: .orange, title: "Total Wins") {
                            Text("\(unlockManager.totalWins)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        rowDivider()
                        settingsRow(icon: "face.smiling.fill", iconColor: .mintPurple, title: "Emoji Unlocked") {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(unlockManager.unlockedCount)/\(PieceOption.allPieces.count)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.mintPurple)
                                ProgressView(value: Double(unlockManager.unlockedCount),
                                             total: Double(PieceOption.allPieces.count))
                                    .tint(.mintPurple)
                                    .frame(width: 70)
                            }
                        }
                    }

                    // Ads
                    settingsCard(title: "ADS", accent: .red, footer: "") {
                        if store.isAdsRemoved {
                            settingsRow(icon: "checkmark.seal.fill", iconColor: .mintAccent,
                                        title: "Ads Removed") {
                                Text("PURCHASED")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .tracking(1.5)
                                    .foregroundColor(.mintAccent)
                            }
                        } else {
                            Button { Task { await store.purchaseRemoveAds() } } label: {
                                settingsRow(icon: "xmark.circle.fill", iconColor: .red,
                                            title: "Remove Ads") {
                                    if let product = store.removeAdsProduct {
                                        Text(product.displayPrice)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(.mintGold)
                                    } else if store.isPurchasing {
                                        ProgressView().tint(.mintGold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(store.isPurchasing)

                            rowDivider()

                            Button { Task { await store.restorePurchases() } } label: {
                                settingsRow(icon: "arrow.clockwise", iconColor: .mintAccent,
                                            title: "Restore Purchases") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }.buttonStyle(.plain)
                        }
                    }

                    // Sound
                    settingsCard(title: "SOUND", accent: .mintAccent, footer: "") {
                        settingsRow(
                            icon: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            iconColor: settings.soundEnabled ? .mintAccent : .gray,
                            title: "Sound Effects"
                        ) {
                            Toggle("", isOn: $settings.soundEnabled)
                                .labelsHidden()
                                .tint(.mintAccent)
                        }
                    }

                    // AI Difficulty
                    settingsCard(title: "AI DIFFICULTY", accent: .red, footer: "") {
                        ForEach(Array(AIDifficulty.allCases.enumerated()), id: \.element.id) { i, difficulty in
                            if i > 0 { rowDivider() }
                            Button { withAnimation { settings.aiDifficulty = difficulty } } label: {
                                settingsRow(
                                    icon: difficulty == .easy ? "tortoise.fill"
                                        : difficulty == .medium ? "hare.fill" : "flame.fill",
                                    iconColor: difficulty == .easy ? .mintAccent
                                        : difficulty == .medium ? .mintGold : .red,
                                    title: difficulty.rawValue,
                                    subtitle: "\(difficulty.description)  +\(difficulty.coinReward) coins"
                                ) {
                                    if settings.aiDifficulty == difficulty {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .black))
                                            .foregroundColor(.mintAccent)
                                    }
                                }
                            }.buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(Color.mintBG.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func rowDivider() -> some View {
        Divider().padding(.horizontal, 14)
    }

    private func settingsCard<Content: View>(
        title: String,
        accent: Color,
        footer: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundColor(accent.opacity(0.75))

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            )

            if !footer.isEmpty {
                Text(footer)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.leading, 2)
            }
        }
    }

    @ViewBuilder
    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)
                }
            }

            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

#Preview {
    ContentView()
}
