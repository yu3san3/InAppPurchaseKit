import SwiftUI
import StoreKit

private struct StoreKitViewPurchaseModifier: ViewModifier {
    let onStart: (@Sendable (Product) -> Void)?
    let onCompletion: (@Sendable (Product, PurchaseOutcome) -> Void)?
    let onFailure: (@Sendable (InAppPurchaseError) -> Void)?

    @Environment(InAppPurchaseState.self) private var state

    func body(content: Content) -> some View {
        content
            .onInAppPurchaseStart { product in
                state.setPhase(.updating)
                onStart?(product)
            }
            .onInAppPurchaseCompletion { product, result in
                defer { state.setPhase(.ready) }

                do {
                    let outcome = try await state.handlePurchaseCompletion(result)
                    onCompletion?(product, outcome)
                } catch let error as InAppPurchaseError {
                    onFailure?(error)
                } catch {
                    onFailure?(.storeKitError(error))
                }
            }
    }
}

extension View {
    /// StoreKit ビュー (ProductView / StoreView / SubscriptionStoreView) の購入イベントを処理する。
    ///
    /// 購入中のローディング状態管理と、購入完了後の状態更新を自動的に行う。
    /// StoreKit ビュー以外のビューに付与しても購入イベントは発火しない。
    /// `inAppPurchaseContainer` 配下でのみ使用可能。
    ///
    /// - Parameters:
    ///   - onStart: 購入開始時に呼ばれるコールバック。購入対象の `Product` を受け取る。
    ///   - onCompletion: 購入処理がエラーなく完了したときに呼ばれるコールバック。`PurchaseOutcome` で購入完了・キャンセル・保留を区別できる。
    ///   - onFailure: 購入失敗時に呼ばれるコールバック。`InAppPurchaseError` を受け取る。
    public func onStoreKitViewPurchase(
        onStart: (@Sendable (Product) -> Void)? = nil,
        onCompletion: (@Sendable (Product, PurchaseOutcome) -> Void)? = nil,
        onFailure: (@Sendable (InAppPurchaseError) -> Void)? = nil
    ) -> some View {
        modifier(
            StoreKitViewPurchaseModifier(
                onStart: onStart,
                onCompletion: onCompletion,
                onFailure: onFailure
            )
        )
    }
}
