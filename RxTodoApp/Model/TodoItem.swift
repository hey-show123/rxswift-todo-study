import Foundation

struct TodoItem {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}
