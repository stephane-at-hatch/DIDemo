import SwiftUI
@testable import ScreenA

struct MockScreenADestinationView: View {
    let destination: ScreenADestination

    var body: some View {
        switch destination.type {
        case .public(let publicDestination):
            switch publicDestination {
            case .main:
                Color.blue
                    .overlay(Text("main"))
            }
        }
    }
}

extension ScreenADestination {

    @MainActor
    public static func testBuilder() -> ScreenADestinationBuilder<MockScreenADestinationView> {
        ScreenADestinationBuilder { destination, mode, navigationClient in
            return MockScreenADestinationView(destination: destination)
        }
    }
}
