import UIKit
import RxSwift
import RxCocoa

final class VideoListViewController: UIViewController {

    // MARK: - UI
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "タイトル・説明で検索"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private let categorySegment: UISegmentedControl = {
        let items = Category.allCases.map { $0.rawValue }
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(VideoCell.self, forCellReuseIdentifier: VideoCell.identifier)
        tv.rowHeight = 72
        tv.separatorInset = UIEdgeInsets(top: 0, left: 108, bottom: 0, right: 0)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Properties
    private let viewModel: VideoListViewModel
    private weak var coordinator: VideoCoordinator?
    private let disposeBag = DisposeBag()

    private let favoriteToggleRelay = PublishRelay<String>()

    // MARK: - Init
    init(viewModel: VideoListViewModel, coordinator: VideoCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "動画一覧"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        view.addSubview(categorySegment)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            categorySegment.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            categorySegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categorySegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: categorySegment.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Binding
    private func bindViewModel() {
        let categorySelected = categorySegment.rx.selectedSegmentIndex
            .map { Category.allCases[$0] }
            .asObservable()

        let input = VideoListViewModel.Input(
            selectedCategory: categorySelected,
            searchQuery: searchBar.rx.text.orEmpty.asObservable(),
            favoriteToggled: favoriteToggleRelay.asObservable(),
            refreshTrigger: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            selectedVideo: tableView.rx.modelSelected(Video.self).asObservable()
        )

        let output = viewModel.transform(input: input)

        // ビデオ一覧 → テーブルビュー
        output.videos
            .drive(tableView.rx.items(cellIdentifier: VideoCell.identifier, cellType: VideoCell.self)) { [weak self] _, video, cell in
                cell.configure(with: video)
                cell.onFavoriteTapped = { self?.favoriteToggleRelay.accept(video.id) }
            }
            .disposed(by: disposeBag)

        // ローディング
        output.isLoading
            .drive(onNext: { [weak self] loading in
                loading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
                if !loading { self?.refreshControl.endRefreshing() }
            })
            .disposed(by: disposeBag)

        // エラー表示
        output.errorMessage
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] message in
                let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)

        // 画面遷移
        output.navigateToDetail
            .drive(onNext: { [weak self] video in
                self?.coordinator?.showDetail(video: video)
            })
            .disposed(by: disposeBag)

        // セル選択の解除
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
