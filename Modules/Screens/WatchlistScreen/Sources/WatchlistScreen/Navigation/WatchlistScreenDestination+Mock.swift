import DetailScreen
import ModularNavigation
import SwiftUI
import WatchlistDomainInterface

public extension WatchlistScreen {
    @MainActor
    static func mockEntry(
        publicDestination: Destination.Public = .main
    ) -> Entry {
        Entry(
            configuration: DestinationMonitor(mode: .cover).entryConfig(for: .public(publicDestination)),
            builder: { destination, mode, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        let viewModel = WatchlistViewModel(
                            watchlistRepository: .mock(),
                            imageBaseURL: URL(filePath: "/test"),
                            navigationClient: navigationClient
                        )
                        state = .main(viewModel)
                    }

                case .external(let externalDestination):
                    switch externalDestination {
                    case .detail(let detailDestination):
                        state = .detail(
                            DetailScreen.mockEntry(
                                publicDestination: detailDestination
                            )
                        )
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
    let entry = WatchlistScreen.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        entry: entry
    )
}
