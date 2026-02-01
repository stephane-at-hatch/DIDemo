import SwiftUI
@testable import BoxOfficeScreen

extension BoxOfficeScreen {
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

extension BoxOfficeScreen {
    @MainActor
    static func testEntry(
        at publicDestination: Destination.Public = .main
    ) -> ModuleEntry<Destination, MockDestinationView> {
        ModuleEntry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                MockDestinationView(destination: destination)
            }
        )
    }
}
