import Foundation
import RxSwift
@testable import RxTodoApp

final class MockVideoRepository: VideoRepository {

    var mockVideos: [Video] = [
        Video(id: "1", title: "ドラマA", duration: 3600, category: .drama, description: "ドラマの説明", viewCount: 10000, isFavorite: false),
        Video(id: "2", title: "バラエティB", duration: 2700, category: .variety, description: "バラエティの説明", viewCount: 20000, isFavorite: false),
    ]
    var shouldFail = false
    private var favorites: Set<String> = []

    func fetchVideos(category: RxTodoApp.Category) -> Observable<[Video]> {
        if shouldFail {
            return Observable.create { observer in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    observer.onError(RepositoryError.networkError)
                }
                return Disposables.create()
            }
        }
        let filtered = category == .all ? mockVideos : mockVideos.filter { $0.category == category }
        return .just(filtered)
    }

    func searchVideos(query: String) -> Observable<[Video]> {
        let results = mockVideos.filter { $0.title.localizedCaseInsensitiveContains(query) }
        return .just(results)
    }

    func toggleFavorite(videoID: String) -> Observable<Video> {
        if favorites.contains(videoID) { favorites.remove(videoID) }
        else { favorites.insert(videoID) }
        guard var video = mockVideos.first(where: { $0.id == videoID }) else {
            return .error(RepositoryError.notFound)
        }
        video.isFavorite = favorites.contains(videoID)
        return .just(video)
    }
}
