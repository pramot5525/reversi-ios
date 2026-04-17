import GoogleMobileAds
import UIKit

@MainActor
class RewardedAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = RewardedAdManager()

    #if DEBUG
    static let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let adUnitID = "ca-app-pub-3591885168954129/REPLACE_WITH_REAL_REWARDED_ID"
    #endif

    @Published var isAdReady = false
    @Published var isLoading = false

    private var rewardedAd: RewardedAd?
    private var rewardEarned = false
    private var dismissContinuation: CheckedContinuation<Bool, Never>?

    override private init() {
        super.init()
        Task { await loadAd() }
    }

    // MARK: - Load Ad

    func loadAd() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let ad = try await RewardedAd.load(
                with: Self.adUnitID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            isAdReady = true
        } catch {
            #if DEBUG
            print("Failed to load rewarded ad: \(error)")
            #endif
            isAdReady = false
        }
        isLoading = false
    }

    // MARK: - Show Ad

    /// Shows the rewarded ad. Returns true if the user earned the reward.
    func showAd() async -> Bool {
        guard let ad = rewardedAd else { return false }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.keyWindow?.rootViewController else {
            return false
        }

        // Find the top-most presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        rewardEarned = false

        return await withCheckedContinuation { continuation in
            dismissContinuation = continuation
            ad.present(from: topVC) { [weak self] in
                self?.rewardEarned = true
            }
        }
    }

    // MARK: - FullScreenContentDelegate

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            let earned = rewardEarned

            // Clean up
            rewardedAd = nil
            isAdReady = false

            // Resume continuation with reward result
            dismissContinuation?.resume(returning: earned)
            dismissContinuation = nil

            // Preload next ad
            await loadAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        #if DEBUG
        print("Rewarded ad failed to present: \(error)")
        #endif
        Task { @MainActor in
            rewardedAd = nil
            isAdReady = false

            dismissContinuation?.resume(returning: false)
            dismissContinuation = nil

            await loadAd()
        }
    }
}
