import UIKit

final class VideoCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let repository: VideoRepository = VideoRepositoryImpl()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = VideoListViewModel(
            fetchVideosUseCase: FetchVideosUseCase(repository: repository),
            searchVideosUseCase: SearchVideosUseCase(repository: repository),
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository)
        )
        let vc = VideoListViewController(viewModel: viewModel, coordinator: self)
        navigationController.setViewControllers([vc], animated: false)
    }

    func showDetail(video: Video) {
        let viewModel = VideoDetailViewModel(video: video, repository: repository)
        let vc = VideoDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
