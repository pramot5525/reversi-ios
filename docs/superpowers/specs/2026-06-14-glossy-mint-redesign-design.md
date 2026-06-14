# Rich Glossy Mint Redesign — Design Spec

**Date:** 2026-06-14
**Status:** Approved (design), pending spec review
**Scope:** UI/UX polish across all screens of Reversi Emoji (iOS, SwiftUI)

## Goal

The app's current mint pastel theme reads as too plain and flat. Elevate it to feel
premium, polished, and vibrant — without changing the mint aesthetic direction or
moving any layouts around. The chosen visual direction is **"Rich Gradient / Glossy"**:
subtle gradients, glossy highlights on buttons/cells, richer greens, glowing accents,
and a slowly drifting animated background — a playful, "candy game" energy.

This is a pure visual-polish pass. Game logic, ads, StoreKit, Game Center, sound, and
haptics are out of scope and must remain functionally untouched.

## Non-Goals

- No layout/structure changes — components are restyled in place.
- No new gameplay, monetization, or settings features.
- No dark mode.
- No changes to game logic, AI, persistence, ads, or in-app purchase flows.
- No micro-interaction overhaul (button-press feedback, screen transitions) — may be a
  future pass; not included here.

## Architecture

Introduce one new file as the single source of truth for the visual language:

**`Reversi/Theme.swift`** — holds the gradient palette, named gradients, reusable view
modifiers, and the shared animated background view.

The existing screens consume `Theme`:

- `Reversi/ContentView.swift` — home (`EmojiSelectionView`), game (`GameView`),
  settings (`SettingsView`), plus shared `ScoreBox`.
- `Reversi/BoardView.swift` — the board container.
- `Reversi/CellView.swift` — individual cells, valid-move hints, pieces.

The legacy `Color` aliases currently defined in `ContentView.swift` (`mintBG`,
`mintAccent`, `arcadeGreen`, etc.) remain available so the refactor can proceed
incrementally without breaking references. Color definitions move to (or are
re-exported from) `Theme.swift` so theme tokens live in one place.

### Why a centralized design system

The glossy treatment repeats across all three screens (cards, buttons, chips, cells).
Centralizing it in reusable modifiers guarantees consistency by construction, lets a
single gradient definition update everywhere, and keeps the already-large
`ContentView.swift` from growing. This was chosen over inline per-screen restyling
specifically to avoid visual drift between screens.

## Design Tokens (`Theme.swift`)

### Palette

- Keep existing hues: `mintBG`, `mintBoard`, `mintCard`, `mintAccent`, `mintDark`,
  `mintPurple`, `mintGold`.
- Add richer gradient endpoints:
  - `mintRich` ≈ `#3ED17A` (bright glossy green)
  - `mintDeep` ≈ `#1F7A48` (deep green)
  - `mintPale` ≈ `#EAFFF2` (near-white mint for card highlights)

### Named gradients

- `Theme.buttonGradient` — `mintRich → mintDeep`, diagonal (135°). Glossy green for
  primary buttons.
- `Theme.cardGradient` — `white → mintPale`, ~145°. For cards/surfaces.
- `Theme.cellGradient` — `white → pale mint`, ~145°. For board cells (empty/default).
- `Theme.cellSelectedGradient` — brighter mint for selected/active cells.
- `Theme.boardGradient` — `#48C47F → #2B9159`, ~145°. The raised board base.
- `Theme.bgGradient(phase:)` — the multi-stop mint background used by the animated
  background view.

## Reusable Modifiers & Components (`Theme.swift`)

- **`.glossyCard()`** — fills with `cardGradient`, 16pt corner radius, soft drop shadow
  (`black 6%, radius 8, y 2`) plus an inset top highlight (`white` inner top edge) to
  read as glossy/raised.
- **`.glossyButton()`** — fills with `buttonGradient`, drop shadow tinted green
  (`mintDeep ~40%`), plus inset top highlight. Used by Start Game, Resign, New Game,
  and the Remove Ads / purchase buttons where appropriate.
- **`.glassChip(tint:)`** — pill/capsule with a tinted translucent gradient fill and
  subtle highlight. Used by the turn indicator chip, home stat badges, and score boxes.
- **`AnimatedBackground`** — a `View` rendering `bgGradient` with a slowly drifting
  animation (animate the gradient's start/end `UnitPoint` on a long, autoreversing
  loop, ~12s, `easeInOut`). Replaces the flat `Color.mintBG.ignoresSafeArea()` at each
  screen root.
  - **Accessibility:** when `accessibilityReduceMotion` is enabled, render a static
    gradient (no animation) for accessibility and battery.

## Per-Screen Application

### Home (`EmojiSelectionView`)

- Root background → `AnimatedBackground`.
- Selected-piece card → `.glossyCard()`.
- Stat badges (coins, unlocked count) → `.glassChip(tint:)`.
- Emoji grid cells → `cellGradient` fill; selected state uses a glossier highlight
  (brighter gradient + accent ring + stronger shadow). Locked state keeps its dimmed
  look and lock badge.
- Search bar → light glossy surface consistent with cards.
- Start Game button → `.glossyButton()`.

### Game (`GameView`)

- Root background → `AnimatedBackground`.
- Turn indicator chip (current turn / AI thinking / win / draw states) → `.glassChip`
  with the existing state colors (accent / red / orange) as the tint.
- `LIVE SCORE` boxes (`ScoreBox`) → glossy gradient surface.
- Resign button and New Game button → `.glossyButton()` (New Game keeps its accent
  tone; Resign keeps its darker tone).

### Board (`BoardView` / `CellView`)

- `BoardView`: board base uses `boardGradient` with a raised shadow
  (`#1F7A48 ~40%, radius 10, y bigger`) and an inset top highlight; keep rounded
  corners and border.
- `CellView`: empty cells use `cellGradient` with an inset bevel (inner top white
  highlight, inner bottom subtle shadow) for a tactile glossy look.
- Valid-move hint: replace the flat pulsing circle with a soft **glowing radial dot**
  (radial gradient, gentle opacity/scale pulse), keeping the existing pulse timing.
- Pieces (`AnimalPieceView`): keep the flip/scale animation; increase the drop shadow
  slightly for depth on the glossy board.

### Settings (`SettingsView`)

- Background behind the sheet → `AnimatedBackground`.
- Setting cards (`settingsCard`) → `.glossyCard()`.
- Rows, toggles, and icons keep their structure; icon chips may pick up a subtle
  gradient to match.

## Error Handling & Performance

- The animated background is a single looping SwiftUI animation driving one gradient —
  inexpensive on the GPU. It is fully disabled under Reduce Motion.
- No new state, persistence, or network paths are introduced.
- All changes are presentational; game logic, ads, StoreKit, and Game Center are
  untouched, so there is no behavioral or data-integrity risk.

## Testing / Verification

This is a visual change, so verification is primarily by inspection:

1. Build with `xcodebuild` (or Xcode) and confirm it compiles cleanly with no warnings
   introduced by the new code.
2. Run in the iOS Simulator and visually confirm each screen (home, game with board,
   settings) matches the approved mockups in `.superpowers/brainstorm/`.
3. Verify the drifting background animates and that enabling **Reduce Motion** swaps it
   for a static gradient.
4. Confirm no functional regressions: piece placement, flips, scoring, AI turn,
   resign/new game, emoji unlock flow, settings toggles all behave as before.

No unit tests are added — there is no logic to assert on for a pure styling change.

## Affected Files

- **New:** `Reversi/Theme.swift`
- **Modified:** `Reversi/ContentView.swift`, `Reversi/BoardView.swift`,
  `Reversi/CellView.swift`
