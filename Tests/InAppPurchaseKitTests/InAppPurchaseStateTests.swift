import Testing
@testable import InAppPurchaseKit

private struct DummyError: Error {}

@MainActor
struct InAppPurchaseStateTests {
    // MARK: - Phase

    @Test("hasInitialized は ready と updating の場合のみ true を返す")
    func hasInitialized() {
        #expect(InAppPurchaseState.Phase.idle.hasInitialized == false)
        #expect(InAppPurchaseState.Phase.initializing.hasInitialized == false)
        #expect(InAppPurchaseState.Phase.ready.hasInitialized == true)
        #expect(InAppPurchaseState.Phase.updating.hasInitialized == true)
        #expect(InAppPurchaseState.Phase.failed(DummyError()).hasInitialized == false)
    }

    @Test("isLoading は initializing と updating の場合のみ true を返す")
    func isLoading() {
        #expect(InAppPurchaseState.Phase.idle.isLoading == false)
        #expect(InAppPurchaseState.Phase.initializing.isLoading == true)
        #expect(InAppPurchaseState.Phase.ready.isLoading == false)
        #expect(InAppPurchaseState.Phase.updating.isLoading == true)
        #expect(InAppPurchaseState.Phase.failed(DummyError()).isLoading == false)
    }

    // MARK: - isPurchased

    @Test("購入データ未取得の場合、isPurchased が nil を返す")
    func isPurchasedBeforeSync() {
        let state = InAppPurchaseState.preview(phase: .idle)
        #expect(state.isPurchased(id: "com.example.pro") == nil)
    }

    @Test("failed の場合、isPurchased が nil を返す")
    func isPurchasedWhenFailed() {
        let state = InAppPurchaseState.preview(phase: .failed(DummyError()))
        #expect(state.isPurchased(id: "com.example.pro") == nil)
    }

    @Test("購入していないプロダクトの場合、isPurchased が false を返す")
    func isPurchasedNotPurchased() {
        let state = InAppPurchaseState.preview(purchased: ["com.example.pro"])
        #expect(state.isPurchased(id: "com.example.other") == false)
    }

    @Test("購入済みプロダクトの場合、isPurchased が true を返す")
    func isPurchasedTrue() {
        let state = InAppPurchaseState.preview(purchased: ["com.example.pro"])
        #expect(state.isPurchased(id: "com.example.pro") == true)
    }

    // MARK: - product(for:)

    @Test("プロダクトが未取得の場合、product(for:) が nil を返す")
    func productForIdWhenEmpty() {
        let state = InAppPurchaseState.preview()
        #expect(state.product(for: "com.example.pro") == nil)
    }
}
