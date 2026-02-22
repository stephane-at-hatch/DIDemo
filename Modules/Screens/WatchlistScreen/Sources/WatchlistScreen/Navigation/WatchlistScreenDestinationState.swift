import ModularNavigation
import DetailScreen
import SwiftUI

// MARK: - ViewState Enum

extension WatchlistScreen {
    enum DestinationState {
        case main(WatchlistViewModel)
        case detail(DetailScreen.Entry)
    }
}
