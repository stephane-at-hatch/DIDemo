//
//  NavigationDestinationHandler.swift
//  HatchModularNavigation
//
//  Created by Stephane Magne on 2025-10-25.
//  Copyright hatch.co, 2025.
//

import SwiftUI

extension View {
    /// Attaches navigation destination handling to a view.
    ///
    /// This is the core integration point that wires up SwiftUI's native navigation modifiers
    /// (navigationDestination, sheet, fullScreenCover) to the coordinator's state management.
    ///
    /// Typically you don't call this directly; it's automatically applied by `NavigationRootView`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator managing navigation state for this context
    ///   - builder: Closure to build views for destinations
    /// - Returns: A view with navigation handling attached
    /// swiftformat:disable:next opaqueGenericParameters
    func destinationHandler<Destination, ViewContent>(
        coordinator: NavigationCoordinator<Destination>,
        builder: @escaping DestinationBuilder<Destination, ViewContent>
    ) -> some View where Destination: Hashable, ViewContent: View {
        modifier(
            NavigationDestinationHandler(
                coordinator: coordinator,
                builder: builder
            )
        )
    }
}

/// ViewModifier that wires up navigation destinations, sheets, and covers for a coordinator.
///
/// This modifier:
/// - Registers `navigationDestination` handlers for push navigation
/// - Observes coordinator state to present sheets and covers
/// - Injects the coordinator into child views via environment
/// - Processes initial deep link routes when the view appears
struct NavigationDestinationHandler<Destination, ViewContent>: ViewModifier where Destination: Hashable, ViewContent: View {
    /// The coordinator managing navigation state
    let coordinator: NavigationCoordinator<Destination>

    /// Builder function to create views for destinations
    let builder: DestinationBuilder<Destination, ViewContent>
    
    /// Initialize the navigation destination handler
    /// - Parameters:
    ///   - coordinator: The coordinator managing navigation state
    ///   - builder: Closure to build views for destinations
    init(
        coordinator: NavigationCoordinator<Destination>,
        builder: @escaping DestinationBuilder<Destination, ViewContent>
    ) {
        self.coordinator = coordinator
        self.builder = builder
    }
    
    func body(content: Content) -> some View {
        content
            .optionalNavigationDestination(
                for: Destination.self,
                hasNavStack: coordinator.presentationMode.allowsNavStack
            ) { destination in
                builder(destination, .push, coordinator.client)
                    .environment(\.navigationCoordinator, AnyNavigationCoordinator(coordinator: coordinator))
            }
            .optionalSheet(
                item: coordinator.presentationBindings?.sheet,
                onDismiss: {
                    // Optional: Add completion handler support in the future
                }, content: { sheetItem in
                    NavigationDestinationView(
                        previousCoordinator: coordinator,
                        mode: sheetItem.value.allowsNavStack
                            ? .sheet(detents: sheetItem.value.detents)
                            : .withoutNavStack(.sheet(detents: sheetItem.value.detents)),
                        destination: sheetItem.value.destination,
                        builder: builder
                    )
                    .optionalPresentationDetents(sheetItem.value.detents)
                }
            )
            .optionalFullScreenCover(
                item: coordinator.presentationBindings?.fullScreenCover,
                onDismiss: {
                    // Optional: Add completion handler support in the future
                }, content: { coverItem in
                    NavigationDestinationView(
                        previousCoordinator: coordinator,
                        mode: coverItem.value.allowsNavStack ? .cover : .withoutNavStack(.cover),
                        destination: coverItem.value.destination,
                        builder: builder
                    )
                }
            )
            .onAppear {
                // Process any initial deep link route when view appears
                coordinator.processInitialRoute()
            }
            .environment(\.navigationCoordinator, AnyNavigationCoordinator(coordinator: coordinator))
    }
}

extension View {
    /// Conditionally add a navigation destination when a NavigationStack is present
    ///
    /// This wrapper allows navigation destination  to be conditionally applied based on whether
    /// the coordinator has allowed a NavigationStack or not. Used internally by the destination handler.
    ///
    /// - Parameters:
    ///   - data: The navigation data type
    ///   - hasNavStack: Whether or not a NavigationStack is present
    ///   - destination: The destination builder
    /// - Returns: A view that conditionally applies a navigation destination
    @ViewBuilder
    /// swiftformat:disable:next opaqueGenericParameters
    /// swiftformat:disable:next modifierOrder
    nonisolated public func optionalNavigationDestination<D, C>(
        for data: D.Type,
        hasNavStack: Bool,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> some View where D: Hashable, C: View {
        if hasNavStack {
            navigationDestination(for: D.self) { destinationType in
                destination(destinationType)
            }
        } else {
            self
        }
    }
    
    /// Conditionally presents a sheet when an optional item is not nil.
    ///
    /// This wrapper allows sheet modifiers to be conditionally applied based on whether
    /// the coordinator has presentation bindings. Used internally by the destination handler.
    ///
    /// - Parameters:
    ///   - item: Optional binding to an identifiable item that controls sheet presentation
    ///   - onDismiss: Optional closure called when the sheet is dismissed
    ///   - content: Closure to build the sheet content from the item
    /// - Returns: A view that conditionally presents a sheet
    @ViewBuilder
    /// swiftformat:disable:next opaqueGenericParameters
    /// swiftformat:disable:next modifierOrder
    nonisolated public func optionalSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>?,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> some View {
        if let item {
            sheet(item: item, onDismiss: onDismiss, content: content)
        } else {
            self
        }
    }

    /// Conditionally apply presentationDetends to a sheet when an optional item is not nil.
    ///
    /// This wrapper allows presentation detents to be conditionally applied based on whether
    /// the call-site has passed in a value.
    ///
    /// - Parameters:
    ///   - detents: Optional set of PresentationDetents.
    /// - Returns: A view that conditionally applies presentation detents to a sheet
    @ViewBuilder
    /// swiftformat:disable:next modifierOrder
    nonisolated public func optionalPresentationDetents(
        _ detents: Set<PresentationDetent>?
    ) -> some View {
        if let detents {
            presentationDetents(detents)
        } else {
            self
        }
    }

    /// Conditionally presents a full screen cover when an optional item is not nil.
    ///
    /// This wrapper allows cover modifiers to be conditionally applied based on whether
    /// the coordinator has presentation bindings. Used internally by the destination handler.
    ///
    /// - Parameters:
    ///   - item: Optional binding to an identifiable item that controls cover presentation
    ///   - onDismiss: Optional closure called when the cover is dismissed
    ///   - content: Closure to build the cover content from the item
    /// - Returns: A view that conditionally presents a full screen cover
    @ViewBuilder
    /// swiftformat:disable:next opaqueGenericParameters
    /// swiftformat:disable:next modifierOrder
    nonisolated public func optionalFullScreenCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>?,
        onDismiss: (() -> Void)? = nil,
        content: @escaping (Item) -> Content
    ) -> some View {
        if let item {
            fullScreenCover(item: item, onDismiss: onDismiss, content: content)
        } else {
            self
        }
    }
}
