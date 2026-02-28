import ModularNavigation
import MovieDomainInterface
import WatchlistDomainInterface
import SwiftUI

public extension DetailScreen {
    @MainActor
    static func mockEntry(
        publicDestination: Destination.Public = .detail(movieId: 550)
    ) -> Entry {
        Entry(
            configuration: DestinationMonitor(mode: .cover).entryConfig(for: .public(publicDestination)),
            builder: { destination, mode, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .detail(let movieId):
                        let viewModel = DetailViewModel(
                            movieId: movieId,
                            movieRepository: .fixtureData,
                            watchlistRepository: .fixtureData,
                            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
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

// MARK: - SwiftUI Preview

#Preview {
    let entry = DetailScreen.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()

    NavigationDestinationView(
        previousClient: rootClient,
        entry: entry
    )
}
