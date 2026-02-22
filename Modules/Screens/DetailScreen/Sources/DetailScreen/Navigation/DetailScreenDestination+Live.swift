import ModularNavigation
import SwiftUI

public extension DetailScreen {
    @MainActor
    static func liveEntry(
        publicDestination: Destination.Public,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDestination),
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
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
