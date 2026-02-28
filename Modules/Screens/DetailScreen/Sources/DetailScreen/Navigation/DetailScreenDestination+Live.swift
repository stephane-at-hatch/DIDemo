import ModularNavigation
import SwiftUI

public extension DetailScreen {
    @MainActor
    static func liveEntry(
        configuration: EntryConfiguration<Destination>,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            configuration: configuration,
            builder: { destination, mode, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .detail(let movieId):
                        let viewModel = DetailViewModel(
                            movieId: movieId,
                            movieRepository: dependencies.movieRepository,
                            watchlistRepository: dependencies.watchlistRepository,
                            imageBaseURL: dependencies.tmdbConfiguration.imageBaseURL
                        )
                        state = .detail(viewModel)
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
