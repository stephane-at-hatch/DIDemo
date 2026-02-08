//
//  NavigationCoordinator.swift
//  HatchModularNavigation
//
//  Created by Stephane Magne on 2025-10-28.
//  Copyright hatch.co, 2025.
//

import SwiftUI

/// Owns and manages navigation state for a specific destination type.
///
/// The coordinator is the core state manager for a navigation context. It maintains the navigation path,
/// presentation state (sheets/covers), and deep link routing information. Each independent navigation
/// context (tab, sheet, fullscreen) has its own coordinator instance.
///
/// Coordinators handle:
/// - Push navigation within a NavigationStack
/// - Sheet and full-screen cover presentation
/// - Smart dismissal logic that respects the navigation hierarchy
/// - Deep link route processing and handoff to child coordinators
///
/// Use `NavigationClient` for dependency injection rather than passing coordinators directly.
@MainActor
final class NavigationCoordinator<Destination: Hashable>: Hashable {
    /// Defines whether the coordinator is a root (top-level) or nested within another navigation context
    enum CoordinatorType {
        /// Root coordinator at the app's top level (e.g., managing tabs)
        case root
        /// Nested coordinator within a parent context, optionally sharing a navigation path
        case nested(path: Binding<NavigationPath>?)
    }
        
    /// Manages deep link routing state for this coordinator.
    ///
    /// When a coordinator is created, it receives a route to process. The route is split into:
    /// - `initialSteps`: Navigation steps this coordinator can immediately consume
    /// - `handoffRoute`: Remaining route segments to pass to child coordinators
    class DeepLinkRoute {
        /// Navigation steps to be processed when this coordinator appears
        var initialSteps: [NavigationStep<Destination>]

        /// Remaining route to be handed off to child coordinators
        var handoffRoute: AnyRoute
        
        init(initialSteps: [NavigationStep<Destination>], handoffRoute: AnyRoute) {
            self.initialSteps = initialSteps
            self.handoffRoute = handoffRoute
        }
    }

    /// Current navigation path binding (either owned or inherited from parent)
    var navigationPath: Binding<NavigationPath>? {
        if let rootPath {
            rootPath
        } else if let chainedPath {
            chainedPath
        } else {
            nil
        }
    }
    
    /// Navigation path binding owned by this coordinator's NavigationStack
    var rootPath: Binding<NavigationPath>?
    
    /// Navigation path binding inherited from a parent coordinator
    var chainedPath: Binding<NavigationPath>?

    /// Bindings for sheet and cover presentation state
    var presentationBindings: Binding<PresentationBindings<Destination>>?

    /// Deep link route information for this coordinator
    let deepLinkRoute: DeepLinkRoute
    
    /// True if this is a root coordinator (top-level, not nested in another context)
    let isRoot: Bool

    /// How this coordinator's context is presented (root, push, sheet, cover)
    let presentationMode: NavigationMode

    /// Closure to dismiss the parent presentation context
    let dismissParent: () -> Bool

    /// Unique identifier for Hashable conformance and coordinator identity
    let uuid = UUID()

    /// Initialize a navigation coordinator.
    /// - Parameters:
    ///   - type: Whether this is a root or nested coordinator
    ///   - presentationMode: How this coordinator's context is presented
    ///   - route: Initial route to process for deep linking
    ///   - dismissParent: Closure to dismiss the parent presentation context
    init(
        type: CoordinatorType,
        presentationMode: NavigationMode,
        route: AnyRoute = [],
        dismissParent: @escaping () -> Bool
    ) {
        switch type {
        case .root:
            self.isRoot = true
            self.deepLinkRoute = DeepLinkRoute(initialSteps: [], handoffRoute: route)
        case .nested(let chainedPath):
            self.isRoot = false
            let isConsumableHandoff = route.isConsumable(by: Destination.self)
            self.deepLinkRoute = DeepLinkRoute(
                initialSteps: isConsumableHandoff ? route.first?.steps as? [NavigationStep<Destination>] ?? [] : [],
                handoffRoute: isConsumableHandoff ? Array(route.dropFirst()) : route
            )
            self.chainedPath = chainedPath
        }
        self.presentationMode = presentationMode
        self.dismissParent = dismissParent
    }

    // MARK: - Present

    /// Push a destination onto the navigation stack.
    /// Has no effect if a modal (sheet/cover) is currently presented.
    func present(_ destination: Destination, mode: NavigationMode) {
        append(
            NavigationStep(destination: destination, mode: mode)
        )
    }

    // MARK: - Pop From Stack
    
    /// Pop the topmost destination from the navigation stack.
    /// Has no effect if the stack is empty or a modal is presented.
    func pop() {
        // Don't pop if we have an active modal presentation
        if presentationBindings?.wrappedValue.fullScreenCover != nil || presentationBindings?.wrappedValue.sheet != nil {
            return
        }
        
        if navigationPath?.wrappedValue.isEmpty == false {
            navigationPath?.wrappedValue.removeLast()
        }
    }
    
    /// Pop to root by clearing the entire navigation stack.
    func popToRoot() {
        navigationPath?.wrappedValue = NavigationPath()
    }
    
    // MARK: - Dismiss Sheet Presentation
    
    /// Dismiss the currently presented sheet.
    func dismissSheet() {
        presentationBindings?.wrappedValue.sheet = nil
    }
    
    // MARK: - Dismiss Full Screen Cover Presentation
    
    /// Dismiss the currently presented full screen cover.
    func dismissFullScreenCover() {
        presentationBindings?.wrappedValue.fullScreenCover = nil
    }
    
    // MARK: - Smart Dismiss
    
    /// Contextually dismiss the topmost presentation.
    ///
    /// Intelligently determines what to dismiss based on the current state:
    /// 1. If a sheet or cover is presented, dismiss it
    /// 2. Otherwise, if the navigation stack has items, pop the top item
    /// 3. Otherwise, attempt to dismiss the parent context
    func dismiss() {
        // First check if we have any presented modals
        if presentationBindings?.wrappedValue.sheet?.value != nil {
            dismissSheet()
            return
        }
        
        if presentationBindings?.wrappedValue.fullScreenCover?.value != nil {
            dismissFullScreenCover()
            return
        }
        
        // Then check if we can pop from navigation stack
        if navigationPath?.wrappedValue.isEmpty == false {
            pop()
            return
        }
        
        // Finally, dismiss the parent context
        closeSheetOrCover()
    }
    
    /// Close the entire presentation context.
    ///
    /// First attempts to dismiss the parent context. If that's not possible (e.g., this is
    /// a root context or the parent refuses dismissal), pops to root instead.
    ///
    /// Use for "Close" or "Done" buttons that should exit a modal flow completely.
    func close() {
        if dismissParent() {
            return
        }
        
        popToRoot()
    }
    
    /// Dismiss this coordinator's presentation context or delegate to parent.
    ///
    /// Attempts to dismiss any active sheet or cover. If none are present,
    /// delegates to the parent's dismissal handler.
    ///
    /// - Returns: `true` if a dismissal occurred, `false` otherwise
    @discardableResult
    func closeSheetOrCover() -> Bool {
        if presentationBindings?.wrappedValue.sheet?.value != nil {
            dismissSheet()
            return true
        }
        
        if presentationBindings?.wrappedValue.fullScreenCover?.value != nil {
            dismissFullScreenCover()
            return true
        }

        return dismissParent()
    }
    
    // MARK: - Hashable Conformance
    
    /// swiftformat:disable:next modifierOrder
    nonisolated static func == (lhs: NavigationCoordinator<Destination>, rhs: NavigationCoordinator<Destination>) -> Bool {
        lhs.uuid == rhs.uuid
    }

    /// swiftformat:disable:next modifierOrder
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    // MARK: - Internal Methods
    
    /// Append a navigation step to the appropriate state (path, sheet, or cover).
    /// Prevents presenting modals when one is already active.
    private func append(_ step: NavigationStep<Destination>) {
        switch step.mode.baseMode {
        case .root,
             .withoutNavStack:
            return
        case .push:
            navigationPath?.wrappedValue.append(step.destination)
        case .sheet(let presentationDetents):
            // Don't present if we already have a sheet or cover
            guard presentationBindings?.wrappedValue.sheet?.value == nil else { return }
            guard presentationBindings?.wrappedValue.fullScreenCover?.value == nil else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = !step.animated
            withTransaction(transaction) {
                presentationBindings?.wrappedValue.sheet = IdentifiableBox(
                    value: (step.destination, step.mode.allowsNavStack, presentationDetents, step.animated)
                )
            }
        case .cover:
            // Don't present if we already have a cover or sheet
            guard presentationBindings?.wrappedValue.sheet?.value == nil else { return }
            guard presentationBindings?.wrappedValue.fullScreenCover?.value == nil else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = !step.animated
            withTransaction(transaction) {
                presentationBindings?.wrappedValue.fullScreenCover = IdentifiableBox(value: (step.destination, step.mode.allowsNavStack, step.animated))
            }
        }
    }
    
    /// Dismiss based on a specific navigation mode.
    func dismiss(for mode: NavigationMode) {
        switch mode.baseMode {
        case .root,
             .withoutNavStack:
            break
        case .push:
            pop()
        case .sheet:
            dismissSheet()
        case .cover:
            dismissFullScreenCover()
        }
    }
    
    /// Process any initial deep link route steps.
    ///
    /// Extracts and clears the initial steps, then asynchronously processes them
    /// after a brief delay to ensure the view hierarchy is ready. Sheets and covers
    /// require slightly longer delays to account for their presentation animations.
    func processInitialRoute() {
        let initialSteps = deepLinkRoute.initialSteps
        deepLinkRoute.initialSteps = []
        
        Task { @MainActor in
            // Introduce a slight delay to account for presentation animations
            // This ensures the navigation stack is ready before processing steps
            switch presentationMode.baseMode {
            case .root,
                 .push,
                 .withoutNavStack:
                break
            case .sheet,
                 .cover:
                try? await Task.sleep(for: .milliseconds(400))
            }
            
            for step in initialSteps {
                append(step)
            }
        }
    }
    
    /// Get the navigation path binding if the mode uses push navigation.
    /// - Returns: Path binding for push navigation, nil for modal presentations
    func path(for mode: NavigationMode) -> Binding<NavigationPath>? {
        switch mode {
        case .root, // When being set as the root of a tab
             .push: // When pushing in a navigation stack
            navigationPath
        case .sheet,
             .cover: // Sheets and covers create their own navigation context
            nil
        case .withoutNavStack(let mode):
            path(for: mode)
        }
    }
}

// MARK: - Bindings

/// Observable container for sheet and cover presentation state.
/// Stores optional identifiable wrappers that trigger SwiftUI's sheet/cover modifiers.
struct PresentationBindings<Destination> {
    // swiftlint:disable large_tuple
    /// Current sheet presentation with destination and detent configuration
    var sheet: IdentifiableBox<(destination: Destination, allowsNavStack: Bool, detents: Set<PresentationDetent>?, animated: Bool)>?
    /// Current full screen cover presentation
    var fullScreenCover: IdentifiableBox<(destination: Destination, allowsNavStack: Bool, animated: Bool)>?
    // swiftlint:enable large_tuple
}

/// Identifiable wrapper for non-Identifiable values, enabling SwiftUI's item-based presentation.
final class IdentifiableBox<T>: Identifiable {
    let id = UUID()
    let value: T
    
    init(value: T) {
        self.value = value
    }
}

extension NavigationCoordinator {
    /// Convert this coordinator to a NavigationClient for dependency injection.
    var client: NavigationClient<Destination> {
        NavigationClient(coordinator: self)
    }
}
