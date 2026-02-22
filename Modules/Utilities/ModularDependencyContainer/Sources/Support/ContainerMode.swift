//
//  ContainerMode.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne
//

// MARK: - Container Mode

/// Controls whether the dependency container uses production or mock registrations.
///
/// Set once at the root container and inherited by all children via `buildChild`.
///
/// In testing mode, parent-provided dependencies always take precedence over
/// child mock registrations. Child mocks only fill gaps the parent doesn't cover.
/// Test-site overrides via `buildChildWithOverrides` always take effect regardless.
///
/// ```swift
/// // Production (default)
/// let builder = DependencyBuilder<GraphRoot>(mode: .production)
///
/// // Testing — parent deps propagate, mocks fill gaps
/// let builder = DependencyBuilder<GraphRoot>(mode: .testing)
/// ```
public enum ContainerMode: Sendable, Equatable {
    /// Normal app execution. Uses `registerDependencies`.
    case production

    /// Test execution. Uses `mockRegistration` for modules that conform
    /// to `TestDependencyProvider`, falls back to `registerDependencies`
    /// with a warning for modules that don't.
    ///
    /// Parent-provided dependencies take precedence over child mock
    /// registrations. Child mocks only apply for dependencies the parent
    /// doesn't already provide. Test-site overrides via
    /// `buildChildWithOverrides` always take effect.
    case testing
}

// MARK: - Convenience Accessors

extension ContainerMode {
    /// Whether this mode is any form of testing.
    public var isTesting: Bool {
        switch self {
        case .production: false
        case .testing: true
        }
    }
}
