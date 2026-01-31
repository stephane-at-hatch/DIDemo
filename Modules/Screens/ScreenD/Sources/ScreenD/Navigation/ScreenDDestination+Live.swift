import ModularNavigation
import SwiftUI

public extension ScreenD {
    @MainActor
    static func liveEntry(
        at publicDestination: Destination.Public,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        let viewModel = ScreenDViewModel()
                        viewState = .main(viewModel)
                    }
                }

                return DestinationView(
                    viewState: viewState,
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
