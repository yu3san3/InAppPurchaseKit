# InAppPurchaseKit

A SwiftUI Utility for Managing In-App Purchases.

#### 1. Use `inAppPurchaseContainer` as the root view
```swift
import GlobalAlert

struct YourApp: View {
    var body: some View {
        ContentView()
            .inAppPurchaseContainer()
    }
}
```

#### 2. Use `InAppPurchaseState` to handle purchases
```swift
struct ContentView: View {
    @EnvironmentObject var inAppPurchaseState: InAppPurchaseState

    var body: some View {
        if inAppPurchaseState.isPurchased(id: "ProductId") {
            Text("Purchased!")
        } else {
            Button("Buy") {}
        }
    }
}
```
