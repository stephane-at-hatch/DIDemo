import ModularNavigation
import SwiftUI

public extension DetailScreen {
    struct DestinationView: View {
        let state: DestinationState
        let mode: NavigationMode
        let client: NavigationClient<Destination>

        init(
            state: DestinationState,
            mode: NavigationMode,
            client: NavigationClient<Destination>
        ) {
            self.state = state
            self.mode = mode
            self.client = client
        }

        public var body: some View {
            switch state {
            case .detail(let viewModel):
                DetailRootView(
                    viewModel: viewModel,
                    onBack: {
                        client.dismiss()
                    }
                )
            }
        }
    }
}
