import RxSwift
import Foundation

enum RepositoryError: Error {
    case notFound
    case networkError
}

final class VideoRepositoryImpl: VideoRepository {

    private var favorites: Set<String> = []

    private let allVideos: [Video] = [
        Video(id: "1",  title: "深夜食堂 Season 1",        duration: 3600, category: .drama,       description: "深夜の食堂を舞台にした人間ドラマ",             viewCount: 152000, isFavorite: false),
        Video(id: "2",  title: "深夜食堂 Season 2",        duration: 3600, category: .drama,       description: "シーズン2。常連客の新たなエピソード",          viewCount: 130000, isFavorite: false),
        Video(id: "3",  title: "水曜どうでしょう傑作選",      duration: 2700, category: .variety,    description: "伝説のバラエティ番組の名シーンを厳選",           viewCount: 234000, isFavorite: false),
        Video(id: "4",  title: "ガキの使いやあらへんで",      duration: 3600, category: .variety,    description: "笑いを届けるバラエティの金字塔",               viewCount: 198000, isFavorite: false),
        Video(id: "5",  title: "プラネットアース 4K",         duration: 3300, category: .documentary, description: "地球の自然を4Kで捉えた映像詩",              viewCount: 87000,  isFavorite: false),
        Video(id: "6",  title: "民族音楽の旅",               duration: 2400, category: .documentary, description: "世界各地の民族音楽を巡るドキュメンタリー",     viewCount: 41000,  isFavorite: false),
        Video(id: "7",  title: "鬼滅の刃 無限列車編",         duration: 7200, category: .anime,     description: "煉獄さんの炎は永遠に",                      viewCount: 512000, isFavorite: false),
        Video(id: "8",  title: "進撃の巨人 Final Season",   duration: 5400, category: .anime,     description: "マーレ編から描かれる完結への物語",              viewCount: 445000, isFavorite: false),
        Video(id: "9",  title: "PERFECT DAYS",              duration: 6360, category: .movie,     description: "ヴィム・ヴェンダース監督のカンヌ受賞作",        viewCount: 63000,  isFavorite: false),
        Video(id: "10", title: "ゴジラ-1.0",                duration: 7620, category: .movie,     description: "アカデミー賞視覚効果賞受賞のゴジラ最新作",      viewCount: 298000, isFavorite: false),
    ]

    func fetchVideos(category: Category) -> Observable<[Video]> {
        let filtered = category == .all
            ? allVideos
            : allVideos.filter { $0.category == category }
        let result = filtered.map { video -> Video in
            var v = video; v.isFavorite = favorites.contains(video.id); return v
        }
        return Observable.just(result)
            .delay(.milliseconds(300), scheduler: MainScheduler.instance)
    }

    func searchVideos(query: String) -> Observable<[Video]> {
        let results = allVideos.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }.map { video -> Video in
            var v = video; v.isFavorite = favorites.contains(video.id); return v
        }
        return Observable.just(results)
            .delay(.milliseconds(150), scheduler: MainScheduler.instance)
    }

    func toggleFavorite(videoID: String) -> Observable<Video> {
        if favorites.contains(videoID) { favorites.remove(videoID) }
        else { favorites.insert(videoID) }
        guard var video = allVideos.first(where: { $0.id == videoID }) else {
            return .error(RepositoryError.notFound)
        }
        video.isFavorite = favorites.contains(videoID)
        return .just(video)
    }
}
