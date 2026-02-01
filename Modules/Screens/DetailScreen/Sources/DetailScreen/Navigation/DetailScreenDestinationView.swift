import ModularNavigation
import SwiftUI

public extension DetailScreen {
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
            case .detail(let viewModel):
                detailView(viewModel)
            }
        }

        // MARK: - Destination Views

        func detailView(_ viewModel: DetailViewModel) -> some View {
            DetailRootView(
                viewModel: viewModel,
                onBack: {
                    client.dismiss()
                }
            )
        }
    }
}
