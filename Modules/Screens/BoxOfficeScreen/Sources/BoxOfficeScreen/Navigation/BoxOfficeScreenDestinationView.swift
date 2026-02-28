import ModularNavigation
import DetailScreen
import SwiftUI

public extension BoxOfficeScreen {
    struct DestinationView: View {
        let state: DestinationState
        let client: NavigationClient<Destination>

        public var body: some View {
            switch state {
            case .main(let viewModel):
                BoxOfficeRootView(
                    viewModel: viewModel
                )
            case .detail(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    entry: entry
                )
            }
        }
    }
}
