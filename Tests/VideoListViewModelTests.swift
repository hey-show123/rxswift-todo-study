import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
@testable import RxTodoApp

final class VideoListViewModelTests: XCTestCase {

    var disposeBag: DisposeBag!
    var repository: MockVideoRepository!
    var viewModel: VideoListViewModel!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        repository = MockVideoRepository()
        viewModel = VideoListViewModel(
            fetchVideosUseCase: FetchVideosUseCase(repository: repository),
            searchVideosUseCase: SearchVideosUseCase(repository: repository),
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository)
        )
    }

    // MARK: - Tests

    func test_初期ロードですべてのビデオが取得される() throws {
        let categoryRelay = BehaviorRelay<RxTodoApp.Category>(value: .all)
        let input = makeInput(category: categoryRelay.asObservable())
        let output = viewModel.transform(input: input)

        let videos = try output.videos.toBlocking(timeout: 2).first()
        XCTAssertEqual(videos?.count, repository.mockVideos.count)
    }

    func test_カテゴリ変更でドラマのみフィルタされる() throws {
        let categoryRelay = BehaviorRelay<RxTodoApp.Category>(value: .all)
        let input = makeInput(category: categoryRelay.asObservable())
        let output = viewModel.transform(input: input)

        var results: [[Video]] = []
        output.videos.drive(onNext: { results.append($0) }).disposed(by: disposeBag)

        categoryRelay.accept(.drama)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertTrue(results.last?.allSatisfy { $0.category == .drama } ?? false)
    }

    func test_検索クエリでタイトルフィルタされる() throws {
        let searchRelay = BehaviorRelay<String>(value: "")
        let input = makeInput(searchQuery: searchRelay.asObservable())
        let output = viewModel.transform(input: input)

        var results: [[Video]] = []
        output.videos.drive(onNext: { results.append($0) }).disposed(by: disposeBag)

        searchRelay.accept("ドラマ")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        XCTAssertTrue(results.last?.allSatisfy { $0.title.contains("ドラマ") } ?? false)
    }

    func test_お気に入りトグルで状態が差分更新される() throws {
        let favoriteRelay = PublishRelay<String>()
        let input = makeInput(favoriteToggled: favoriteRelay.asObservable())
        let output = viewModel.transform(input: input)

        var results: [[Video]] = []
        output.videos.drive(onNext: { results.append($0) }).disposed(by: disposeBag)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        favoriteRelay.accept("1")
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let updatedVideo = results.last?.first { $0.id == "1" }
        XCTAssertEqual(updatedVideo?.isFavorite, true)
    }

    func test_APIエラー時にエラーメッセージが流れる() {
        repository.shouldFail = true
        let categoryRelay = PublishRelay<RxTodoApp.Category>()
        let input = makeInput(category: categoryRelay.asObservable())
        let output = viewModel.transform(input: input)

        let expectation = expectation(description: "エラーメッセージを受信する")

        // fetchedVideos パイプラインを起動するため output.videos も購読する
        output.videos.drive().disposed(by: disposeBag)

        output.errorMessage
            .filter { !$0.isEmpty }
            .drive(onNext: { _ in expectation.fulfill() })
            .disposed(by: disposeBag)

        // サブスクリプション設定後にカテゴリを送信してエラーをトリガー
        categoryRelay.accept(.all)

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Helpers

    private func makeInput(
        category: Observable<RxTodoApp.Category> = .just(.all),
        searchQuery: Observable<String> = .just(""),
        favoriteToggled: Observable<String> = .empty(),
        refreshTrigger: Observable<Void> = .empty(),
        selectedVideo: Observable<Video> = .empty()
    ) -> VideoListViewModel.Input {
        VideoListViewModel.Input(
            selectedCategory: category,
            searchQuery: searchQuery,
            favoriteToggled: favoriteToggled,
            refreshTrigger: refreshTrigger,
            selectedVideo: selectedVideo
        )
    }
}
