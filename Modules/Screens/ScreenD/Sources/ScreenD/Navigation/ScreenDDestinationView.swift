import ModularNavigation
import SwiftUI

public extension ScreenD {
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
            case .main(let viewModel):
                ScreenDRootView(viewModel: viewModel)
            }
        }
    }
}
