import SwiftUI

struct DiscView: View {
    let state: CellState

    @State private var displayedState: CellState
    @State private var flipAngle: Double = 0

    init(state: CellState) {
        self.state = state
        self._displayedState = State(initialValue: state)
    }

    var body: some View {
        ZStack {
            if displayedState == .black {
                Circle()
                    .fill(Color.black)
                    .padding(4)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 1)
            } else if displayedState == .white {
                Circle()
                    .fill(Color.white)
                    .padding(4)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 1)
            }
        }
        .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0))
        .onChange(of: state) { _, newState in
            guard newState != displayedState else { return }
            withAnimation(.easeIn(duration: 0.15)) {
                flipAngle = 90
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                displayedState = newState
                withAnimation(.easeOut(duration: 0.15)) {
                    flipAngle = 0
                }
            }
        }
    }
}
