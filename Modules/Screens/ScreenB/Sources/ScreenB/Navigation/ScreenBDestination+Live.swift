import ModularNavigation
import SwiftUI

public extension ScreenB {
    @MainActor
    public static func liveEntry(
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
                        let viewModel = ScreenBViewModel(testClient: dependencies.testClient)
                        viewState = .main(viewModel)
                    }
                case .internal(let internalDestination):
                    switch internalDestination {
                    case .testPage:
                        viewState = .testPage
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
