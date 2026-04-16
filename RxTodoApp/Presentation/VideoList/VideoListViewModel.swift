import RxSwift
import RxCocoa

// MARK: - State Action (for scan-based state management)
private enum VideoListAction {
    case loaded([Video])
    case favoriteUpdated(Video)
}

final class VideoListViewModel {

    // MARK: - Input / Output (テスタビリティを高めるI/Oパターン)
    struct Input {
        let selectedCategory: Observable<Category>
        let searchQuery: Observable<String>
        let favoriteToggled: Observable<String>   // videoID
        let refreshTrigger: Observable<Void>
        let selectedVideo: Observable<Video>
    }

    struct Output {
        let videos: Driver<[Video]>
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String>
        let navigateToDetail: Driver<Video>
    }

    // MARK: - Dependencies
    private let fetchVideosUseCase: FetchVideosUseCase
    private let searchVideosUseCase: SearchVideosUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let disposeBag = DisposeBag()

    init(
        fetchVideosUseCase: FetchVideosUseCase,
        searchVideosUseCase: SearchVideosUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase
    ) {
        self.fetchVideosUseCase = fetchVideosUseCase
        self.searchVideosUseCase = searchVideosUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
    }

    func transform(input: Input) -> Output {
        let isLoading     = BehaviorRelay<Bool>(value: false)
        let errorRelay    = PublishRelay<String>()

        // カテゴリを replay して後段で参照可能にする
        let currentCategory = input.selectedCategory
            .startWith(.all)
            .distinctUntilChanged()
            .share(replay: 1)

        // 検索クエリ: 300ms debounce + 重複排除
        let debouncedQuery = input.searchQuery
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .startWith("")
            .share(replay: 1)

        // カテゴリ変更 or 手動リフレッシュ → API コール（flatMapLatest で前のリクエストをキャンセル）
        let fetchTrigger = Observable.merge(
            currentCategory.map { _ in () },
            input.refreshTrigger
        )

        let fetchedVideos = fetchTrigger
            .do(onNext: { _ in isLoading.accept(true) })
            .withLatestFrom(currentCategory)
            .flatMapLatest { [weak self] category -> Observable<[Video]> in
                guard let self else { return .empty() }
                return self.fetchVideosUseCase.execute(category: category)
                    .catch { error in
                        errorRelay.accept("読み込みエラー: \(error.localizedDescription)")
                        return .just([])
                    }
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .share(replay: 1)

        // お気に入りトグル
        let favoriteUpdated = input.favoriteToggled
            .flatMapLatest { [weak self] videoID -> Observable<Video> in
                guard let self else { return .empty() }
                return self.toggleFavoriteUseCase.execute(videoID: videoID)
                    .catch { _ in .empty() }
            }

        // scan でリスト状態を管理 (全件再取得せず差分更新)
        let videoState = Observable.merge(
            fetchedVideos.map    { VideoListAction.loaded($0) },
            favoriteUpdated.map  { VideoListAction.favoriteUpdated($0) }
        )
        .scan([Video]()) { current, action -> [Video] in
            switch action {
            case .loaded(let videos):
                return videos
            case .favoriteUpdated(let updated):
                return current.map { $0.id == updated.id ? updated : $0 }
            }
        }
        .share(replay: 1)

        // 検索クエリがある場合は SearchUseCase、なければキャッシュ済みリストをフィルタリング
        let videos = Observable.combineLatest(videoState, debouncedQuery)
            .flatMapLatest { [weak self] (base, query) -> Observable<[Video]> in
                guard let self else { return .empty() }
                guard !query.isEmpty else { return .just(base) }
                return self.searchVideosUseCase.execute(query: query)
                    .catch { _ in .just([]) }
            }
            .asDriver(onErrorJustReturn: [])

        return Output(
            videos: videos,
            isLoading: isLoading.asDriver(),
            errorMessage: errorRelay.asDriver(onErrorJustReturn: ""),
            navigateToDetail: input.selectedVideo.asDriver(onErrorJustReturn: Video(id: "", title: "", duration: 0, category: .all, description: "", viewCount: 0, isFavorite: false))
        )
    }
}
