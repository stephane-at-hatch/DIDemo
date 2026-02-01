import ModularNavigation
import MovieDomainInterface
import SwiftUI

public extension BoxOfficeScreen {
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
                        let viewModel = BoxOfficeViewModel(
                            movieRepository: .fixtureData,
                            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
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

// MARK: - SwiftUI Preview

#Preview {
    let entry = BoxOfficeScreen.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
