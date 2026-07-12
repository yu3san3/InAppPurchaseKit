/// アプリ内購入のエラー
public enum InAppPurchaseError: Error, Sendable {
    case unverified
    case unknown
    case storeKitError(any Error & Sendable)
}
