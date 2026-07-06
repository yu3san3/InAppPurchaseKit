# InAppPurchaseKit

StoreKit 2 のアプリ内購入を SwiftUI で扱うユーティリティ。

## 動作要件

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Swift 6.3

## 特徴

- `@Observable` な購入状態を Environment 経由で共有 (シングルトン不使用)
- StoreKit ビュー (ProductView / StoreView / SubscriptionStoreView) の購入イベント処理 (`onStoreKitViewPurchase` modifier)
- `Transaction.updates` 常時監視によるアプリ外購入対応 (オファーコード、Ask to Buy の承認、他デバイスでの購入)
- プロダクト情報の取得と `import StoreKit` 不要のカスタム UI 構築

## 使い方

### 1. ルートビューに `inAppPurchaseContainer` を付与する

`productIDs` を渡すと、プロダクト情報が `InAppPurchaseState.products` にロードされる:

```swift
import InAppPurchaseKit

struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .inAppPurchaseContainer(productIDs: [
                    "com.example.app.pro",
                    "com.example.app.premium",
                ])
        }
    }
}
```

### 2. 購入状態を読む

`isPurchased(id:)` で確認する。購入データ未取得の場合は `nil` を返す:

```swift
struct ContentView: View {
    @Environment(InAppPurchaseState.self) private var state

    var body: some View {
        if state.isPurchased(id: "com.example.app.pro") == true {
            Text("購入済み")
        }
    }
}
```

### 3. 購入 UI を表示する

#### StoreKit ビューを使う場合

`ProductView` に `.onStoreKitViewPurchase` を付与すると、購入中のローディング状態管理と購入結果のコールバックが有効になる。StoreKit ビュー (ProductView / StoreView / SubscriptionStoreView) に対してのみ有効:

```swift
ProductView(id: "com.example.app.pro")
    .onStoreKitViewPurchase(
        onCompletion: { product, outcome in
            if outcome == .purchased {
                print("購入成功: \(product.id)")
            }
        },
        onFailure: { error in
            print("購入失敗: \(error)")
        }
    )
```

コールバックが不要な場合は引数なしで付与する。ローディング状態の管理のみ行われる:

```swift
ProductView(id: "com.example.app.pro")
    .onStoreKitViewPurchase()
```

`.onStoreKitViewPurchase` を付与しない場合、購入成功トランザクションは `Transaction.updates` 経由で処理され、エラー時は StoreKit のデフォルトアラートが表示される。

#### カスタム UI を使う場合

`products` からプロダクト情報を取得し、独自の UI を構築できる。`import StoreKit` は不要:

```swift
import InAppPurchaseKit

struct PaywallView: View {
    @Environment(InAppPurchaseState.self) private var state

    var body: some View {
        ForEach(state.products) { product in
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                    Text(product.description)
                        .font(.caption)
                }
                Spacer()
                if state.isPurchased(id: product.id) == true {
                    Text("購入済み")
                } else {
                    Button(product.displayPrice) {
                        Task {
                            let outcome = try await state.purchase(product)
                            if outcome == .pending {
                                // 保護者の承認待ち (Ask to Buy)
                            }
                        }
                    }
                }
            }
        }
    }
}
```

`purchase(_:)` は `PurchaseOutcome` を返す。キャンセルや保留はエラーではなく戻り値で表現されるため、`catch` ブロックは実際のエラーのみを扱えばよい。visionOS では利用不可。

### 購入の復元

```swift
Button("購入を復元") {
    Task {
        try await state.restorePurchases()
    }
}
```

### 購入済みでビューを非表示にする

プロダクトが購入済みの間、広告バナーなどを非表示にする。初回同期が完了するまでも非表示になる (未購入と確定するまで表示しないため):

```swift
AdBannerView()
    .hiddenIfPurchased(id: "com.example.app.pro")
```
