/// 購入の結果。エラーでない購入結果を表す。
public enum PurchaseOutcome: Sendable {
    /// 購入が完了した
    case purchased
    /// ユーザが購入をキャンセルした
    case cancelled
    /// 購入が保留中 (Ask to Buy など)
    case pending
}
