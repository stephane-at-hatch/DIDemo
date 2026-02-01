import ModularNavigation
import SwiftUI

public extension BoxOfficeScreen {
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
            }
        }
        
        // MARK: - Destination Views
        
        func mainView(_ viewModel: BoxOfficeViewModel) -> some View {
            BoxOfficeRootView(
                viewModel: viewModel,
                onMovieSelected: { movieId in
                    // TODO: Navigate to detail screen
                    // client.push(.external(.detail(movieId: movieId)))
                }
            )
        }
    }
}
