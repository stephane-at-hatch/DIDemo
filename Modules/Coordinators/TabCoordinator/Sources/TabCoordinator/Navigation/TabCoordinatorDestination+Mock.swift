import ModularNavigation
import SwiftUI

extension TabCoordinator {
    @MainActor
    static func mockEntry(
        tabDestination: Destination.Tab = .boxOffice
    ) -> Entry {
        Entry(
            configuration: DestinationMonitor(mode: .root).entryConfig(for: .tab(tabDestination)),
            builder: { destination, mode, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .tab(let tabDestination):
                    switch tabDestination {
                    case .boxOffice:
                        fatalError()
                    case .discover:
                        fatalError()
                    case .watchlist:
                        fatalError()
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

// MARK: - SwiftUI Preview

#Preview {
    let entry = TabCoordinator.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        entry: entry
    )
}
