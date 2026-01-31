import SwiftUI
@testable import TabCoordinator

extension TabCoordinator {
    struct MockDestinationView: View {
        let destination: Destination
        
        var body: some View {
            switch destination.type {
            case .public(let publicDestination):
                switch publicDestination {
                case .tab:
                    Color.blue.overlay(Text("tab"))
                }
            case .external(let externalDestination):
                switch externalDestination {
                case .firstTab:
                    Color.green.overlay(Text("firstTab"))
                case .secondTab:
                    Color.red.overlay(Text("secondTab"))
                case .thirdTab:
                    Color.orange.overlay(Text("thirdTab"))
                }
            }
        }
    }
}

extension TabCoordinator {
    @MainActor
    static func testBuilder() -> DestinationBuilder<MockDestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            MockDestinationView(destination: destination)
        }
    }
}
