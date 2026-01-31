//
//  NavigationClient+Root.swift
//  ModularNavigation
//
//  Created by Stephane Magne
//

import SwiftUI

/// Special destination type used only by root coordinators.
/// Root coordinators don't navigate to destinations themselves; they only manage child contexts.
public enum RootDestination: Hashable {}

extension NavigationClient {
    /// Create a root navigation client for the top-level navigation context.
    ///
    /// This creates the entry point for your navigation hierarchy. Typically called once at app startup
    /// and used to initialize tab bars or the main navigation flow.
    ///
    /// - Parameters:
    ///   - firstDestinationType: The destination type that immediate child contexts will use.
    ///     This is needed for type inference but doesn't affect the root's behavior.
    ///   - initialRoute: Optional deep link route to process on startup. The route will be
    ///     distributed to child coordinators as they're created.
    ///   - dismissParent: Closure called when attempting to dismiss. For root contexts, this
    ///     typically returns `false` since there's no parent to dismiss to.
    /// - Returns: A root coordinator ready to manage the top-level navigation
    /// swiftformat:disable:next opaqueGenericParameters
    public static func root(
        initialRoute: AnyRoute = [],
        dismissParent: @escaping () -> Bool = { false }
    ) -> NavigationClient<RootDestination> {
        NavigationCoordinator<RootDestination>(
            type: .root,
            presentationMode: .root,
            route: initialRoute,
            dismissParent: dismissParent
        )
        .client
    }
}
