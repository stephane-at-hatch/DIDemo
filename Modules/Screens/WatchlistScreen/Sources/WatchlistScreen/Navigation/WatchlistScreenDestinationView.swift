import ModularNavigation
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
            case .main:
                Text("main View")
            }
        }
    }
}
