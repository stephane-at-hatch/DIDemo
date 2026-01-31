import ModularNavigation
import SwiftUI

// MARK: - ViewModel Enum

extension ScreenB {
    enum DestinationViewState {
        case main(ScreenBViewModel)
        case testPage
    }
}
