import ModularNavigation
import ScreenB
import SwiftUI

public extension ScreenA {

    @MainActor
    static func liveEntry(
        at publicDesination: Destination.Public,
        dependencies: Dependencies
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
                                testClient: dependencies.testClient
                            )
                        )
                    }
                case .external(let externalDestination):
                    switch externalDestination {
                    case .screenB:
                        let screenBDependencies = dependencies.buildChild(ScreenB.Dependencies.self)
                        let entry = ScreenB.liveEntry(
                            at: .main,
                            dependencies: screenBDependencies
                        )
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
