//
//  AnyNavigationCoordinator.swift
//  ModularNavigation
//
//  Created by Stephane Magne
//

import SwiftUI

// MARK: - AnyNavigationCoordinator

/// Type-erased wrapper for NavigationCoordinator, enabling storage in SwiftUI environment.
///
/// SwiftUI's environment requires types to be homogeneous, but we need to pass coordinators
/// of different destination types through the view hierarchy. `AnyNavigationCoordinator`
/// erases the destination type while preserving the ability to cast back when needed.
///
/// This is used internally to inject coordinators into the environment for access by child views.
@MainActor
public final class AnyNavigationCoordinator: Hashable {
    /// Unique identifier matching the wrapped coordinator
    private let uuid: UUID
    
    /// The type-erased coordinator
    let hiddenValue: AnyHashable
    
    /// Create a type-erased coordinator wrapper.
    /// The UUID is preserved for identity-based comparison.
    /// swiftformat:disable:next opaqueGenericParameters
    init<T>(coordinator: NavigationCoordinator<T>) {
        self.uuid = coordinator.uuid
        self.hiddenValue = coordinator
    }
    
    /// Attempt to cast back to a typed coordinator client.
    ///
    /// Returns the coordinator's client if the destination type matches, nil otherwise.
    ///
    /// Example:
    /// ```swift
    /// @Environment(\.navigationCoordinator) var anyCoordinator
    ///
    /// if let client = anyCoordinator?.value(type: MyDestination.self) {
    ///     client.push(.detail)
    /// }
    /// ```
    public func value<T>(type: T.Type) -> NavigationClient<T>? {
        (hiddenValue as? NavigationCoordinator<T>)?.client
    }
    
    /// Identity-based equality using UUID
    public nonisolated static func == (lhs: AnyNavigationCoordinator, rhs: AnyNavigationCoordinator) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    /// Hash based on UUID
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

// MARK: - Environment Key

/// Environment key for accessing the current navigation coordinator.
private struct NavigationCoordinatorKey<Route: Hashable>: EnvironmentKey {
    static var defaultValue: AnyNavigationCoordinator? { nil }
}

extension EnvironmentValues {
    /// Access the current navigation coordinator from the environment.
    ///
    /// The coordinator is automatically injected by `NavigationDestinationHandler` and is
    /// available to all child views. Use `value(type:)` to cast to your destination type:
    ///
    /// ```swift
    /// @Environment(\.navigationCoordinator) var coordinator
    ///
    /// var body: some View {
    ///     Button("Navigate") {
    ///         coordinator?.value(type: MyDestination.self)?.push(.detail)
    ///     }
    /// }
    /// ```
    public var navigationCoordinator: AnyNavigationCoordinator? {
        get { self[NavigationCoordinatorKey<AnyHashable>.self] }
        set { self[NavigationCoordinatorKey<AnyHashable>.self] = newValue }
    }
}
