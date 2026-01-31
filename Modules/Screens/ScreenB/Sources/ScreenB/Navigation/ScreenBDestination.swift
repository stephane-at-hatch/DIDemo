import ModularNavigation
import SwiftUI

// MARK: - Destination Enum

public extension ScreenB {
    struct Destination: Hashable {
        public enum Public: Hashable {
            case main
        }

        enum Internal: Hashable {
            case testPage
        }

        enum DestinationType: Hashable {
            case `public`(Public)
            case `internal`(Internal)
        }

        var type: DestinationType

        init(_ destination: Public) {
            self.type = .public(destination)
        }
        
        init(_ destination: Internal) {
            self.type = .internal(destination)
        }
        
        public static func `public`(_ destination: Public) -> Self {
            self.init(destination)
        }
        
        static func `internal`(_ destination: Internal) -> Self {
            self.init(destination)
        }
    }
}

// MARK: - Entry Point

public extension ScreenB {
    typealias Entry = ModuleEntry<Destination, DestinationView>
}
