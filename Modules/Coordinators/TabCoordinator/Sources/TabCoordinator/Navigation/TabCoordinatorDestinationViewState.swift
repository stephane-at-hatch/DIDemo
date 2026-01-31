import ModularNavigation
import SwiftUI
import ScreenA
import ScreenC
import ScreenD

// MARK: - ViewState Enum

extension TabCoordinator {
    enum DestinationViewState {
        case firstTab(ScreenA.Entry)
        case secondTab(ScreenC.Entry)
        case thirdTab(ScreenD.Entry)
    }
}
