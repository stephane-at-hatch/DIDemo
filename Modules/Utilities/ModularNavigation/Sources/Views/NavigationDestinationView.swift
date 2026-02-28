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
    
    /// Monitors how this context is being presented (sheet, cover, or root), and if it's crossing modules
    let monitor: DestinationMonitor
    
    /// The destination to display in this context
    let destination: Destination
    
    /// Builder function to create views for destinations
    let builder: DestinationBuilder<Destination, Content>

    /// Builder function to create views for destinations
    let content: Content

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
        monitor: DestinationMonitor,
        destination: Destination,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        self.coordinator = previousCoordinator.newCoordinator(monitor: monitor)
        self.monitor = monitor
        self.destination = destination
        self.builder = builder
        self.content = builder(destination, monitor, coordinator.client)
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
        monitor: DestinationMonitor,
        destination: Destination,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        self.init(
            previousCoordinator: previousClient.coordinator,
            monitor: monitor,
            destination: destination,
            builder: builder
        )
    }

    public init(
        previousClient: NavigationClient<PreviousDestination>,
        entry: ModuleEntry<Destination, Content>
    ) {
        self.init(
            previousClient: previousClient,
            monitor: entry.configuration.monitor,
            destination: entry.configuration.destination,
            builder: entry.builder
        )
    }

    public var body: some View {
        NavigationRootView(
            coordinator: coordinator,
            monitor: monitor,
            builder: builder,
            content: content
        )
    }
}

// MARK: - Module Entry

/// Entry point for a module's navigation destination.
///
/// `ModuleEntry` pairs a destination's configuration with its view builder,
/// providing the navigation system with everything needed to present a destination.
/// When created, it signals to the entry monitor that navigation is transitioning
/// to an external module, which allows the system to suppress redundant navigation
/// within the same module.
///
/// Example:
/// ```swift
/// let entry = ModuleEntry(
///     configuration: monitor.entryConfig(for: .detail(id: "123")),
///     builder: DetailFeature.destinationBuilder
/// )
/// ```
@MainActor
public struct ModuleEntry<Destination: Hashable, Content: View> {
    public let configuration: EntryConfiguration<Destination>
    public let builder: DestinationBuilder<Destination, Content>
    
    public init(
        configuration: EntryConfiguration<Destination>,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        configuration.monitor.entryMonitor.isNavigatingToExternal = true
        self.configuration = configuration
        self.builder = builder
    }
}

/// Type alias for the destination builder closure used throughout the navigation system.
///
/// This closure is responsible for creating views for navigation destinations. It receives:
/// - The destination to display
/// - The destination monitor (wraps mode and helps identify crossing module boundaries)
/// - The navigation client for that context
///
/// Example:
/// ```swift
/// let builder: DestinationBuilder<MyDestination, MyDestinationView> = { destination, monitor, client in
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
public typealias DestinationBuilder<Destination: Hashable, Content: View> = (Destination, DestinationMonitor, NavigationClient<Destination>) -> Content

/// Configuration for a navigation entry, binding a destination to its entry monitor.
///
/// Created by `DestinationMonitor.entryConfig(for:)` and passed to `ModuleEntry`
/// to associate a specific destination with the monitor tracking navigation state
/// for that context.
public final class EntryConfiguration<Destination: Hashable> {
    public let destination: Destination
    public let monitor: DestinationMonitor
    
    public init(
        destination: Destination,
        monitor: DestinationMonitor
    ) {
        self.destination = destination
        self.monitor = monitor
    }
}

/// Monitors and tracks navigation state for a destination context.
///
/// `DestinationMonitor` is created with a presentation mode and provides
/// `EntryConfiguration` instances for each destination. It uses an internal
/// `EntryMonitor` to detect when navigation transitions between same-module
/// destinations and external modules, allowing the system to suppress
/// redundant navigation events.
///
/// Example:
/// ```swift
/// let monitor = DestinationMonitor(mode: .push)
/// let config = monitor.entryConfig(for: MyDestination.detail(id: "123"))
/// ```
public final class DestinationMonitor {
    let entryMonitor: EntryMonitor
    public let mode: NavigationMode
    private(set) var preferredDetents: Set<PresentationDetent>?
    
    public convenience init(
        mode: NavigationMode
    ) {
        self.init(
            entryMonitor: EntryMonitor(),
            mode: mode
        )
    }
    
    init(
        entryMonitor: EntryMonitor,
        mode: NavigationMode
    ) {
        self.entryMonitor = entryMonitor
        self.mode = mode
    }
    
    public func entryConfig<Destination: Hashable>(for destination: Destination) -> EntryConfiguration<Destination> {
        EntryConfiguration(
            destination: destination,
            monitor: self
        )
    }
    
    /// There is a bug in SwiftUI where presentationDetents set within a NavigationStack are sometimes/often ignored.
    /// If your view has presentation detents, then you should call this method when setting up the destination
    public func disableNavigationStack() {
        entryMonitor.manuallyDisableNavStack = true
    }
    
    /// If you absolutely need presentationDetents *and* and NavigationStack to push on, you can set
    /// your detents with this function.
    public func setPreferredDetents(_ detents: Set<PresentationDetent>) {
        preferredDetents = detents
    }
}

/// Internal tracker for navigation state within a module's destination handler.
///
/// Tracks whether the current destination is within the same module
/// (`isCurrentlyInSameModule`) and whether navigation is transitioning to an
/// external module (`isNavigatingToExternal`). When both are true,
/// `shouldSuppressNavigation` returns `true`, preventing the navigation system
/// from re-presenting a destination that is already being handled by the
/// current module's navigation stack.
final class EntryMonitor {
    var isCurrentlyInSameModule: Bool
    var isNavigatingToExternal: Bool
    var manuallyDisableNavStack: Bool
    
    var shouldSuppressPushNavigation: Bool {
        (isCurrentlyInSameModule && isNavigatingToExternal) || manuallyDisableNavStack
    }

    init() {
        self.isCurrentlyInSameModule = false
        self.isNavigatingToExternal = false
        self.manuallyDisableNavStack = false
    }
}
