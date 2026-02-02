import ModularNavigation
import DetailScreen
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
            case .detail(let model):
                detailView(model)
            }
        }

        // MARK: - Destination Views

        func mainView(_ viewModel: BoxOfficeViewModel) -> some View {
            BoxOfficeRootView(
                viewModel: viewModel
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
