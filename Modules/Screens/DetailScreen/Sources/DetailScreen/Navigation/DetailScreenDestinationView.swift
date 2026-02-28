import ModularNavigation
import SwiftUI

public extension DetailScreen {
    struct DestinationView: View {
        let state: DestinationState
        let client: NavigationClient<Destination>

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
