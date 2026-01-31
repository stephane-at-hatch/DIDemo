import ModularNavigation
import SwiftUI

// MARK: - Destination Enum

/// Represents all possible destinations within the ScreenA module
public extension ScreenA {
    struct Destination: Hashable {
        public enum Public: Hashable {
            case main
        }

        public enum External: Hashable {
            case screenB
        }

        enum DestinationType: Hashable {
            case `public`(Public)
            case external(External)
        }

        var type: DestinationType

        init(_ destination: Public) {
            self.type = .public(destination)
        }

        public init(_ destination: External) {
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

public extension ScreenA {
    typealias Entry = ModuleEntry<Destination, DestinationView>
}
