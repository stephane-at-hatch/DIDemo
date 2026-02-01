import ModularNavigation
import SwiftUI

// MARK: - Destination Enum

public extension DetailScreen {
    struct Destination: Hashable {
        public enum Public: Hashable {
            case detail(movieId: Int)
        }

        enum DestinationType: Hashable {
            case `public`(Public)
        }

        var type: DestinationType

        init(_ destination: Public) {
            self.type = .public(destination)
        }

        public static func `public`(_ destination: Public) -> Self {
            self.init(destination)
        }
    }
}

// MARK: - Entry Point

public extension DetailScreen {
    typealias Entry = ModuleEntry<Destination, DestinationView>
}
