import SwiftUI

struct ContentView: View {
    @StateObject private var game = ReversiGame()

    var body: some View {
        VStack(spacing: 20) {
            Text("Reversi")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Score
            HStack(spacing: 40) {
                ScoreBadge(label: "Black", symbol: "⚫", count: game.blackCount, isActive: game.currentPlayer == .black && !game.gameOver)
                ScoreBadge(label: "White", symbol: "⚪", count: game.whiteCount, isActive: game.currentPlayer == .white && !game.gameOver)
            }

            // Turn indicator or game result
            if game.gameOver {
                if let winner = game.winner {
                    Text("\(winner.symbol) \(winner.name) Wins!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                } else {
                    Text("Draw!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            } else if game.isAIThinking {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("AI is thinking...")
                }
                .font(.title3)
                .foregroundColor(.secondary)
            } else {
                Text("\(game.currentPlayer.symbol) \(game.currentPlayer.name)'s Turn")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Board
            BoardView(game: game)
                .padding(.horizontal, 8)

            // Reset button
            Button(action: {
                withAnimation {
                    game.reset()
                }
            }) {
                Label("New Game", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()

            // Banner Ad
            BannerAdView(adUnitID: AdConstants.bannerAdUnitID)
                .frame(height: 50)
        }
        .padding()
    }
}

struct ScoreBadge: View {
    let label: String
    let symbol: String
    let count: Int
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.title)
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.blue.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    ContentView()
}
