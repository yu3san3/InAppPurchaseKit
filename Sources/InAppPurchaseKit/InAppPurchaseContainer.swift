import SwiftUI
import StoreKit

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private struct InAppPurchaseContainerModifier: ViewModifier {
#if !os(watchOS) || !os(tvOS)
    @Environment(\.requestReview) var requestReview
#endif

    @StateObject private var inAppPurchaseState = InAppPurchaseState.shared

    func body(content: Content) -> some View {
        content
            .environmentObject(inAppPurchaseState)
            .onInAppPurchaseStart { _ in
                inAppPurchaseState.updateIsLoading(true)
            }
            .onInAppPurchaseCompletion { _, result in
                inAppPurchaseState.updateIsLoading(false)

                await processPurchaseResultWithRequestingReview(result)
            }
    }

    private func processPurchaseResultWithRequestingReview(
        _ result: Result<Product.PurchaseResult, Error>
    ) async {
        do {
            try await inAppPurchaseState.handlePurchaseResult(result)

            #if !os(watchOS) || !os(tvOS)
            requestReview()
            #endif
        } catch {
            print(error.localizedDescription)
        }
    }
}

@available(iOS, deprecated: 17.0, message: "Use InAppPurchaseContainerModifier instead.")
@available(macOS, deprecated: 14.0, message: "Use InAppPurchaseContainerModifier instead.")
@available(tvOS, deprecated: 17.0, message: "Use InAppPurchaseContainerModifier instead.")
@available(watchOS, deprecated: 10.0, message: "Use InAppPurchaseContainerModifier instead.")
private struct InAppPurchaseContainerLegacyModifier: ViewModifier {
    @StateObject private var inAppPurchaseState = InAppPurchaseState.shared

    func body(content: Content) -> some View {
        content
            .environmentObject(inAppPurchaseState)
    }
}

extension View {
    /// `InAppPurchaseState` を環境オブジェクトとして注入する。
    ///
    /// iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0 以降では、アプリ内購入の開始および完了時の処理を自動で行う。
    /// それ以前のOSでは、`InAppPurchaseState` を環境オブジェクトとして設定するのみを行うため、
    /// アプリ内購入の開始および完了時の処理は手動で定義する必要がある。
    public func inAppPurchaseContainer() -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            return modifier(InAppPurchaseContainerModifier())
        } else {
            return modifier(InAppPurchaseContainerLegacyModifier())
        }
    }
}
