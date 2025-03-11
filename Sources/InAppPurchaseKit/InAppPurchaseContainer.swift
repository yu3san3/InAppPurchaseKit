import SwiftUI
import StoreKit

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
private struct InAppPurchaseContainerModifier: ViewModifier {
    #if !os(watchOS) || !os(tvOS)
    @Environment(\.requestReview) var requestReview
    #endif

    @ObservedObject private var inAppPurchaseState = InAppPurchaseState.shared

    func body(content: Content) -> some View {
        content
            .environmentObject(inAppPurchaseState)
            .onInAppPurchaseStart { _ in
                inAppPurchaseState.updateIsLoading(true)
            }
            .onInAppPurchaseCompletion { _, result in
                inAppPurchaseState.updateIsLoading(false)

                await processPurchaseResult(result)
            }
    }

    private func processPurchaseResult(
        _ result: Result<Product.PurchaseResult, Error>
    ) async {
        do {
            try await inAppPurchaseState.processPurchaseResult(result)

            #if !os(watchOS) || !os(tvOS)
            requestReview()
            #endif
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension View {
    /// `InAppPurchaseState` を環境オブジェクトとして注入する。
    ///
    /// 以下のOS以前では適用されない。
    /// - iOS 17.0
    /// - macOS 14.0
    /// - tvOS 17.0
    /// - watchOS 10.0
    /// - visionOS 1.0
    public func inAppPurchaseContainer() -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return modifier(InAppPurchaseContainerModifier())
        } else {
            return self
        }
    }
}
