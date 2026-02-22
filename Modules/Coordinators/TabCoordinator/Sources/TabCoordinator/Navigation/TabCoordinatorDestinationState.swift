import BoxOfficeScreen
import DiscoverScreen
import ModularNavigation
import SwiftUI
import WatchlistScreen

// MARK: - Destination-Specific ViewStates

// MARK: - ViewState Enum

extension TabCoordinator {
    enum DestinationState {
        case boxOffice(BoxOfficeScreen.Entry)
        case discover(DiscoverScreen.Entry)
        case watchlist(WatchlistScreen.Entry)
    }
}
