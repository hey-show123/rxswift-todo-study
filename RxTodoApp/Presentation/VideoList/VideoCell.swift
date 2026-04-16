import UIKit

final class VideoCell: UITableViewCell {
    static let identifier = "VideoCell"

    private let thumbnailView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemFill
        v.layer.cornerRadius = 6
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let categoryBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = .systemBlue
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let favoriteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "heart"), for: .normal)
        b.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        b.tintColor = .systemRed
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    var onFavoriteTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        favoriteButton.addTarget(self, action: #selector(favTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        [thumbnailView, titleLabel, metaLabel, favoriteButton].forEach { contentView.addSubview($0) }
        thumbnailView.addSubview(categoryBadge)

        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailView.heightAnchor.constraint(equalToConstant: 52),

            categoryBadge.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: 4),
            categoryBadge.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -4),
            categoryBadge.heightAnchor.constraint(equalToConstant: 16),
            categoryBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            favoriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func configure(with video: Video) {
        titleLabel.text = video.title
        categoryBadge.text = " \(video.category.rawValue) "
        let minutes = Int(video.duration) / 60
        let views = video.viewCount >= 10000
            ? String(format: "%.1f万回視聴", Double(video.viewCount) / 10000)
            : "\(video.viewCount)回視聴"
        metaLabel.text = "\(minutes)分  ·  \(views)"
        favoriteButton.isSelected = video.isFavorite
    }

    @objc private func favTapped() { onFavoriteTapped?() }
}
