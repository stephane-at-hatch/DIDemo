import SwiftUI
@testable import ScreenD

extension ScreenD {
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

extension ScreenD {
    @MainActor
    static func testBuilder() -> DestinationBuilder<MockDestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            MockDestinationView(destination: destination)
        }
    }
}
