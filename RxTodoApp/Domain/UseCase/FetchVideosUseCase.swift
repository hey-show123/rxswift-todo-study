import RxSwift

struct FetchVideosUseCase {
    private let repository: VideoRepository
    init(repository: VideoRepository) { self.repository = repository }

    func execute(category: Category) -> Observable<[Video]> {
        repository.fetchVideos(category: category)
    }
}
