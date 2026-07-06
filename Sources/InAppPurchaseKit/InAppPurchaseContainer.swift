import SwiftUI

private struct InAppPurchaseContainerModifier: ViewModifier {
    @State private var state: InAppPurchaseState

    init(productIDs: [String]) {
        _state = State(initialValue: InAppPurchaseState(productIDs: productIDs))
    }

    func body(content: Content) -> some View {
        content
            .environment(state)
            .task {
                await state.sync()
                await state.observeTransactionUpdates()
            }
    }
}

extension View {
    /// `InAppPurchaseState` を環境値として注入し、購入状態の同期とアプリ外購入の監視を開始する。
    ///
    /// アプリのルートビューに付与すること。
    ///
    /// - Parameter productIDs: App Store Connect で登録したプロダクトの ID
    public func inAppPurchaseContainer(productIDs: [String]) -> some View {
        modifier(InAppPurchaseContainerModifier(productIDs: productIDs))
    }
}
