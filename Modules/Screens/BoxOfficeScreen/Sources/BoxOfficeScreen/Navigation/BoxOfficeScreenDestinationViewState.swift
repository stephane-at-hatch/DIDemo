import ModularNavigation
import DetailScreen
import SwiftUI

// MARK: - ViewState Enum

extension BoxOfficeScreen {
    struct DetailDestinationViewState {
        let entry: DetailScreen.Entry
    }

    enum DestinationViewState {
        case main(BoxOfficeViewModel)
        case detail(DetailDestinationViewState)
    }
}
