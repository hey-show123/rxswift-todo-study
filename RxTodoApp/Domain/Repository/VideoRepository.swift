import RxSwift

protocol VideoRepository {
    func fetchVideos(category: Category) -> Observable<[Video]>
    func searchVideos(query: String) -> Observable<[Video]>
    func toggleFavorite(videoID: String) -> Observable<Video>
}
