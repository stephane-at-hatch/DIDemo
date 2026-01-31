import ScreenB
import ModularNavigation
import TestClientInterface
import SwiftUI

public extension ScreenA {

    @MainActor
    static func mockEntry(
        at publicDesination: Destination.Public = .main
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDesination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState

                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        viewState = .main(
                            ScreenAViewModel(
                                navigationClient: navigationClient,
                                testClient: MockTestClient()
                            )
                        )
                    }
                case .external(let externalDestination):
                    switch externalDestination {
                    case .screenB:
                        let entry = ScreenB.mockEntry()
                        viewState = .screenB(entry)
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

// MARK: - SwiftUI Preview

#Preview {
    let entry = ScreenA.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()

    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
