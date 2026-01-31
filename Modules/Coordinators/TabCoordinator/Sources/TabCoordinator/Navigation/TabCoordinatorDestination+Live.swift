import ModularNavigation
import SwiftUI
import ScreenA
import ScreenC
import ScreenD

public extension TabCoordinator {
    @MainActor
    static func liveBuilder(
        dependencies: Dependencies
    ) -> Builder {
        { destination, mode, navigationClient in
            let viewState: DestinationViewState
            
            switch destination.type {
            case .tab(let tabDestination):
                switch tabDestination {
                case .first:
                    let screenADependencies = dependencies.buildChild(ScreenA.Dependencies.self)
                    let builder = ScreenA.liveEntry(at: .main, dependencies: screenADependencies)
                    viewState = .firstTab(builder)
                case .second:
                    let screenCDependencies = dependencies.buildChild(ScreenC.Dependencies.self)
                    let entry = ScreenC.liveEntry(at: .main, dependencies: screenCDependencies)
                    viewState = .secondTab(entry)
                case .third:
                    let screenDDependencies = dependencies.buildChild(ScreenD.Dependencies.self)
                    let builder = ScreenD.liveEntry(at: .main, dependencies: screenDDependencies)
                    viewState = .thirdTab(builder)
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
