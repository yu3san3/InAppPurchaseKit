import StoreKit

@MainActor
@Observable
public final class InAppPurchaseState {
    public enum Phase: Sendable, Equatable {
        public static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                (.initializing, .initializing),
                (.ready, .ready),
                (.updating, .updating),
                (.failed, .failed): true
            default: false
            }
        }

        /// 初期状態。購入データ未取得
        case idle
        /// 購入データの初回取得中。データはまだ利用できない
        case initializing
        /// 購入データ取得済み
        case ready
        /// 購入データ取得済みの状態で再同期・購入・復元中
        case updating
        /// プロダクト情報の取得に失敗した
        case failed(any Error & Sendable)

        /// 購入データの初回取得が完了しているかどうか
        public var hasInitialized: Bool {
            switch self {
            case .ready, .updating: true
            case .idle, .initializing, .failed: false
            }
        }

        /// 同期・購入・復元などの処理中かどうか
        public var isLoading: Bool {
            switch self {
            case .initializing, .updating: true
            case .idle, .ready, .failed: false
            }
        }
    }

    public private(set) var phase = Phase.idle
    public private(set) var products = [Product]()
    public private(set) var purchasedProductIDs = Set<String>()

    private let productIDs: [String]

    public init(productIDs: [String]) {
        self.productIDs = productIDs
    }

    /// Preview やテスト用のインスタンスを生成する。
    ///
    /// - Parameters:
    ///   - phase: 初期フェーズ (デフォルト: `.ready`)
    ///   - purchased: 購入済みとみなすプロダクト ID
    public static func preview(
        phase: Phase = .ready,
        purchased: Set<String> = []
    ) -> InAppPurchaseState {
        let state = InAppPurchaseState(productIDs: [])
        state.setPhase(phase)
        state.setPurchasedProductIDs(purchased)
        return state
    }

    /// 購入データ未取得の場合は `nil` を返す。
    public func isPurchased(id: String) -> Bool? {
        guard phase.hasInitialized else { return nil }

        return purchasedProductIDs.contains(id)
    }

    /// `products` から指定した ID のプロダクトを返す。
    public func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    /// アプリ外での購入 (オファーコード、Ask to Buy の承認、他デバイスでの購入) を検知し、購入状態を自動更新する。
    ///
    /// `inAppPurchaseContainer` を使わない場合は、ルートビューの `.task` などから呼び出すこと。
    /// この関数は Task がキャンセルされるまで実行を続ける。
    public func observeTransactionUpdates() async {
        for await verificationResult in Transaction.updates {
            guard let transaction = try? verificationResult.payloadValue else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    /// プロダクト情報と購入状態を最新に同期する。
    public func sync() async {
        phase = phase == .idle ? .initializing : .updating

        async let products = fetchProducts()
        async let purchased = refreshEntitlements()

        do {
            try await products
            await purchased
            phase = .ready
        } catch {
            phase = .failed(error)
        }
    }

    /// 指定したプロダクトを購入する。
    ///
    /// - Parameters:
    ///   - product: `products` から取得したプロダクト
    ///   - options: 購入オプション (例: `.quantity(3)`)
    /// - Returns: 購入の結果。キャンセルや保留はエラーではなく戻り値で表現される。
    @available(visionOS, unavailable)
    public func purchase(
        _ product: Product,
        options: Set<Product.PurchaseOption> = []
    ) async throws -> PurchaseOutcome {
        phase = .updating
        defer { phase = .ready }

        let purchaseResult = try await product.purchase(options: options)
        return try await handlePurchaseResult(purchaseResult)
    }

    /// 購入情報を復元する。
    ///
    /// 「購入を復元」ボタンが押されたときに呼ぶ。
    ///
    /// - Throws: 復元に失敗した場合
    public func restorePurchases() async throws {
        phase = .updating
        defer { phase = .ready }

        try await AppStore.sync()
        await refreshEntitlements()
    }

    func setPhase(_ phase: Phase) {
        self.phase = phase
    }

    /// 購入結果を処理する。成功時は購入状態を更新し、失敗時はエラーをスローする。
    func handlePurchaseCompletion(_ result: Result<Product.PurchaseResult, Error>) async throws -> PurchaseOutcome {
        switch result {
        case let .success(purchaseResult):
            return try await handlePurchaseResult(purchaseResult)

        case let .failure(error):
            throw error
        }
    }

    private func setPurchasedProductIDs(_ ids: Set<String>) {
        purchasedProductIDs = ids
    }

    private func fetchProducts() async throws {
        guard !productIDs.isEmpty else { return }

        products = try await Product.products(for: productIDs)
    }

    private func handlePurchaseResult(_ purchaseResult: Product.PurchaseResult) async throws -> PurchaseOutcome {
        switch purchaseResult {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await refreshEntitlements()
            return .purchased

        case .success(.unverified):
            throw InAppPurchaseError.unverified

        case .pending:
            return .pending

        case .userCancelled:
            return .cancelled

        @unknown default:
            throw InAppPurchaseError.unknown

        }
    }

    private func refreshEntitlements() async {
        var result = Set<String>()
        for await verificationResult in Transaction.currentEntitlements {
            guard let transaction = try? verificationResult.payloadValue else { continue }
            result.insert(transaction.productID)
        }
        purchasedProductIDs = result
    }
}
