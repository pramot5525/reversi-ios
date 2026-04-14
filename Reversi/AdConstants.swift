import Foundation

enum AdConstants {
    // TODO: Switch to production ID before release
    // Production: "ca-app-pub-3591885168954129/1949435781"
    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Google test banner
    #else
    static let bannerAdUnitID = "ca-app-pub-3591885168954129/1949435781"
    #endif
}
