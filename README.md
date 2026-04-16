# RxStream サンプル — 動画配信サービス iOS アプリ

RxSwift × UIKit × Clean Architecture で構築した動画配信サービスのサンプル実装。
**リードエンジニアとして設計方針・アーキテクチャ改善・テスト戦略**まで意識した構成にしています。

## アーキテクチャ

```
Presentation ──▶ Domain ◀── Data
```

| レイヤー | 役割 |
|---------|------|
| **Domain** | Entity・Repository Protocol・UseCase（ビジネスロジック） |
| **Data** | Repository の具体実装（API・DB・キャッシュ） |
| **Presentation** | ViewModel (I/O パターン)・ViewController・Coordinator |

依存方向を一方向に保ち、`Data` と `Presentation` は `Domain` のプロトコルにのみ依存します。
`VideoRepositoryImpl` をモックに差し替えるだけでテストが通る構造です。

## 使用している RxSwift オペレータ

| オペレータ | 目的 |
|-----------|------|
| `flatMapLatest` | カテゴリ変更時に前のAPIリクエストをキャンセル |
| `scan` | お気に入りトグルをリスト全体の再取得なしで差分更新 |
| `debounce` + `distinctUntilChanged` | 検索入力の300ms待機・重複排除 |
| `share(replay: 1)` | `fetchedVideos` をマルチキャストして多重リクエスト防止 |
| `withLatestFrom` | リフレッシュトリガーに最新カテゴリを組み合わせる |
| `merge` | fetch trigger と refresh trigger を単一ストリームへ |
| `catch` | エラーをUI側に伝えつつストリームを継続 |
| `Driver` | メインスレッド保証・エラー終了なし（UIバインディング専用） |
| `startWith` | 初期値の注入（カテゴリ・検索クエリ） |
| `BehaviorRelay` / `PublishRelay` | 状態管理 / イベント発火 |

## ViewModel: Input / Output パターン

```swift
let output = viewModel.transform(input: Input(
    selectedCategory: segment.rx.selectedSegmentIndex.map { Category.allCases[$0] },
    searchQuery:      searchBar.rx.text.orEmpty.asObservable(),
    favoriteToggled:  favoriteToggleRelay.asObservable(),
    refreshTrigger:   refreshControl.rx.controlEvent(.valueChanged).asObservable(),
    selectedVideo:    tableView.rx.modelSelected(Video.self).asObservable()
))
```

ViewController は I/O を渡すだけ。ViewModel 内に RxSwift ロジックを閉じ込め、
テスト時は `MockVideoRepository` を注入するだけで全ロジックを検証できます。

## Coordinator パターン

画面遷移ロジックを ViewController から分離。
`VideoCoordinator` が Repository を保持し、UseCase → ViewModel → ViewController へ DI します。

```
AppCoordinator
  └── VideoCoordinator
        ├── VideoListViewController
        └── VideoDetailViewController
```

## テスト

```bash
xcodebuild test \
  -project RxTodoApp.xcodeproj \
  -scheme RxTodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16"
```

`MockVideoRepository` によるユニットテストを実装：

- 初期ロードで全ビデオ取得
- カテゴリ変更でフィルタリング
- 検索クエリのフィルタリング
- お気に入りトグルの差分更新
- APIエラー時のエラーメッセージ伝播

## CI/CD (GitHub Actions)

`.github/workflows/ci.yml` にて `main` ブランチへの push / PR 時にビルド＋テストを自動実行。

## セットアップ

```bash
# xcodegen でプロジェクト生成
brew install xcodegen
xcodegen generate

# Xcode で開く
open RxTodoApp.xcodeproj
```
