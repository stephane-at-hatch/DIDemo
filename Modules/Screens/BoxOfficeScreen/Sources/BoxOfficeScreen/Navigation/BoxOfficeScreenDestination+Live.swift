import ModularNavigation
import DetailScreen
import SwiftUI

public extension BoxOfficeScreen {
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
                    case .main:
                        let viewModel = BoxOfficeViewModel(
                            movieRepository: dependencies.movieRepository,
                            imageBaseURL: dependencies.tmdbConfiguration.imageBaseURL,
                            navigationClient: navigationClient
                        )
                        viewState = .main(viewModel)
                    }

                case .external(let externalDestination):
                    switch externalDestination {
                    case .detail(let movieId):
                        let detailDependencies = dependencies.buildChild(DetailScreen.Dependencies.self)
                        let entry = DetailScreen.liveEntry(
                            at: .detail(movieId: movieId),
                            dependencies: detailDependencies
                        )
                        viewState = .detail(entry)
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
