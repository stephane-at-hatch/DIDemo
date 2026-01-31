import Foundation
import SwiftUI
import TabCoordinator

/// ViewModel for AppCoordinator
/// Manages navigation state between screens
@MainActor
@Observable
public final class AppCoordinatorViewModel {
    // MARK: Dependencies

    let tabCoordinatorViewModel: TabCoordinatorViewModel

    // MARK: - Init

    public static func live(
        dependencies: AppCoordinator.Dependencies
    ) -> AppCoordinatorViewModel {
        let tabCoordinatorDependencies = dependencies.buildChild(TabCoordinator.Dependencies.self)
        return AppCoordinatorViewModel(tabBuilder: TabCoordinator.liveBuilder(dependencies: tabCoordinatorDependencies))
    }

    public static func mock(
        dependencies: AppCoordinator.Dependencies
    ) -> AppCoordinatorViewModel {
        let tabCoordinatorDependencies = dependencies.buildChild(TabCoordinator.Dependencies.self)
        return AppCoordinatorViewModel(tabBuilder: TabCoordinator.liveBuilder(dependencies: tabCoordinatorDependencies))
    }

    init(
        tabBuilder: @escaping TabCoordinator.Builder
    ) {
        self.tabCoordinatorViewModel = TabCoordinatorViewModel(builder: tabBuilder)
    }

    public func handleDeepLink(_ url: URL) {
        // TODO: Parse URL and navigate accordingly
    }
}
