//
//  NavigationClient.swift
//  HatchModularNavigation
//
//  Created by Stephane Magne on 2025-10-28.
//  Copyright hatch.co, 2025.
//

import SwiftUI

/// Closure-based navigation interface for dependency injection into ViewModels.
///
/// `NavigationClient` provides a clean, testable API for navigation operations by wrapping
/// a `NavigationCoordinator` in simple closure-based methods. Use this type for dependency
/// injection rather than passing coordinators directly.
///
/// The client automatically handles the translation between high-level navigation requests
/// (push, sheet, cover) and the underlying coordinator state management.
@MainActor
public struct NavigationClient<Destination: Hashable> {
    /// Navigate to a destination using the specified presentation mode.
    /// - Parameters:
    ///   - destination: The destination to navigate to
    ///   - mode: How the destination should be presented (push, sheet, or cover)
    public let present: (Destination, NavigationMode) -> Void
    
    /// Intelligently dismiss the topmost presentation.
    /// Priority order: sheet/cover → navigation stack pop → parent context dismissal
    public let dismiss: () -> Void
    
    /// Pop all destinations from the navigation stack, returning to the root.
    public let popToRoot: () -> Void
    
    /// Close the entire presentation context.
    /// For modals: dismisses the sheet/cover. For navigation stacks: pops to root.
    public let close: () -> Void
    
    /// Internal coordinator reference for creating child coordinators in new contexts
    let coordinator: NavigationCoordinator<Destination>
    
    /// Create a navigation client with custom closures for testing.
    /// For production use, create clients via `NavigationCoordinator.client` instead.
    init(
        present: @escaping (Destination, NavigationMode) -> Void,
        dismiss: @escaping () -> Void,
        popToRoot: @escaping () -> Void,
        close: @escaping () -> Void
    ) {
        self.present = present
        self.dismiss = dismiss
        self.popToRoot = popToRoot
        self.close = close
        self.coordinator = .mockCoordinator()
    }
    
    /// Create a client from a coordinator.
    /// This initializer wires up the closure-based API to the coordinator's methods,
    /// automatically mapping presentation modes to the appropriate coordinator calls.
    init(
        coordinator: NavigationCoordinator<Destination>
    ) {
        self.present = { destination, mode in
            coordinator.present(destination, mode: mode)
        }
        self.dismiss = {
            coordinator.dismiss()
        }
        self.popToRoot = {
            coordinator.popToRoot()
        }
        self.close = {
            coordinator.close()
        }
        self.coordinator = coordinator
    }
}

// MARK: - Convenience Extensions

extension NavigationClient {
    /// Navigate by pushing onto the navigation stack
    public func push(_ destination: Destination) {
        present(destination, .push)
    }
    
    /// Present as a sheet
    public func presentSheet(_ destination: Destination, detents: Set<PresentationDetent>? = nil) {
        present(destination, .sheet(detents: detents))
    }
    
    /// Present as a full screen cover
    public func presentFullScreenCover(_ destination: Destination) {
        present(destination, .cover)
    }
}
