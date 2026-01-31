import ModularNavigation
import SwiftUI
import ScreenA
import ScreenC
import ScreenD

public extension TabCoordinator {
    @MainActor
    static func mockBuilder() -> Builder {
        { destination, mode, navigationClient in
            let viewState: DestinationViewState
            
            switch destination.type {
            case .tab(let tabDestination):
                switch tabDestination {
                case .first:
                    let entry = ScreenA.mockEntry()
                    viewState = .firstTab(entry)
                case .second:
                    let entry = ScreenC.mockEntry()
                    viewState = .secondTab(entry)
                case .third:
                    let entry = ScreenD.mockEntry()
                    viewState = .thirdTab(entry)
                }
            }
            
            return DestinationView(
                viewState: viewState,
                mode: mode,
                client: navigationClient
            )
        }
    }
}
