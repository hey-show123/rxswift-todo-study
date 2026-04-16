# RxSwift ToDo App

RxSwift + MVVM パターンで実装したシンプルな ToDo アプリ。

## 構成

```
RxTodoApp/
├── Package.swift
└── RxTodoApp/
    ├── AppDelegate.swift
    ├── Model/
    │   └── TodoItem.swift          # データモデル
    ├── ViewModel/
    │   └── TodoViewModel.swift     # ビジネスロジック (RxSwift)
    └── View/
        ├── TodoViewController.swift # メイン画面
        └── TodoCell.swift           # カスタムセル
```

## 使用している RxSwift の主要コンセプト

| 概念 | 使用箇所 |
|------|---------|
| `BehaviorRelay` | todos リスト・フィルターテキストの状態管理 |
| `PublishRelay` | 追加・削除・トグルのイベント伝達 |
| `Observable.combineLatest` | todos + filterText を合成してフィルタリング |
| `withLatestFrom` | インデックスとデータを安全に組み合わせる |
| `bind(to:)` | ViewModel → View への一方向データバインディング |
| `rx.items` | TableView への自動バインディング |
| `rx.text` / `rx.itemSelected` | UIKit イベントの Observable 化 |
| `DisposeBag` | メモリリーク防止のためのサブスクリプション管理 |

## 機能

- ToDo の一覧表示
- ToDo の追加（ナビゲーションバー右の + ボタン）
- 完了/未完了のトグル（セルタップ）
- 削除（左スワイプ）
- リアルタイム検索フィルター
- 全件数・完了件数の統計表示
