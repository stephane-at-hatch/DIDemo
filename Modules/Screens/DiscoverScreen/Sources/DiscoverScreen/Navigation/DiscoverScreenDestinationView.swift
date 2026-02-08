import ModularNavigation
import DetailScreen
import SwiftUI

public extension DiscoverScreen {
    struct DestinationView: View {
        let viewState: DestinationViewState
        let mode: NavigationMode
        let client: NavigationClient<Destination>

        init(
            viewState: DestinationViewState,
            mode: NavigationMode,
            client: NavigationClient<Destination>
        ) {
            self.viewState = viewState
            self.mode = mode
            self.client = client
        }

        public var body: some View {
            switch viewState {
            case .main(let viewModel):
                mainView(viewModel)
            case .detail(let entry):
                detailView(entry)
            }
        }

        // MARK: - Destination Views

        func mainView(_ viewModel: DiscoverViewModel) -> some View {
            DiscoverRootView(
                viewModel: viewModel,
                onMovieSelected: { movieId in
                    client.push(.external(.detail(movieId: movieId)))
                }
            )
        }

        func detailView(_ entry: DetailScreen.Entry) -> some View {
            NavigationDestinationView(
                previousClient: client,
                mode: mode,
                entry: entry
            )
        }
    }
}
