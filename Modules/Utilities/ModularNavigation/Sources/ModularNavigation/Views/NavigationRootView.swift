//
//  NavigationRootView.swift
//  ModularNavigation
//
//  Created by Stephane Magne
//

import SwiftUI

/// Root view that wraps content in a NavigationStack and manages navigation state.
///
/// This is the entry point for every independent navigation context (tab, sheet, fullscreen cover).
/// It creates or inherits a NavigationStack and binds the coordinator's state to SwiftUI's
/// native navigation system.
///
/// Behavior depends on whether the coordinator has an inherited path:
/// - No inherited path: Creates a new NavigationStack with its own path binding
/// - Inherited path: Reuses the parent's NavigationStack (push navigation)
///
/// You typically don't instantiate this directly; it's created automatically by the
/// `NavigationDestinationView` or tab setup code.
struct NavigationRootView<Destination: Hashable, Content: View>: View {
    /// The navigation path state for this context (when not using an inherited path)
    @State var navigationPath = NavigationPath()

    /// The presentation state (sheet/cover) for this context
    @State var presentationBindings = PresentationBindings<Destination>()

    /// The coordinator managing navigation state
    private let coordinator: NavigationCoordinator<Destination>
    
    /// Builder function to create views for destinations
    private let builder: DestinationBuilder<Destination, Content>

    /// Closure that builds the root content to display
    private let content: () -> Content
    
    /// Initialize a navigation root view for a new context.
    /// - Parameters:
    ///   - coordinator: The coordinator managing this navigation context
    ///   - builder: Closure to build views for destinations
    ///   - content: Closure to build the root content view
    init(
        coordinator: NavigationCoordinator<Destination>,
        builder: @escaping DestinationBuilder<Destination, Content>,
        content: @escaping () -> Content
    ) {
        self.coordinator = coordinator
        self.builder = builder
        self.content = content
    }
    
    var body: some View {
        if coordinator.chainedPath == nil {
            // Create a new NavigationStack with our own path
            NavigationStack(path: $navigationPath) {
                DestinationHookupView(
                    navigationPath: $navigationPath,
                    presentationBindings: $presentationBindings,
                    coordinator: coordinator,
                    builder: builder,
                    content: content
                )
            }
        } else {
            // Use an inherited path from a parent context (push navigation)
            DestinationHookupView(
                navigationPath: $navigationPath,
                presentationBindings: $presentationBindings,
                coordinator: coordinator,
                builder: builder,
                content: content
            )
        }
    }
}

/// Internal view that connects the coordinator's state to the view hierarchy.
///
/// This view performs the critical task of binding the coordinator's internal state
/// (path and presentation bindings) to the actual SwiftUI state objects that were
/// created in the parent view.
private struct DestinationHookupView<Destination: Hashable, Content: View>: View {
    /// The coordinator managing navigation state
    private let coordinator: NavigationCoordinator<Destination>
    
    /// Builder function to create views for destinations
    private let builder: DestinationBuilder<Destination, Content>

    /// Closure that builds the root content
    private let content: () -> Content
    
    /// Initialize the destination hookup view.
    ///
    /// The initializer performs the binding between coordinator and SwiftUI state:
    /// - If no inherited path, binds the coordinator to the local navigation path
    /// - Always binds the presentation state for sheets and covers
    ///
    /// - Parameters:
    ///   - navigationPath: Binding to the navigation path state
    ///   - presentationBindings: Binding to sheet/cover presentation state
    ///   - coordinator: The coordinator managing this navigation context
    ///   - builder: Closure to build views for destinations
    ///   - content: Closure to build the root content view
    init(
        navigationPath: Binding<NavigationPath>,
        presentationBindings: Binding<PresentationBindings<Destination>>,
        coordinator: NavigationCoordinator<Destination>,
        builder: @escaping DestinationBuilder<Destination, Content>,
        content: @escaping () -> Content
    ) {
        self.coordinator = coordinator
        self.builder = builder
        self.content = content
        // Bind the coordinator to SwiftUI state
        coordinator.presentationBindings = presentationBindings
        if coordinator.chainedPath == nil {
            coordinator.rootPath = navigationPath
        }
    }
    
    var body: some View {
        content()
            .destinationHandler(
                coordinator: coordinator,
                builder: builder
            )
    }
}
