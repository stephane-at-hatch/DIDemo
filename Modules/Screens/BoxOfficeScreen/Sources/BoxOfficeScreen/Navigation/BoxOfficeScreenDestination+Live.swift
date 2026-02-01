import ModularNavigation
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
                            imageBaseURL: dependencies.tMDBConfiguration.imageBaseURL
                        )
                        viewState = .main(viewModel)
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
