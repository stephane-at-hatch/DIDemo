import ModularNavigation
import MovieDomainInterface
import SwiftUI

public extension DetailScreen {
    @MainActor
    static func mockEntry(
        at publicDestination: Destination.Public = .detail(movieId: 550)
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
                            movieRepository: .fixtureData,
                            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
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

// MARK: - SwiftUI Preview

#Preview {
    let entry = DetailScreen.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()

    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
