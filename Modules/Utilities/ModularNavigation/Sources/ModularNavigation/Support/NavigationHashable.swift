//
//  NavigationHashable.swift
//
//  Created by Stephane Magne
//

import Foundation

/// Wrapper that makes any type Hashable by identity rather than value.
///
/// Sometimes you need to pass non-Hashable types through navigation (like closures or view models).
/// `NavigationHashable` wraps these values and provides Hashable conformance based on a unique ID,
/// allowing them to be used as navigation destinations.
///
/// Example:
/// ```swift
/// enum MyDestination: Hashable {
///     case detail(viewModel: NavigationHashable<DetailViewModel>)
/// }
/// ```
///
/// Each instance is considered unique even if wrapping identical values.
public final class NavigationHashable<T>: Hashable {
    /// Unique identifier for this instance
    let uuid = UUID()
    
    /// The wrapped value
    public let value: T
    
    /// Create a new hashable wrapper for a value
    public init(_ value: T) {
        self.value = value
    }
    
    /// Instances are equal only if they have the same UUID (identity-based)
    public static func == (lhs: NavigationHashable<T>, rhs: NavigationHashable<T>) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    /// Hash based on UUID, not the wrapped value
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
