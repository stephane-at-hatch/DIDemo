import ModularNavigation
import DetailScreen
import SwiftUI

// MARK: - ViewState Enum

extension BoxOfficeScreen {
    enum DestinationViewState {
        case main(BoxOfficeViewModel)
        case detail(DetailScreen.Entry)
    }
}
