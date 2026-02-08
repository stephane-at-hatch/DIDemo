import ModularNavigation
import DetailScreen
import SwiftUI

// MARK: - ViewState Enum

extension DiscoverScreen {
    enum DestinationState {
        case main(DiscoverViewModel)
        case detail(DetailScreen.Entry)
    }
}
