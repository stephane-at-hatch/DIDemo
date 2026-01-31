import ScreenB
import ModularNavigation
import SwiftUI

// MARK: - Destination-Specific ViewModels

// MARK: - Public Destination ViewModels

extension ScreenA {

    enum DestinationViewState {
        case main(ScreenAViewModel)
        case screenB(ScreenB.Entry)
    }
}
