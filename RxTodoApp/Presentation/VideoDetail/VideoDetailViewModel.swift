import RxSwift
import RxCocoa

final class VideoDetailViewModel {

    struct Output {
        let title: Driver<String>
        let categoryBadge: Driver<String>
        let description: Driver<String>
        let meta: Driver<String>
        let isFavorite: Driver<Bool>
    }

    private let video: BehaviorRelay<Video>
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let disposeBag = DisposeBag()

    let favoriteToggleTap = PublishRelay<Void>()

    init(video: Video, repository: VideoRepository) {
        self.video = BehaviorRelay(value: video)
        self.toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: repository)

        favoriteToggleTap
            .withLatestFrom(self.video)
            .flatMapLatest { [weak self] current -> Observable<Video> in
                guard let self else { return .empty() }
                return self.toggleFavoriteUseCase.execute(videoID: current.id)
                    .catch { _ in .empty() }
            }
            .bind(to: self.video)
            .disposed(by: disposeBag)
    }

    func makeOutput() -> Output {
        let v = video.asDriver()
        return Output(
            title: v.map { $0.title },
            categoryBadge: v.map { $0.category.rawValue },
            description: v.map { $0.description },
            meta: v.map { video in
                let min = Int(video.duration) / 60
                let views = video.viewCount >= 10000
                    ? String(format: "%.1f万回視聴", Double(video.viewCount) / 10000)
                    : "\(video.viewCount)回視聴"
                return "\(min)分  ·  \(views)"
            },
            isFavorite: v.map { $0.isFavorite }
        )
    }
}
