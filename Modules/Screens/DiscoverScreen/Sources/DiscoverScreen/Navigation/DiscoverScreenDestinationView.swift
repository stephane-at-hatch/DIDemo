import ModularNavigation
import DetailScreen
import SwiftUI

public extension DiscoverScreen {
    struct DestinationView: View {
        let state: DestinationState
        let client: NavigationClient<Destination>
        
        public var body: some View {
            switch state {
            case .main(let viewModel):
                DiscoverRootView(
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
