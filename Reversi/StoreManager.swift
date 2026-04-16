import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Product ID — must match App Store Connect / StoreKit config
    static let removeAdsID = "com.reversi.app.removeads"
    
    @Published var removeAdsProduct: Product?
    @Published var isAdsRemoved: Bool = false
    @Published var isPurchasing: Bool = false
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        // Check saved state first (fast)
        isAdsRemoved = UserDefaults.standard.bool(forKey: "adsRemoved")
        
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Load products & verify entitlements
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.removeAdsID])
            removeAdsProduct = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                setAdsRemoved(true)
                
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }
    
    // MARK: - Check Entitlements
    
    private func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.removeAdsID,
               transaction.revocationDate == nil {
                setAdsRemoved(true)
                return
            }
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == Self.removeAdsID {
                        if transaction.revocationDate == nil {
                            await self.setAdsRemoved(true)
                        } else {
                            await self.setAdsRemoved(false)
                        }
                    }
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func setAdsRemoved(_ value: Bool) {
        isAdsRemoved = value
        UserDefaults.standard.set(value, forKey: "adsRemoved")

        // Award 100 bonus coins on first purchase
        if value && !UserDefaults.standard.bool(forKey: "removeAdsCoinAwarded") {
            UserDefaults.standard.set(true, forKey: "removeAdsCoinAwarded")
            EmojiUnlockManager.shared.addCoins(100)
        }
    }
    
    enum StoreError: Error {
        case verificationFailed
    }
}
