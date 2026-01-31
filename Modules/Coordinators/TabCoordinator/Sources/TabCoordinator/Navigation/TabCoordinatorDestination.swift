import ModularNavigation
import SwiftUI

// MARK: - Destination Enum

public extension TabCoordinator {
    struct Destination: Hashable {
        enum Tab: Hashable {
            case first
            case second
            case third
        }

        enum DestinationType: Hashable {
            case tab(Tab)
        }

        var type: DestinationType

        init(_ destination: Tab) {
            self.type = .tab(destination)
        }
        
        static func tab(_ destination: Tab) -> Self {
            self.init(destination)
        }
        
    }
}

// MARK: - Destination Builder

public extension TabCoordinator {
    typealias Builder = DestinationBuilder<Destination, DestinationView>
}
