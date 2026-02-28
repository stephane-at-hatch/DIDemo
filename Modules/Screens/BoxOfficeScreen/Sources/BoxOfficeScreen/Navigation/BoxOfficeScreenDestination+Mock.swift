import ModularNavigation
import MovieDomainInterface
import DetailScreen
// import ShareComponent
import SwiftUI

public extension BoxOfficeScreen {
    @MainActor
    static func mockEntry(
        publicDestination: Destination.Public = .main
    ) -> Entry {
        Entry(
            configuration: DestinationMonitor(mode: .cover).entryConfig(for: .public(publicDestination)),
            builder: { destination, mode, navigationClient in
                let state: DestinationState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        let viewModel = BoxOfficeViewModel(
                            movieRepository: .fixtureData,
                            // shareButtonBuilder: .mock(),
                            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
                            navigationClient: navigationClient
                        )
                        state = .main(viewModel)
                    }

                case .external(let externalDestination):
                    switch externalDestination {
                    case .detail(let detailDestination):
                        let entry = DetailScreen.mockEntry(publicDestination: detailDestination)
                        state = .detail(entry)
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
    let entry = BoxOfficeScreen.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()

    NavigationDestinationView(
        previousClient: rootClient,
        entry: entry
    )
}
