import BoxOfficeScreen
import ModularNavigation
import SwiftUI

// MARK: - Destination-Specific ViewStates

// MARK: - ViewState Enum

extension TabCoordinator {
    enum DestinationViewState {
        case boxOffice(BoxOfficeScreen.Entry)
        case discover
        case watchlist
    }
}
