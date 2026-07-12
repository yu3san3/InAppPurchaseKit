# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

StoreKit 2 のアプリ内購入を SwiftUI で扱うユーティリティライブラリ。
`@Observable` + Environment による購入状態共有、`ProductIdentifiable` プロトコルによる型安全なプロダクト ID 管理を提供する。

- Swift Package (swift-tools-version: 6.3, Swift Concurrency / Strict Sendable 有効)
- 対応プラットフォーム: iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+ / visionOS 1+

## ビルド・テスト

```bash
# ビルド (macOS)
swift build

# テスト (Swift Testing フレームワーク使用)
swift test

# 特定テストのみ実行
swift test --filter InAppPurchaseStateTests/isPurchasedTrue

# iOS シミュレータ向けビルド
xcodebuild build -scheme InAppPurchaseKit -destination 'platform=iOS Simulator,name=iPhone 16'
```

StoreKit API はシミュレータ/実機でしか動作しないため、`swift test` (macOS ネイティブ) で実行可能なテストは `InAppPurchaseState.preview()` を使ったロジックテストに限られる。

## アーキテクチャ

### 状態管理の流れ

```
App root
  └─ .inAppPurchaseContainer(ProductID.self)   ← InAppPurchaseContainer.swift
       ├─ @State InAppPurchaseState<ProductID>  ← 生成・Environment に注入
       ├─ .task { sync() → observeTransactionUpdates() }
       └─ 子ビュー
            ├─ @Environment(PurchaseState.self) で購入状態を読み取り
            ├─ .onStoreKitViewPurchase(for:)     ← StoreKitViewPurchaseModifier.swift
            └─ .hiddenIfPurchased(id:)           ← HiddenIfPurchasedModifier.swift
```

### ジェネリクス設計

すべての public API は `<ProductID: ProductIdentifiable>` でジェネリック。利用側が `enum ProductID: String, ProductIdentifiable` を定義し、型パラメータとして渡す。`InAppPurchaseState<ProductID>` が Environment のキーになるため、異なるプロダクト ID 型は互いに干渉しない。

### Phase (状態遷移)

`InAppPurchaseState.Phase` はライフサイクルを管理する:

- `idle` → `initializing` → `ready` (初回同期)
- `ready` → `updating` → `ready` (購入・復元・再同期)
- いずれの段階でも → `failed` (プロダクト取得失敗時)

`isPurchased(_:)` は `hasInitialized == false` の間 `nil` を返す。UI 側は `nil` を「まだ分からない」として扱う。

### テスト

Swift Testing フレームワーク (`import Testing`, `@Test`, `#expect`) を使用。XCTest は使わない。
テスト用インスタンスは `InAppPurchaseState.preview(phase:purchased:)` で生成する。

## 注意点

- ViewModifier は `private struct` + `extension View` の公開メソッドで提供するパターン
