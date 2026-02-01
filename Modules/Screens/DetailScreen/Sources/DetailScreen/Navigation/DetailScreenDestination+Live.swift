import ModularNavigation
import SwiftUI

public extension DetailScreen {
    @MainActor
    static func liveEntry(
        at publicDestination: Destination.Public,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .detail(let movieId):
                        let viewModel = DetailViewModel(
                            movieId: movieId,
                            movieRepository: dependencies.movieRepository,
                            imageBaseURL: dependencies.tmdbConfiguration.imageBaseURL
                        )
                        viewState = .detail(viewModel)
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
