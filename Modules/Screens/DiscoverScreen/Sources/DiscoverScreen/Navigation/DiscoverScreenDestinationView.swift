import ModularNavigation
import DetailScreen
import SwiftUI

public extension DiscoverScreen {
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
            case .main(let viewModel):
                DiscoverRootView(
                    viewModel: viewModel
                )
            case .detail(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    mode: mode,
                    entry: entry
                )
            }
        }
    }
}
