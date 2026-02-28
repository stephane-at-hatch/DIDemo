import ModularNavigation
import SwiftUI

public extension TabCoordinator {
    struct DestinationView: View {
        let state: DestinationState
        let client: NavigationClient<Destination>
        
        public var body: some View {
            switch state {
            case .boxOffice(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    entry: entry
                )
            case .discover(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    entry: entry
                )
            case .watchlist(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    entry: entry
                )
            }
        }
    }
}
