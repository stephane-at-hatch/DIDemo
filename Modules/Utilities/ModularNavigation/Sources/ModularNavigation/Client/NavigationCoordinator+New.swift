//
//  NavigationCoordinator+New.swift
//
//  Created by Stephane Magne
//

import SwiftUI

@MainActor
extension NavigationCoordinator {
    /// Creates a child navigation coordinator for a new navigation context.
    ///
    /// This method creates a new coordinator that:
    /// - Inherits the appropriate navigation path based on presentation mode
    /// - Receives any remaining deep link route to continue processing
    /// - Has a dismissal handler that targets this parent coordinator
    ///
    /// The path inheritance behavior:
    /// - Root coordinators don't pass paths to children
    /// - Push navigation shares the parent's path
    /// - Sheets and covers get independent paths (nil)
    ///
    /// Deep link routes are automatically consumed and split:
    /// - If the route's destination type matches `NextDestination`, the first segment is consumed
    /// - Remaining route segments are handed off to the child for further processing
    ///
    /// - Parameters:
    ///   - mode: The presentation mode for the new context (typically .push, .sheet, or .cover)
    /// - Returns: A new navigation coordinator configured for the child context
    func newCoordinator<NextDestination: Hashable>(
        mode: NavigationMode
    ) -> NavigationCoordinator<NextDestination> {
        // Root coordinators don't inherit paths; nested contexts may inherit based on mode
        let chainedPath = isRoot ? nil : path(for: mode)
            
        let coordinator = NavigationCoordinator<NextDestination>(
            type: .nested(path: chainedPath),
            presentationMode: mode,
            route: deepLinkRoute.handoffRoute,
            dismissParent: {
                self.closeSheetOrCover()
            }
        )

        // If the handoff route can be consumed by the new destination type, clear it
        let isConsumableHandoff = deepLinkRoute.handoffRoute.isConsumable(by: NextDestination.self) == true
        if isConsumableHandoff {
            deepLinkRoute.handoffRoute = []
        }

        return coordinator
    }
}
