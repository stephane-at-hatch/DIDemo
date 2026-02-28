import ModularNavigation
import DetailScreen
import SwiftUI

public extension WatchlistScreen {
    struct DestinationView: View {
        let state: DestinationState
        let client: NavigationClient<Destination>
        
        public var body: some View {
            switch state {
            case .main(let viewModel):
                WatchlistRootView(
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
