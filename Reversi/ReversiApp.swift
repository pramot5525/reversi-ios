import SwiftUI
import GoogleMobileAds

@main
struct ReversiApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
        GameCenterManager.shared.authenticate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
