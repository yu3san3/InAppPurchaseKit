import SwiftUI

private struct PurchaseVisibilityModifier: ViewModifier {
    let productID: String
    let showsWhenPurchased: Bool

    @Environment(InAppPurchaseState.self) private var state

    func body(content: Content) -> some View {
        if state.isPurchased(id: productID) == showsWhenPurchased {
            content
        }
    }
}

extension View {
    /// 指定したプロダクトが購入済みの間、ビューを非表示にする。
    ///
    /// 課金状態の初回取得が完了するまでは非表示になる。
    ///
    /// - Note: `inAppPurchaseContainer` 配下でのみ使用可能
    public func hiddenIfPurchased(id: String) -> some View {
        modifier(
            PurchaseVisibilityModifier(
                productID: id,
                showsWhenPurchased: false
            )
        )
    }

    /// 指定したプロダクトが購入済みの間だけビューを表示する。
    ///
    /// 課金状態の初回取得が完了するまでは非表示になる。
    ///
    /// - Note: `inAppPurchaseContainer` 配下でのみ使用可能
    public func visibleIfPurchased(id: String) -> some View {
        modifier(
            PurchaseVisibilityModifier(
                productID: id,
                showsWhenPurchased: true
            )
        )
    }
}
