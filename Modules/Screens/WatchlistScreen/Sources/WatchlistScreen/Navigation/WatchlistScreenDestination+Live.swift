import ModularNavigation
import DetailScreen
import ShareComponent
import SwiftUI

public extension WatchlistScreen {
    @MainActor
    static func liveEntry(
        configuration: EntryConfiguration<Destination>,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            configuration: configuration,
            builder: { destination, monitor, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        let shareComponentDependencies = dependencies.buildChild(ShareComponent.Dependencies.self)
                        let shareButtonBuilder = ShareComponent.Builder(dependencies: shareComponentDependencies)
                        let viewModel = WatchlistViewModel(
                            watchlistRepository: dependencies.watchlistRepository,
                            shareButtonBuilder: shareButtonBuilder,
                            imageBaseURL: dependencies.tmdbConfiguration.imageBaseURL,
                            navigationClient: navigationClient
                        )
                        state = .main(viewModel)
                    }

                case .external(let externalDestination):
                    switch externalDestination {
                    case .detail(let detailDestination):
                        let detailDependencies = dependencies.buildChild(DetailScreen.Dependencies.self)
                        let entry = DetailScreen.liveEntry(
                            configuration: monitor.entryConfig(for: .public(detailDestination)),
                            dependencies: detailDependencies
                        )
                        state = .detail(entry)
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
