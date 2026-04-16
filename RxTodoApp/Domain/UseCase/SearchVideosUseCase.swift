import RxSwift

struct SearchVideosUseCase {
    private let repository: VideoRepository
    init(repository: VideoRepository) { self.repository = repository }

    func execute(query: String) -> Observable<[Video]> {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return .just([]) }
        return repository.searchVideos(query: query)
    }
}
