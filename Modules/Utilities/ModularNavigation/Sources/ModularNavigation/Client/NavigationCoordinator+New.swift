//
//  NavigationCoordinator+New.swift
//
//  Created by Stephane Magne on 2025-11-05.
//  Copyright hatch.co, 2025.
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
    ///   - monitor: Monitors presentation context and if navigation is crossing module boundaries
    /// - Returns: A new navigation coordinator configured for the child context
    func newCoordinator<NextDestination: Hashable>(
        monitor: DestinationMonitor
    ) -> NavigationCoordinator<NextDestination> {
        // Update monitor state to determine if we've yet navigated to the next module
        monitor.entryMonitor.isCurrentlyInSameModule = NextDestination.self == Destination.self

        // Root coordinators don't inherit paths; nested contexts may inherit based on mode
        let chainedPath = isRoot ? nil : path(for: monitor.mode)
            
        return NavigationCoordinator<NextDestination>(
            type: .nested(path: chainedPath),
            presentationMode: monitor.mode,
            route: deepLinkRoute.handoffRoute,
            didConsumeRoute: {
                self.deepLinkRoute.handoffRoute = []
                self.didConsumeRoute()
            },
            dismissParent: {
                self.closeSheetOrCover()
            }
        )
    }
}
