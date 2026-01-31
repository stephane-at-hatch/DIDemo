import SwiftUI
@testable import ScreenB

extension ScreenB {
    struct MockDestinationView: View {
        let destination: Destination
        
        var body: some View {
            switch destination.type {
            case .public(let publicDestination):
                switch publicDestination {
                case .main:
                    Color.blue.overlay(Text("main"))
                }
            case .internal(let internalDestination):
                switch internalDestination {
                case .testPage:
                    Color.green.overlay(Text("testPage"))
                }
            }
        }
    }
}

extension ScreenB {
    @MainActor
    static func testBuilder() -> DestinationBuilder<MockDestinationView> {
        DestinationBuilder { destination, mode, navigationClient in
            MockDestinationView(destination: destination)
        }
    }
}
