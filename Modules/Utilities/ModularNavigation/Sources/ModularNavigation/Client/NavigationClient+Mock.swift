//
//  NavigationClient+Mock.swift
//
//  Created by Stephane Magne
//

extension NavigationClient {
    /// Create a mock navigation client for testing.
    ///
    /// Provides no-op implementations by default, or accepts custom closures
    /// to verify navigation calls during testing.
    ///
    /// Example:
    /// ```swift
    /// var presentedDestinations: [MyDestination] = []
    /// let client = NavigationClient.mock(
    ///     present: { destination, _ in
    ///         presentedDestinations.append(destination)
    ///     }
    /// )
    /// ```
    public static func mock(
        present: @escaping (Destination, NavigationMode) -> Void = { _, _ in },
        dismiss: @escaping () -> Void = {},
        popToRoot: @escaping () -> Void = {},
        close: @escaping () -> Void = {}
    ) -> NavigationClient<Destination> {
        NavigationClient<Destination>(
            present: present,
            dismiss: dismiss,
            popToRoot: popToRoot,
            close: close
        )
    }
}
