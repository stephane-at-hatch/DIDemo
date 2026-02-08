//
//  NavigationCoordinator+Mock.swift
//
//  Created by Stephane Magne on 2025-11-17.
//  Copyright hatch.co, 2025.
//

import SwiftUI

@MainActor
extension NavigationCoordinator {
    /// Creates a mock navigation coordinator for testing purposes.
    ///
    /// This creates a minimal coordinator with no navigation state or deep linking,
    /// suitable for quick testing scenarios where navigation behavior isn't being verified.
    ///
    /// For more sophisticated test scenarios, use `NavigationClient.mock()` instead,
    /// which allows you to capture and verify navigation calls.
    ///
    /// - Returns: A mock root coordinator with no-op dismissal behavior
    public static func mockCoordinator() -> NavigationCoordinator<Destination> {
        NavigationCoordinator<Destination>(
            type: .root,
            presentationMode: .root,
            route: [],
            dismissParent: { false }
        )
    }
}
