import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .easy: return "Random moves"
        case .medium: return "Greedy strategy"
        case .hard: return "Thinks ahead"
        }
    }

    var coinReward: Int {
        switch self {
        case .easy: return 2
        case .medium: return 3
        case .hard: return 5
        }
    }
}

class GameSettings: ObservableObject {
    static let shared = GameSettings()
    
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    
    @Published var aiDifficulty: AIDifficulty {
        didSet { UserDefaults.standard.set(aiDifficulty.rawValue, forKey: "aiDifficulty") }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }

    private init() {
        let savedSound = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool
        self.soundEnabled = savedSound ?? true

        let savedDifficulty = UserDefaults.standard.string(forKey: "aiDifficulty") ?? "Medium"
        self.aiDifficulty = AIDifficulty(rawValue: savedDifficulty) ?? .medium

        let savedAppearance = UserDefaults.standard.string(forKey: "appearanceMode") ?? "System"
        self.appearanceMode = AppearanceMode(rawValue: savedAppearance) ?? .system
    }
}
