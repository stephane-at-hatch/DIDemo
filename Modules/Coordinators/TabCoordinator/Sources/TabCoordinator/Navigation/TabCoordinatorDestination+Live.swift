import BoxOfficeScreen
import DiscoverScreen
import ModularNavigation
import SwiftUI
import WatchlistScreen

extension TabCoordinator {
    @MainActor
    static func liveEntry(
        tabDestination: Destination.Tab = .boxOffice,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            configuration: DestinationMonitor(mode: .root).entryConfig(for: .tab(tabDestination)),
            builder: { destination, monitor, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .tab(let tabDestination):
                    switch tabDestination {
                    case .boxOffice:
                        let boxOfficeDependencies = dependencies.buildChild(BoxOfficeScreen.Dependencies.self)
                        let entry = BoxOfficeScreen.liveEntry(
                            configuration: monitor.entryConfig(for: .public(.main)),
                            dependencies: boxOfficeDependencies
                        )
                        state = .boxOffice(entry)
                    case .discover:
                        let discoverDependencies = dependencies.buildChild(DiscoverScreen.Dependencies.self)
                        let entry = DiscoverScreen.liveEntry(
                            configuration: monitor.entryConfig(for: .public(.main)),
                            dependencies: discoverDependencies
                        )
                        state = .discover(entry)
                    case .watchlist:
                        let watchlistDependencies = dependencies.buildChild(WatchlistScreen.Dependencies.self)
                        let entry = WatchlistScreen.liveEntry(
                            configuration: monitor.entryConfig(for: .public(.main)),
                            dependencies: watchlistDependencies
                        )
                        state = .watchlist(entry)
                    }
                }

                return DestinationView(
                    state: state,
                    client: navigationClient
                )
            }
        )
    }
}
