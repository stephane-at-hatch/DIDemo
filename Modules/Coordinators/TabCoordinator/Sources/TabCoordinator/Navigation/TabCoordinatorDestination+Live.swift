import BoxOfficeScreen
import ModularNavigation
import SwiftUI

extension TabCoordinator {
    @MainActor
    static func liveEntry(
        tabDestination: Destination.Tab = .boxOffice,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            entryDestination: .tab(tabDestination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState

                switch destination.type {
                case .tab(let tabDestination):
                    switch tabDestination {
                    case .boxOffice:
                        let boxOfficeDependencies = dependencies.buildChild(BoxOfficeScreen.Dependencies.self)
                        let entry = BoxOfficeScreen.liveEntry(
                            at: .main,
                            dependencies: boxOfficeDependencies
                        )
                        viewState = .boxOffice(entry)
                    case .discover:
                        fatalError()
                    case .watchlist:
                        fatalError()
                    }
                }

                return DestinationView(
                    viewState: viewState,
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
