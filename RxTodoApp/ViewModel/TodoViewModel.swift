import Foundation
import RxSwift
import RxCocoa

final class TodoViewModel {

    // MARK: - Input
    let addTodoTitle = PublishRelay<String>()
    let toggleTodo = PublishRelay<Int>()
    let deleteTodo = PublishRelay<Int>()
    let filterText = BehaviorRelay<String>(value: "")

    // MARK: - Output
    let filteredTodos: Observable<[TodoItem]>
    let todoCount: Observable<String>
    let completedCount: Observable<String>

    private let todos = BehaviorRelay<[TodoItem]>(value: [
        TodoItem(title: "RxSwiftを学ぶ"),
        TodoItem(title: "BehaviorRelayを使う"),
        TodoItem(title: "MVVMパターンを実装する", isCompleted: true)
    ])

    private let disposeBag = DisposeBag()

    init() {
        // フィルタリング: todos と filterText を組み合わせる
        filteredTodos = Observable
            .combineLatest(todos, filterText) { items, query in
                guard !query.isEmpty else { return items }
                return items.filter { $0.title.localizedCaseInsensitiveContains(query) }
            }

        // 統計情報
        todoCount = todos.map { "全\($0.count)件" }
        completedCount = todos.map { items in
            let done = items.filter { $0.isCompleted }.count
            return "完了: \(done)件"
        }

        // ToDo追加
        addTodoTitle
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .subscribe(onNext: { [weak self] title in
                guard let self else { return }
                var current = self.todos.value
                current.append(TodoItem(title: title))
                self.todos.accept(current)
            })
            .disposed(by: disposeBag)

        // 完了トグル（filteredTodos ではなく todos 全体のインデックスで操作）
        toggleTodo
            .withLatestFrom(filteredTodos) { index, filtered in filtered[index] }
            .subscribe(onNext: { [weak self] item in
                guard let self else { return }
                var current = self.todos.value
                if let idx = current.firstIndex(where: { $0.id == item.id }) {
                    current[idx].isCompleted.toggle()
                    self.todos.accept(current)
                }
            })
            .disposed(by: disposeBag)

        // 削除
        deleteTodo
            .withLatestFrom(filteredTodos) { index, filtered in filtered[index] }
            .subscribe(onNext: { [weak self] item in
                guard let self else { return }
                let updated = self.todos.value.filter { $0.id != item.id }
                self.todos.accept(updated)
            })
            .disposed(by: disposeBag)
    }
}
