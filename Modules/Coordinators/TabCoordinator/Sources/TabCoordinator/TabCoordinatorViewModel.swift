import ModularNavigation
import SwiftUI

/// ViewModel for TabCoordinator
/// Manages navigation state between screens

enum Tab {
    case first
    case second
    case third
}

@MainActor
@Observable
public final class TabCoordinatorViewModel {

    // MARK: - Dependencies

    let navigationClient: NavigationClient<RootDestination>
    let builder: TabCoordinator.Builder

    // MARK: - Private State

    var currentTab: Tab = .first
    private var isNavigating = false
    
    // MARK: - Init

    public init(
        navigationClient: NavigationClient<RootDestination>? = nil,
        builder: @escaping TabCoordinator.Builder
    ) {
        self.navigationClient = navigationClient ?? .root()
        self.builder = builder
    }
    
    // MARK: - Navigation Methods
    
    public func navigateToFirstTab() {
        currentTab = .first
    }
    
    public func navigateToSecondTab() {
        currentTab = .second
    }

    public func navigateToThirdTab() {
        currentTab = .third
    }

    public func handleDeepLink(_ url: URL) {
        // TODO: Parse URL and navigate accordingly
    }
}
