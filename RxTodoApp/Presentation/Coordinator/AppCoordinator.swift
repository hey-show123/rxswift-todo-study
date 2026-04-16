import UIKit

final class AppCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let coordinator = VideoCoordinator(navigationController: navigationController)
        coordinator.start()
    }
}
