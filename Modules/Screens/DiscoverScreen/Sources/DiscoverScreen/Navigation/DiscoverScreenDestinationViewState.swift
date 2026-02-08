import ModularNavigation
import DetailScreen
import SwiftUI

// MARK: - ViewState Enum

extension DiscoverScreen {
    enum DestinationViewState {
        case main(DiscoverViewModel)
        case detail(DetailScreen.Entry)
    }
}
