import ModularNavigation
import SwiftUI

// MARK: - Destination-Specific ViewStates

extension TabCoordinator {
    struct MainDestinationViewState {
        // TODO: Replace with actual ViewModel type
        let viewModel: Any?
    }

}

// MARK: - ViewState Enum

extension TabCoordinator {
    enum DestinationViewState {
        case main(MainDestinationViewState)
    }
}
