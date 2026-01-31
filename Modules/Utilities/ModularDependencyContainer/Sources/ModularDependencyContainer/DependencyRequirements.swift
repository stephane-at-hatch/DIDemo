//
//  DependencyRequirements.swift
//  Modules
//
//  Created by Stephane Magne
//

// MARK: - Dependency Requirements Protocol

/// Protocol for declaring a module's dependency requirements.
///
/// Two-phase design:
/// 1. **Registration phase** (static): `registerDependencies(in:)` mutates a builder
/// 2. **Usage phase** (instance): `init(_:)` receives a frozen container
public protocol DependencyRequirements: Sendable {
    /// The dependencies this module requires from its parent (inherited).
    static var requirements: [Requirement] { get }

    /// The MainActor-isolated dependencies this module requires from its parent (inherited).
    static var mainActorRequirements: [Requirement] { get }

    /// The local dependencies this module registers for itself only (not inherited by children).
    static var localRequirements: [Requirement] { get }

    /// The local MainActor-isolated dependencies this module registers for itself only.
    static var localMainActorRequirements: [Requirement] { get }

    /// The inputs this module requires (runtime configuration).
    static var inputRequirements: [InputRequirement] { get }

    /// Registers this module's dependencies into the builder.
    /// Called during build phase, before freezing.
    @MainActor
    static func registerDependencies(in builder: DependencyBuilder<Self>)

    /// Creates an instance with access to the frozen container.
    /// Called after freezing, for resolution during usage.
    init(_ container: DependencyContainer<Self>)
}

// MARK: - Default Implementations

extension DependencyRequirements {
    public static var requirements: [Requirement] { [] }
    public static var mainActorRequirements: [Requirement] { [] }
    public static var localRequirements: [Requirement] { [] }
    public static var localMainActorRequirements: [Requirement] { [] }
    public static var inputRequirements: [InputRequirement] { [] }

    @MainActor
    public static func registerDependencies(in builder: DependencyBuilder<Self>) {}
}
