//
//  NavigationTypes.swift
//  ModularNavigation
//
//  Created by Stephane Magne
//

import SwiftUI

// MARK: - Navigation Mode

/// Defines how a destination should be presented in the navigation hierarchy.
///
/// Navigation modes determine both the visual presentation and the navigation state management:
/// - `.root`: Initial view of a context (not used for dynamic navigation)
/// - `.push`: Adds to NavigationStack, preserving back navigation
/// - `.sheet`: Modal presentation with dismissal gesture and configurable detents
/// - `.cover`: Full-screen modal without dismissal gesture
public enum NavigationMode: Equatable {
    /// Root of a navigation context (tab root or initial view)
    case root
    /// Pushed onto the navigation stack
    case push
    /// Presented as a modal sheet with configurable detents
    case sheet(detents: Set<PresentationDetent>)
    /// Presented as a full screen cover
    case cover
}

extension NavigationMode {
    public static var sheet: NavigationMode {
        .sheet(detents: [.large])
    }
    
    public static var halfSheet: NavigationMode {
        .sheet(detents: [.medium])
    }
}

// MARK: - Navigation Step

/// Represents a single navigation action with a destination and presentation mode.
///
/// Navigation steps are the building blocks of programmatic navigation and deep linking.
/// Each step describes both *where* to go (destination) and *how* to get there (mode).
///
/// Example:
/// ```swift
/// let step = NavigationStep(destination: .profile, mode: .push)
/// ```
public struct NavigationStep<Destination> {
    /// The destination to navigate to
    public let destination: Destination
    /// How the destination should be presented
    public let mode: NavigationMode
    
    public init(destination: Destination, mode: NavigationMode) {
        self.destination = destination
        self.mode = mode
    }
}

extension NavigationStep {
    /// Convenience factory method for creating navigation steps with clearer syntax.
    ///
    /// Example:
    /// ```swift
    /// .destination(.settings, as: .push)
    /// .destination(.profile, as: .sheet)
    /// ```
    public static func destination(_ destination: Destination, as mode: NavigationMode) -> Self {
        NavigationStep(destination: destination, mode: mode)
    }
}

// MARK: - Type-Erased Wrappers

/// Type-erased container for navigation steps, enabling heterogeneous route storage.
///
/// Deep links often span multiple navigation contexts with different destination types
/// (e.g., tab selection → Screen navigation → detail screen). `AnySteps` erases the
/// destination type so these diverse steps can be stored together in a single route.
///
/// The underlying steps can be recovered when needed by attempting to cast back to
/// the specific destination type using `isConsumable(by:)`.
public struct AnySteps {
    /// The underlying array of navigation steps (type-erased as Any)
    public let steps: [Any]
    
    // swiftformat:disable:next opaqueGenericParameters
    public init<A>(_ steps: [A]) {
        self.steps = steps
    }
}

/// A route composed of multiple step segments across different destination types.
///
/// Each element represents a segment of the route that can be consumed by a specific
/// coordinator when the destination type matches.
///
/// Example deep link route:
/// ```swift
/// let route: AnyRoute = [
///     [.destination(.home, as: .root)].anySteps(),           // Tab selection
///     [.destination(.library, as: .push)].anySteps(),         // Screen navigation
///     [.destination(.soundDetail(id: "123"), as: .push)].anySteps() // Detail screen
/// ]
/// ```
///
/// As coordinators are created, they consume their segment and pass the remainder
/// to child coordinators.
public typealias AnyRoute = [AnySteps]

// MARK: - Convenience Extensions

extension Array {
    /// Convert a typed array of navigation steps into type-erased AnySteps.
    ///
    /// Example:
    /// ```swift
    /// let steps: [NavigationStep<SomeDestination>] = [
    ///     NavigationStep(destination: .library, mode: .push),
    ///     NavigationStep(destination: .favorites, mode: .push)
    /// ]
    /// let anySteps = steps.anySteps()
    /// ```
    public func anySteps<A>() -> AnySteps where Element == NavigationStep<A> {
        AnySteps(self)
    }
}

// swiftformat:disable:next genericExtensions
extension Array where Element == AnySteps {
    /// Check if the first element of the route can be consumed by a specific destination type.
    ///
    /// Used by coordinators to determine if they can process the next segment of a deep link route.
    func isConsumable<Destination>(by type: Destination.Type) -> Bool {
        first?.steps as? [NavigationStep<Destination>] != nil
    }
}

extension AnySteps {
    /// Factory method to create type-erased steps for a specific destination type.
    ///
    /// Provides clearer syntax for route construction:
    /// ```swift
    /// let route: AnyRoute = [
    ///     .steps(for: HomeDestination.self, order: [
    ///         .destination(.tab1, as: .root)
    ///     ]),
    ///     .steps(for: LibraryDestination.self, order: [
    ///         .destination(.sounds, as: .push)
    ///     ])
    /// ]
    /// ```
    public static func steps<Destination>(for destinationType: Destination.Type, order: [NavigationStep<Destination>]) -> AnySteps {
        AnySteps(order)
    }
}
