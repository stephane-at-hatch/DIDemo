import BoxOfficeScreen
import DiscoverScreen
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
                let state: DestinationState

                switch destination.type {
                case .tab(let tabDestination):
                    switch tabDestination {
                    case .boxOffice:
                        let boxOfficeDependencies = dependencies.buildChild(BoxOfficeScreen.Dependencies.self)
                        let entry = BoxOfficeScreen.liveEntry(
                            publicDestination: .main,
                            dependencies: boxOfficeDependencies
                        )
                        state = .boxOffice(entry)
                    case .discover:
                        let discoverDependencies = dependencies.buildChild(DiscoverScreen.Dependencies.self)
                        let entry = DiscoverScreen.liveEntry(
                            publicDestination: .main,
                            dependencies: discoverDependencies
                        )
                        state = .discover(entry)
                    case .watchlist:
                        fatalError()
                    }
                }

                return DestinationView(
                    state: state,
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
