import UIKit
import RxSwift
import RxCocoa

final class VideoDetailViewController: UIViewController {

    private let thumbnailPlaceholder: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        let icon = UIImageView(image: UIImage(systemName: "play.rectangle.fill"))
        icon.tintColor = .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60),
        ])
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let categoryBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = .systemBlue
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let favoriteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "heart")
        config.title = "お気に入り追加"
        config.imagePadding = 8
        config.baseBackgroundColor = .systemRed
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let viewModel: VideoDetailViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: VideoDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        [thumbnailPlaceholder, categoryBadge, titleLabel, metaLabel, descriptionLabel, favoriteButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            thumbnailPlaceholder.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            thumbnailPlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbnailPlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbnailPlaceholder.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9/16),

            categoryBadge.topAnchor.constraint(equalTo: thumbnailPlaceholder.bottomAnchor, constant: 16),
            categoryBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryBadge.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            favoriteButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            favoriteButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            favoriteButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            favoriteButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func bindViewModel() {
        let output = viewModel.makeOutput()

        output.title
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        output.categoryBadge
            .drive(onNext: { [weak self] in self?.categoryBadge.text = " \($0) " })
            .disposed(by: disposeBag)

        output.description
            .drive(descriptionLabel.rx.text)
            .disposed(by: disposeBag)

        output.meta
            .drive(metaLabel.rx.text)
            .disposed(by: disposeBag)

        output.isFavorite
            .drive(onNext: { [weak self] isFav in
                guard let self else { return }
                var config = self.favoriteButton.configuration
                config?.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
                config?.title = isFav ? "お気に入り済み" : "お気に入り追加"
                config?.baseBackgroundColor = isFav ? .systemGray : .systemRed
                self.favoriteButton.configuration = config
            })
            .disposed(by: disposeBag)

        favoriteButton.rx.tap
            .bind(to: viewModel.favoriteToggleTap)
            .disposed(by: disposeBag)
    }
}
