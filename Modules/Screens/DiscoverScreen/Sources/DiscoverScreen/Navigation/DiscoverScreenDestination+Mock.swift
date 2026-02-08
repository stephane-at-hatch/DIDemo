import ModularNavigation
import MovieDomainInterface
import DetailScreen
import SwiftUI

public extension DiscoverScreen {
    @MainActor
    static func mockEntry(
        at publicDestination: Destination.Public = .main
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        let viewModel = DiscoverViewModel(
                            movieRepository: .fixtureData,
                            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
                        )
                        viewState = .main(viewModel)
                    }

                case .external(let externalDestination):
                    switch externalDestination {
                    case .detail(let movieId):
                        let entry = DetailScreen.mockEntry(at: .detail(movieId: movieId))
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

// MARK: - SwiftUI Preview

#Preview {
    let entry = DiscoverScreen.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()

    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
