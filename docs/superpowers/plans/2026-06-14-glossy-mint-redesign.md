# Glossy Mint Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply a rich gradient/glossy visual polish across all screens of the Reversi Emoji iOS app, centralized in a new `Theme.swift` design system, with an animated drifting background (Reduce Motion fallback).

**Architecture:** Introduce `Reversi/Theme.swift` as the single source of truth for gradient tokens, reusable view modifiers (`.glossyCard()`, `.glossyButton()`, `.glassChip()`, `.glossyPill()`), and a shared `AnimatedBackground` view. Refactor the three existing screen files to consume them. No layout changes; all changes are presentational. Existing `mint*` colors stay in `ContentView.swift`; only *new* tokens are added in `Theme.swift` to avoid duplicate-symbol churn.

**Tech Stack:** Swift, SwiftUI, Xcode project (`Reversi.xcodeproj`, scheme `Reversi`).

---

## Verification Conventions

This is a visual change with no logic to unit-test. Every task is verified by **(a)** a clean compile and **(b)** visual inspection against the approved mockups in `.superpowers/brainstorm/`.

**Build command** (used as the "test" in every task). `xcode-select` points at Command Line Tools on this machine, so the full Xcode toolchain is selected inline via `DEVELOPER_DIR`:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

Expected on success: `** BUILD SUCCEEDED **`.

**Visual inspection:** Open `Reversi.xcodeproj` in Xcode and run on an iOS Simulator (e.g. iPhone 15), or use SwiftUI previews. Compare against the mockups. The implementer (or reviewer) confirms the screen matches before committing.

---

## File Structure

- **Create:** `Reversi/Theme.swift` — gradient tokens, view modifiers, `AnimatedBackground`. One responsibility: the visual language.
- **Modify:** `Reversi/ContentView.swift` — apply modifiers to `EmojiSelectionView`, `GameView`, `SettingsView`, `ScoreBox`.
- **Modify:** `Reversi/BoardView.swift` — glossy raised board.
- **Modify:** `Reversi/CellView.swift` — beveled cells, glowing valid-move hint, stronger piece shadow.

---

## Task 1: Create Theme tokens & gradients

**Files:**
- Create: `Reversi/Theme.swift`

- [ ] **Step 1: Create `Theme.swift` with color tokens and gradients**

```swift
import SwiftUI

// MARK: - Theme

/// Central source of truth for the glossy mint visual language.
/// Existing `mint*` colors remain defined in ContentView.swift; this enum adds
/// the richer gradient endpoints and named gradients introduced by the redesign.
enum Theme {
    // Richer gradient endpoints
    static let mintRich  = Color(red: 0.24, green: 0.82, blue: 0.48) // #3ED17A
    static let mintDeep  = Color(red: 0.12, green: 0.48, blue: 0.28) // #1F7A48
    static let mintPale  = Color(red: 0.92, green: 1.00, blue: 0.95) // #EAFFF2
    static let boardHigh = Color(red: 0.28, green: 0.77, blue: 0.50) // #48C47F
    static let boardLow  = Color(red: 0.17, green: 0.57, blue: 0.35) // #2B9159

    // MARK: Named gradients
    static let buttonGradient = LinearGradient(
        colors: [mintRich, mintDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardGradient = LinearGradient(
        colors: [.white, mintPale],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cellGradient = LinearGradient(
        colors: [.white, Color(red: 0.91, green: 0.98, blue: 0.93)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cellSelectedGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 1.00, blue: 0.90),
                 Color(red: 0.68, green: 0.94, blue: 0.77)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let boardGradient = LinearGradient(
        colors: [boardHigh, boardLow],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Background gradient stops (consumed by AnimatedBackground)
    static let bgColors: [Color] = [
        Color(red: 0.89, green: 0.98, blue: 0.92),
        Color(red: 0.76, green: 0.94, blue: 0.82),
        Color(red: 0.75, green: 0.92, blue: 0.90),
        Color(red: 0.83, green: 0.95, blue: 0.87)
    ]
}
```

- [ ] **Step 2: Add `Theme.swift` to the Xcode target**

In Xcode, confirm `Theme.swift` is a member of the `Reversi` target (it usually is automatically when created in the group; if added outside Xcode, drag it into the project navigator under the `Reversi` group and check the target membership box). This is required or the build will not see it.

- [ ] **Step 3: Build to verify it compiles**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **` (no visual change yet — this only adds unused tokens, which is fine).

- [ ] **Step 4: Commit**

```bash
git add Reversi/Theme.swift Reversi.xcodeproj
git commit -m "feat: add Theme gradient tokens"
```

---

## Task 2: Add reusable modifiers & AnimatedBackground

**Files:**
- Modify: `Reversi/Theme.swift` (append)

- [ ] **Step 1: Append view modifiers and the animated background to `Theme.swift`**

Add the following to the end of `Reversi/Theme.swift`:

```swift
// MARK: - Glossy Modifiers

/// White→pale-mint gradient surface with soft shadow and a glossy top highlight.
struct GlossyCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
        )
    }
}

/// Glossy gradient button surface with tinted shadow and top highlight.
struct GlossyButton: ViewModifier {
    var cornerRadius: CGFloat = 14
    var gradient: LinearGradient = Theme.buttonGradient
    var shadowColor: Color = Theme.mintDeep
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: shadowColor.opacity(0.40), radius: 8, y: 4)
        )
    }
}

/// Translucent tinted capsule for badges/score boxes.
struct GlassChip: ViewModifier {
    var tint: Color
    func body(content: Content) -> some View {
        content.background(
            Capsule()
                .fill(tint.opacity(0.14))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        .blendMode(.overlay)
                )
        )
    }
}

/// Solid-color capsule with a glossy top highlight (for the turn indicator chip).
struct GlossyPill: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content.background(
            Capsule()
                .fill(color)
                .overlay(
                    Capsule().fill(
                        LinearGradient(colors: [Color.white.opacity(0.35), Color.clear],
                                       startPoint: .top, endPoint: .center)
                    )
                )
                .shadow(color: color.opacity(0.40), radius: 6, y: 3)
        )
    }
}

extension View {
    func glossyCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlossyCard(cornerRadius: cornerRadius))
    }
    func glossyButton(cornerRadius: CGFloat = 14,
                      gradient: LinearGradient = Theme.buttonGradient,
                      shadowColor: Color = Theme.mintDeep) -> some View {
        modifier(GlossyButton(cornerRadius: cornerRadius, gradient: gradient, shadowColor: shadowColor))
    }
    func glassChip(tint: Color) -> some View {
        modifier(GlassChip(tint: tint))
    }
    func glossyPill(color: Color) -> some View {
        modifier(GlossyPill(color: color))
    }
}

// MARK: - Animated Background

/// Slowly drifting mint gradient. Falls back to a static gradient under Reduce Motion.
struct AnimatedBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: Theme.bgColors,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                // Oversize so rotation never exposes empty corners.
                .frame(width: geo.size.width * 1.5, height: geo.size.height * 1.5)
                .rotationEffect(.degrees(animate ? 18 : -18))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Visually verify `AnimatedBackground` in a preview**

Temporarily add this preview to the bottom of `Theme.swift`, run the Xcode canvas preview, and confirm the gradient slowly drifts:

```swift
#Preview { AnimatedBackground() }
```

Confirm: gradient rotates/drifts smoothly over ~12s. Then **remove** the preview (keep the file clean) before committing.

- [ ] **Step 4: Commit**

```bash
git add Reversi/Theme.swift
git commit -m "feat: add glossy modifiers and animated background"
```

---

## Task 3: Apply glossy treatment to the Home screen

**Files:**
- Modify: `Reversi/ContentView.swift` (struct `EmojiSelectionView`, ~lines 80–351)

- [ ] **Step 1: Swap the home background for `AnimatedBackground`**

In `EmojiSelectionView.body`, find the root background (currently the last modifier on the outer `VStack`, around line 260):

```swift
        .background(Color.mintBG.ignoresSafeArea())
```

Replace with:

```swift
        .background(AnimatedBackground())
```

Also update the bottom safe-area inset's background (around line 258) from:

```swift
            .background(Color.mintBG)
```

to a translucent fill so the drifting background shows through the bottom bar:

```swift
            .background(Color.mintBG.opacity(0.85))
```

- [ ] **Step 2: Make the selected-piece card glossy**

Find the selected-piece card background (around lines 169–174):

```swift
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .padding(.horizontal, 20)
```

Replace the `.background(...)` block with the modifier:

```swift
            .padding(14)
            .glossyCard()
            .padding(.horizontal, 20)
```

- [ ] **Step 3: Make the Start Game button glossy**

Find the Start button background in the bottom inset (around lines 244–248):

```swift
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.mintDark)
                            .shadow(color: .mintDark.opacity(0.3), radius: 8, y: 4)
                    )
```

Replace with:

```swift
                    .glossyButton()
```

- [ ] **Step 4: Make stat badges glossy chips**

Find `statBadge` (around lines 342–351). Replace its `.background(...)`:

```swift
        .background(Capsule().fill(color.opacity(0.10)))
```

with:

```swift
        .glassChip(tint: color)
```

- [ ] **Step 5: Make emoji cells use the cell gradient**

In `emojiButton` (around lines 317–322), find the cell fill:

```swift
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected
                                  ? Color.mintAccent.opacity(0.15)
                                  : Color.white.opacity(isLocked ? 0.4 : 0.8))
                    )
```

Replace with gradient fills (keeps the locked dimming via the existing `.opacity(isLocked ? 0.35 : 1.0)` already applied below):

```swift
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Theme.cellSelectedGradient : Theme.cellGradient)
                    )
```

- [ ] **Step 6: Build to verify it compiles**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Visually verify the Home screen**

Run in the Simulator. Confirm: drifting background, glossy selected-piece card, glossy Start button, glass stat badges, gradient emoji cells with a brighter selected state, locked emoji still dimmed with lock badge. Matches the home mockup.

- [ ] **Step 8: Commit**

```bash
git add Reversi/ContentView.swift
git commit -m "feat: apply glossy treatment to home screen"
```

---

## Task 4: Apply glossy treatment to the Game screen

**Files:**
- Modify: `Reversi/ContentView.swift` (struct `GameView` ~lines 356–530, struct `ScoreBox` ~lines 534–553)

- [ ] **Step 1: Swap the game background for `AnimatedBackground`**

In `GameView.body`, find (around line 522):

```swift
        .background(Color.mintBG.ignoresSafeArea())
```

Replace with:

```swift
        .background(AnimatedBackground())
```

And in the bottom banner inset (around line 519), change:

```swift
                    .background(Color.mintBG)
```

to:

```swift
                    .background(Color.mintBG.opacity(0.85))
```

- [ ] **Step 2: Make the turn-indicator chip glossy**

The turn indicator has four states (win, draw, AI thinking, normal turn), each currently using `.background(Capsule().fill(<color>))`. Replace each with `.glossyPill(color:)`.

Win state (around line 410):
```swift
                                .background(Capsule().fill(isPlayer ? Color.mintAccent : Color.red.opacity(0.7)))
```
becomes:
```swift
                                .glossyPill(color: isPlayer ? Color.mintAccent : Color.red.opacity(0.7))
```

Draw state (around line 417):
```swift
                                    .background(Capsule().fill(Color.orange))
```
becomes:
```swift
                                    .glossyPill(color: Color.orange)
```

AI thinking state (around line 429):
```swift
                            .background(Capsule().fill(Color.mintAccent))
```
becomes:
```swift
                            .glossyPill(color: Color.mintAccent)
```

Normal turn state (around line 440):
```swift
                            .background(Capsule().fill(Color.mintAccent))
```
becomes:
```swift
                            .glossyPill(color: Color.mintAccent)
```

- [ ] **Step 3: Make the Resign button glossy**

Find the Resign button background (around lines 480–483):

```swift
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mintDark)
                    )
```

Replace with (darker tone via a custom gradient so Resign stays visually distinct from New Game):

```swift
                    .glossyButton(cornerRadius: 12,
                                  gradient: LinearGradient(colors: [Color.mintDark, Theme.mintDeep],
                                                           startPoint: .top, endPoint: .bottom))
```

- [ ] **Step 4: Make the New Game button glossy**

Find the New Game button background (around lines 504–507):

```swift
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mintAccent)
                        )
```

Replace with:

```swift
                        .glossyButton(cornerRadius: 12)
```

- [ ] **Step 5: Make score boxes glossy**

In `ScoreBox` (around lines 547–551), replace:

```swift
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
        )
```

with:

```swift
        .glossyCard(cornerRadius: 10)
```

- [ ] **Step 6: Build to verify it compiles**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Visually verify the Game screen**

Run in the Simulator, start a game. Confirm: drifting background, glossy turn chip across states (play a move, let AI think, finish a game to see win/draw), glossy score boxes, glossy Resign (darker) and New Game (accent) buttons.

- [ ] **Step 8: Commit**

```bash
git add Reversi/ContentView.swift
git commit -m "feat: apply glossy treatment to game screen"
```

---

## Task 5: Glossy board, beveled cells & glowing hints

**Files:**
- Modify: `Reversi/BoardView.swift`
- Modify: `Reversi/CellView.swift`

- [ ] **Step 1: Make the board raised and glossy**

Replace the entire body of `BoardView` (`Reversi/BoardView.swift`) with:

```swift
import SwiftUI

struct BoardView: View {
    @ObservedObject var game: ReversiGame

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<ReversiGame.boardSize, id: \.self) { row in
                HStack(spacing: 3) {
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
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.boardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: Theme.mintDeep.opacity(0.40), radius: 10, y: 5)
        )
    }
}
```

Note: cell spacing moves from `0` to `3` and the board gets `padding(8)` so the raised green base shows between cells (matching the mockup). The corner-radius clip is replaced by the rounded background.

- [ ] **Step 2: Make cells beveled with the cell gradient**

In `Reversi/CellView.swift`, replace the `Rectangle` background in `CellView.body` (around lines 73–75):

```swift
                Rectangle()
                    .fill(bgColor)
                    .border(Color.green.opacity(0.2), width: 0.5)
```

with a beveled rounded cell:

```swift
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.cellGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                            .blendMode(.overlay)
                    )
```

The now-unused `bgColor` constant (around line 68) can be deleted:

```swift
    private let bgColor = Color(red: 0.75, green: 0.93, blue: 0.80)
```

- [ ] **Step 3: Make the valid-move hint a glowing radial dot**

In `CellView.body`, replace the valid-move circle (around lines 78–87):

```swift
                if isValidMove {
                    Circle()
                        .fill(Color.mintDark.opacity(pulse ? 0.25 : 0.08))
                        .padding(9)
                        .scaleEffect(pulse ? 1.0 : 0.72)
                        .animation(
                            .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                            value: pulse
                        )
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }
```

with a soft glowing radial gradient dot (keeps the same pulse timing/state):

```swift
                if isValidMove {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.mintDeep.opacity(0.55), Theme.boardLow.opacity(0.0)],
                                center: .center, startRadius: 0, endRadius: 14
                            )
                        )
                        .padding(7)
                        .scaleEffect(pulse ? 1.0 : 0.7)
                        .opacity(pulse ? 0.9 : 0.45)
                        .animation(
                            .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                            value: pulse
                        )
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }
```

- [ ] **Step 4: Strengthen the piece drop shadow**

In `AnimalPieceView.body` (around line 22), change the piece shadow from:

```swift
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
```

to:

```swift
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
```

- [ ] **Step 5: Build to verify it compiles**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Visually verify the board**

Run in the Simulator and start a game. Confirm: raised glossy green board with gaps showing the base between cells, beveled cells, glowing pulsing valid-move dots, pieces with a stronger shadow, and the flip animation still works when capturing pieces.

- [ ] **Step 7: Commit**

```bash
git add Reversi/BoardView.swift Reversi/CellView.swift
git commit -m "feat: glossy board, beveled cells and glowing move hints"
```

---

## Task 6: Apply glossy treatment to Settings

**Files:**
- Modify: `Reversi/ContentView.swift` (struct `SettingsView` ~lines 557–747)

- [ ] **Step 1: Add the animated background behind the settings sheet**

In `SettingsView.body`, find the `ScrollView`'s background (around line 675):

```swift
            .background(Color.mintBG.ignoresSafeArea())
```

Replace with:

```swift
            .background(AnimatedBackground())
```

- [ ] **Step 2: Make setting cards glossy**

In `settingsCard` (around lines 700–704), replace the card surface:

```swift
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            )
```

with:

```swift
            .glossyCard()
```

- [ ] **Step 3: Build to verify it compiles**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Visually verify Settings**

Run, open Settings (gear icon). Confirm: drifting background behind the sheet, glossy Collection / Ads / Sound / AI Difficulty cards. Toggle sound and change difficulty to confirm controls still work.

- [ ] **Step 5: Commit**

```bash
git add Reversi/ContentView.swift
git commit -m "feat: apply glossy treatment to settings"
```

---

## Task 7: Reduce Motion & regression pass

**Files:** none (verification only)

- [ ] **Step 1: Verify Reduce Motion fallback**

In the Simulator: Settings app → Accessibility → Motion → enable **Reduce Motion**. Relaunch the Reversi app. Confirm the background renders as a **static** gradient (no drifting) on home, game, and settings. Disable Reduce Motion and confirm the drift returns.

- [ ] **Step 2: Functional regression check**

With the app running, confirm no behavioral regressions:
- Select an emoji (locked + unlocked), unlock with a coin, start a game.
- Place pieces, confirm flips and live score update.
- Let the AI take a turn.
- Resign, then start a New Game.
- Open Settings: toggle sound, switch AI difficulty, view collection stats.

All behave exactly as before the redesign.

- [ ] **Step 3: Final clean build**

Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Reversi.xcodeproj -scheme Reversi \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **` with no new warnings from the redesign code.

- [ ] **Step 4: No code changes to commit**

This task is verification only. If any issue was found and fixed, commit it with a descriptive message; otherwise nothing to commit.

---

## Self-Review Notes

- **Spec coverage:** Theme tokens & gradients (Task 1) ✓; modifiers + AnimatedBackground with Reduce Motion (Task 2, verified Task 7) ✓; home (Task 3) ✓; game (Task 4) ✓; board/cells/hints/pieces (Task 5) ✓; settings (Task 6) ✓; build + visual + regression verification (every task + Task 7) ✓.
- **Token consistency:** Tokens referenced in Tasks 3–6 (`Theme.cellGradient`, `Theme.cellSelectedGradient`, `Theme.boardGradient`, `Theme.boardLow`, `Theme.mintDeep`) and modifiers (`glossyCard`, `glossyButton`, `glassChip`, `glossyPill`, `AnimatedBackground`) are all defined in Tasks 1–2 with matching names/signatures.
- **Deviation from spec:** Existing `mint*` colors are left in `ContentView.swift` rather than moved to `Theme.swift`, to avoid duplicate-symbol risk during the refactor. The spec explicitly allowed "move to (or re-export from)"; leaving them in place satisfies it with lower risk.
