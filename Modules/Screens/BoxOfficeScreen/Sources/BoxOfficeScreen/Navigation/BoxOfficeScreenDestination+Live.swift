import ModularNavigation
import DetailScreen
import SwiftUI

public extension BoxOfficeScreen {
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
                    case .main:
                        let viewModel = BoxOfficeViewModel(
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
                            publicDestination: detailDestination,
                            dependencies: detailDependencies
                        )
                        state = .detail(entry)
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
