import Foundation

struct Video: Equatable {
    let id: String
    let title: String
    let duration: TimeInterval
    let category: Category
    let description: String
    let viewCount: Int
    var isFavorite: Bool

    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id
    }
}

enum Category: String, CaseIterable {
    case all         = "すべて"
    case drama       = "ドラマ"
    case variety     = "バラエティ"
    case documentary = "ドキュメンタリー"
    case anime       = "アニメ"
    case movie       = "映画"
}
