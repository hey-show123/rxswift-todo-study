import RxSwift

struct ToggleFavoriteUseCase {
    private let repository: VideoRepository
    init(repository: VideoRepository) { self.repository = repository }

    func execute(videoID: String) -> Observable<Video> {
        repository.toggleFavorite(videoID: videoID)
    }
}
