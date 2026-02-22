import ModularNavigation
import DetailScreen
import SwiftUI

public extension WatchlistScreen {
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
                WatchlistRootView(
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
