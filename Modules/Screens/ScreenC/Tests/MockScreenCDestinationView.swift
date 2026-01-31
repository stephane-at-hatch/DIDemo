import SwiftUI
@testable import ScreenC

extension ScreenC {
    struct MockDestinationView: View {
        let destination: Destination
        
        var body: some View {
            switch destination.type {
            case .public(let publicDestination):
                switch publicDestination {
                case .main:
                    Color.blue.overlay(Text("main"))
                }
            }
        }
    }
}

extension ScreenC {
    @MainActor
    static func testBuilder() -> DestinationBuilder<MockDestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            MockDestinationView(destination: destination)
        }
    }
}
