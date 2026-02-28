import ModularNavigation
import DetailScreen
import SwiftUI

public extension DiscoverScreen {
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
                        let viewModel = DiscoverViewModel(
                            movieRepository: dependencies.movieRepository,
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
