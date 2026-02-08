import ModularNavigation
import DetailScreen
import SwiftUI

// MARK: - Destination Enum

public extension DiscoverScreen {
    struct Destination: Hashable {
        public enum Public: Hashable {
            case main
        }

        public enum External: Hashable {
            case detail(DetailScreen.Destination.Public)
        }

        enum DestinationType: Hashable {
            case `public`(Public)
            case external(External)
        }

        var type: DestinationType

        init(_ destination: Public) {
            self.type = .public(destination)
        }

        init(_ destination: External) {
            self.type = .external(destination)
        }

        public static func `public`(_ destination: Public) -> Self {
            self.init(destination)
        }

        public static func external(_ destination: External) -> Self {
            self.init(destination)
        }
    }
}

// MARK: - Entry Point

public extension DiscoverScreen {
    typealias Entry = ModuleEntry<Destination, DestinationView>
}
