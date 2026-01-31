import ModularNavigation
import SwiftUI

public extension TabCoordinator {
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
            case .firstTab(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    mode: mode,
                    entry: entry
                )
            case .secondTab(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    mode: mode,
                    entry: entry
                )
            case .thirdTab(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    mode: mode,
                    entry: entry
                )
            }
        }
    }
}
