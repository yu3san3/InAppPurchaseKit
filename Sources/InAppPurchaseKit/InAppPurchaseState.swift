import SwiftUI
import StoreKit

public class InAppPurchaseState: ObservableObject {
    public static let shared = InAppPurchaseState()

    /// 課金情報を同期中かどうかを示すフラグ
    @Published public var isLoading = false
    /// 購入済みのプロダクト ID を保持するセット
    @Published private var purchasedProducts: Set<String>?

    /// 課金状態の取得が完了したかを示すプロパティ
    public var initialized: Bool {
        purchasedProducts != nil
    }

    /// クラスの初期化時に購入情報を同期
    private init() {
        Task { await syncPurchases() }
    }

    /// 指定されたプロダクトが購入済みかどうかを判定する。
    ///
    /// - Parameter id: チェックするプロダクトの ID
    /// - Returns: 購入済みの場合は `true`、未購入の場合は `false`
    public func isPurchased(id: String) -> Bool {
        purchasedProducts?.contains(id) == true
    }

    /// 購入情報を同期し、購入済みのプロダクト ID を更新する。
    @MainActor
    public func syncPurchases() async {
        updateIsLoading(true)

        purchasedProducts = await fetchPurchasedProducts()

        updateIsLoading(false)
    }

    /// 購入の結果を処理
    ///
    /// - 購入に成功した場合は、トランザクションを完了したのちに購入情報を同期する。
    /// - 失敗またはキャンセルされた場合にはエラーを投げる。
    ///
    /// - Parameter result: `Product.PurchaseResult` の `Result` 型。
    public func handlePurchaseResult(
        _ result: Result<Product.PurchaseResult, Error>
    ) async throws {
        switch result {
        case let .success(purchaseResult):
            try await handlePurchaseResultSuccess(purchaseResult)

        case let .failure(error):
            throw error
        }
    }

    /// 購入情報を復元する。
    ///
    /// 「購入を復元」ボタンが押されたときに呼ぶ。
    ///
    /// - Throws: `AppStore.sync()` の実行時にエラーが発生した場合
    public func restorePurchase() async throws {
        defer {
            Task { @MainActor in updateIsLoading(false) }
        }

        await updateIsLoading(true)

        try await AppStore.sync()
        await syncPurchases()
    }

    /// ローディング状態を更新する。
    ///
    /// - Parameter isLoading: 課金情報の同期中かどうか
    @MainActor
    public func updateIsLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    /// 現在の購入済みプロダクトを取得する。
    ///
    /// - Returns: 購入済みのプロダクト ID のセット
    private func fetchPurchasedProducts() async -> Set<String> {
        var result = Set<String>()

        for await verificationResult in Transaction.currentEntitlements {
            guard case let .verified(signedType) = verificationResult else { continue }

            result.insert(signedType.productID)
        }

        return result
    }

    /// 購入の結果を処理
    ///
    /// - 購入に成功した場合は、トランザクションを完了したのちに購入情報を同期する。
    /// - 失敗またはキャンセルされた場合にはエラーを投げる。
    ///
    /// - Parameter result: `Product.PurchaseResult` 型。
    private func handlePurchaseResultSuccess(
        _ purchaseResult: Product.PurchaseResult
    ) async throws {
        guard case let .success(.verified(transaction)) = purchaseResult else {
            throw NSError(
                domain: "InAppPurchaseError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "購入に失敗したか、キャンセルされました。"]
            )
        }

        // これをしないと消耗型の商品を複数回購入できない。
        await transaction.finish()

        await syncPurchases()
    }
}
