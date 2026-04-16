import UIKit
import RxSwift
import RxCocoa

final class TodoViewController: UIViewController {

    // MARK: - UI
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "検索..."
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(TodoCell.self, forCellReuseIdentifier: TodoCell.identifier)
        tv.rowHeight = 52
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Properties
    private let viewModel = TodoViewModel()
    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "RxSwift ToDo"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )

        view.addSubview(searchBar)
        view.addSubview(statsLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            statsLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bind
    private func bindViewModel() {
        // SearchBar → ViewModel
        searchBar.rx.text.orEmpty
            .bind(to: viewModel.filterText)
            .disposed(by: disposeBag)

        // ViewModel → TableView
        viewModel.filteredTodos
            .bind(to: tableView.rx.items(cellIdentifier: TodoCell.identifier, cellType: TodoCell.self)) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        // セルタップ → 完了トグル
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .map { $0.row }
            .bind(to: viewModel.toggleTodo)
            .disposed(by: disposeBag)

        // スワイプ削除
        tableView.rx.itemDeleted
            .map { $0.row }
            .bind(to: viewModel.deleteTodo)
            .disposed(by: disposeBag)

        // 統計ラベル
        Observable.combineLatest(viewModel.todoCount, viewModel.completedCount)
            .map { "\($0.0)  /  \($0.1)" }
            .bind(to: statsLabel.rx.text)
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    @objc private func addTapped() {
        let alert = UIAlertController(title: "ToDo追加", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "タイトルを入力" }
        alert.addAction(UIAlertAction(title: "追加", style: .default) { [weak self, weak alert] _ in
            guard let text = alert?.textFields?.first?.text else { return }
            self?.viewModel.addTodoTitle.accept(text)
        })
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        present(alert, animated: true)
    }
}
