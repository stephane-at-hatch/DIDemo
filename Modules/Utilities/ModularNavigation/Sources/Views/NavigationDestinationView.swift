//
//  NavigationDestinationView.swift
//
//  Created by Stephane Magne on 2025-10-31.
//  Copyright hatch.co, 2025.
//

import SwiftUI

/// Wrapper view that creates a new navigation context for presented destinations (sheets/covers).
///
/// This view bridges between a parent coordinator and a new child coordinator, enabling
/// modals to have their own independent navigation state while maintaining proper dismissal
/// behavior back to the parent context.
///
/// The view handles:
/// - Creating a child coordinator with appropriate path inheritance
/// - Setting up a new NavigationStack (if needed) for the modal content
/// - Building the destination view with the new coordinator
/// - Passing along any remaining deep link route
///
/// Used internally by `NavigationDestinationHandler` for sheet and cover presentations.
/// Can also be used directly in SwiftUI previews to simulate presentation contexts.
public struct NavigationDestinationView<PreviousDestination: Hashable, Destination: Hashable, Content: View>: View {
    /// The new coordinator managing navigation in this presentation context
    let coordinator: NavigationCoordinator<Destination>
    
    /// How this context is being presented (sheet, cover, or root)
    let mode: NavigationMode
    
    /// The destination to display in this context
    let destination: Destination
    
    /// Builder function to create views for destinations
    let builder: DestinationBuilder<Destination, Content>
    
    /// Initialize a navigation destination view from a parent coordinator.
    ///
    /// Creates a child coordinator that inherits appropriate navigation state based
    /// on the presentation mode.
    ///
    /// - Parameters:
    ///   - previousCoordinator: The parent coordinator from which this presentation originates
    ///   - mode: The presentation mode (typically .sheet or .cover)
    ///   - destination: The destination to display
    ///   - builder: Closure to build views for destinations
    init(
        previousCoordinator: NavigationCoordinator<PreviousDestination>,
        mode: NavigationMode,
        destination: Destination,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        self.coordinator = previousCoordinator.newCoordinator(mode: mode)
        self.mode = mode
        self.destination = destination
        self.builder = builder
    }

    /// Initialize a navigation destination view from a parent client.
    ///
    /// Convenience initializer that accepts a `NavigationClient` instead of a coordinator,
    /// useful when working with the public API.
    ///
    /// - Parameters:
    ///   - previousClient: The parent client from which this presentation originates
    ///   - mode: The presentation mode
    ///   - destination: The destination to display
    ///   - builder: Closure to build views for destinations
    public init(
        previousClient: NavigationClient<PreviousDestination>,
        mode: NavigationMode,
        destination: Destination,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        self.init(
            previousCoordinator: previousClient.coordinator,
            mode: mode,
            destination: destination,
            builder: builder
        )
    }

    public init(
        previousClient: NavigationClient<PreviousDestination>,
        mode: NavigationMode,
        entry: ModuleEntry<Destination, Content>
    ) {
        self.init(
            previousClient: previousClient,
            mode: mode,
            destination: entry.entryDestination,
            builder: entry.builder
        )
    }

    public var body: some View {
        NavigationRootView(
            coordinator: coordinator,
            builder: builder,
            content: {
                builder(destination, mode, coordinator.client)
            }
        )
    }
}

/// Type alias for the destination builder closure used throughout the navigation system.
///
/// This closure is responsible for creating views for navigation destinations. It receives:
/// - The destination to display
/// - The presentation mode (push, sheet, cover)
/// - The navigation client for that context
///
/// Example:
/// ```swift
/// let builder: DestinationBuilder<MyDestination, MyDestinationView> = { destination, mode, client in
///     let viewModel: MyViewModelType = switch destination {
///     case .detail:
///         .detail(
///             DetailViewModel(client: client)
///         )
///     case .settings:
///         .settings(
///             SettingsView(client: client)
///         )
///     }
///     return MyDestinationView(viewModel: viewModel)
/// }
/// ```
public typealias DestinationBuilder<Destination: Hashable, Content: View> = (Destination, NavigationMode, NavigationClient<Destination>) -> Content

// MARK: - Module Entry

@MainActor
public struct ModuleEntry<Destination: Hashable, Content: View> {
    public let entryDestination: Destination
    public let builder: DestinationBuilder<Destination, Content>

    public init(
        entryDestination: Destination,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        self.entryDestination = entryDestination
        self.builder = builder
    }
}
