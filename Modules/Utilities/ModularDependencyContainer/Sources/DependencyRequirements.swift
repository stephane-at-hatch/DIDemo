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

// MARK: - Test Dependency Provider Protocol

/// Protocol for modules that provide mock/stub registrations for testing.
///
/// Inherits from `DependencyRequirements` — modules opt in by conforming to
/// `TestDependencyProvider` instead of (or in addition to) `DependencyRequirements`.
///
/// The default implementation of `mockRegistration` is a no-op, allowing
/// incremental adoption. Modules implement `mockRegistration` to register
/// simple mocks/stubs for ALL of their requirements, making the module
/// self-sufficient in test scenarios.
///
/// ```swift
/// struct MyModuleDependencies: TestDependencyProvider {
///
///     static func registerDependencies(in builder: DependencyBuilder<Self>) {
///         // Production: declare requirements, register real provisions
///     }
///
///     static func mockRegistration(in builder: DependencyBuilder<Self>) {
///         // Testing: register simple mocks for ALL requirements
///     }
/// }
/// ```
///
/// **Guidelines:**
/// - Default mocks should be simple stubs/spies with no dependencies of their own.
/// - Complex mocks that require configuration should be provided at the test site.
public protocol TestDependencyProvider: DependencyRequirements {
    /// Register mock/stub dependencies for testing.
    /// Called instead of `registerDependencies` when building in test mode.
    /// The `MockDependencyBuilder` automatically applies `override: true` to all registrations.
    @MainActor
    static func mockRegistration(in builder: MockDependencyBuilder<Self>)
}

// MARK: - TestDependencyProvider Default Implementation

extension TestDependencyProvider {
    @MainActor
    public static func mockRegistration(in builder: MockDependencyBuilder<Self>) {}

    /// Internal trampoline for type-erased mock registration.
    /// Called by `DependencyContainer.registerForMode` when the concrete type
    /// is only known as `any TestDependencyProvider.Type`.
    ///
    /// After `mockRegistration` completes, runs validation in DEBUG builds:
    /// - **Missing requirements**: asserts if any declared requirements have no registration
    ///   (unless `suppressMissingRequirementAssertions()` was called)
    /// - **Redundant explicit registrations**: warns if an explicit registration duplicates
    ///   one already provided by an import (informational, not an error)
    @MainActor
    static func _callMockRegistration(in builder: Any, parent: AnyFrozenContainer?, skipValidation: Bool = false) {
        guard let typedBuilder = builder as? DependencyBuilder<Self> else {
            assertionFailure("Builder type mismatch in _callMockRegistration. Expected DependencyBuilder<\(Self.self)>.")
            return
        }
        mockRegistration(in: MockDependencyBuilder(builder: typedBuilder, parent: parent))

#if DEBUG
        // Post-registration validation (DEBUG only)
        // Skipped when `buildChildWithOverrides` will run additional registrations
        // after this call — validation runs after everything is complete.
        if !skipValidation {
            _validateMockRegistrations(builder: typedBuilder, parent: parent)
        }
#endif
    }

    /// Runs validation separately. Called by `buildChildWithOverrides` after both
    /// `mockRegistration` and the override closure have completed.
    @MainActor
    static func _validateMockRegistrationsExternally(builder: Any, parent: AnyFrozenContainer?) {
#if DEBUG
        guard let typedBuilder = builder as? DependencyBuilder<Self> else { return }
        _validateMockRegistrations(builder: typedBuilder, parent: parent)
#endif
    }

    /// Validates that mockRegistration covered all declared requirements.
    /// Only runs in DEBUG builds, called from `_callMockRegistration`.
    @MainActor
    private static func _validateMockRegistrations(builder: DependencyBuilder<Self>, parent: AnyFrozenContainer?) {
        let moduleName = String(describing: Self.self)

        // Collect all requirement keys
        var allRequiredKeys = Set<RegistrationKey>()
        var localRequiredKeys = Set<RegistrationKey>()

        for req in Self.requirements where !req.isOptional {
            allRequiredKeys.insert(req.key)
        }
        for req in Self.mainActorRequirements where !req.isOptional {
            allRequiredKeys.insert(req.key.withIsolation(.mainActor))
        }
        for req in Self.localRequirements where !req.isOptional {
            let key = req.key
            allRequiredKeys.insert(key)
            localRequiredKeys.insert(key)
        }
        for req in Self.localMainActorRequirements where !req.isOptional {
            let key = req.key.withIsolation(.mainActor)
            allRequiredKeys.insert(key)
            localRequiredKeys.insert(key)
        }

        // Check for missing registrations
        var missingDescriptions: [String] = []
        for req in Self.requirements where !req.isOptional {
            if !builder.canResolveForValidation(key: req.key, isMainActor: false, isLocal: false),
               !(parent?.canResolve(key: req.key) ?? false) {
                missingDescriptions.append(req.description)
            }
        }
        for req in Self.mainActorRequirements where !req.isOptional {
            let key = req.key.withIsolation(.mainActor)
            if !builder.canResolveForValidation(key: key, isMainActor: true, isLocal: false),
               !(parent?.canResolve(key: key) ?? false) {
                missingDescriptions.append(req.description)
            }
        }
        for req in Self.localRequirements where !req.isOptional {
            if !builder.canResolveForValidation(key: req.key, isMainActor: false, isLocal: true) {
                missingDescriptions.append("[local] \(req.description)")
            }
        }
        for req in Self.localMainActorRequirements where !req.isOptional {
            let key = req.key.withIsolation(.mainActor)
            if !builder.canResolveForValidation(key: key, isMainActor: true, isLocal: true) {
                missingDescriptions.append("[local mainActor] \(req.description)")
            }
        }

        // Check input requirements
        for req in Self.inputRequirements {
            if !builder.hasInput(for: req.key) {
                missingDescriptions.append("[input] \(req.description)")
            }
        }

        let totalRequirements = allRequiredKeys.count + Self.inputRequirements.count

        if !missingDescriptions.isEmpty {
            let missingList = missingDescriptions.joined(separator: ", ")
            let message = "❌ \(moduleName): missing registrations for [\(missingList)]"
            if builder.isMissingRequirementAssertionsSuppressed {
                print(message)
            } else {
                assertionFailure(message)
            }
            return
        }

        // Check for redundant explicit registrations (explicit that duplicates an import)
        // An explicit registration is redundant if the same key was also brought in by import.
        // This means the import already covers this type, and the explicit may no longer be needed.
        let redundantKeys = builder.explicitRegistrationKeys.intersection(builder.importedRegistrationKeys)
        if !redundantKeys.isEmpty {
            let descriptions = redundantKeys.compactMap { key -> String? in
                builder.registrationMetadata(for: key)?.typeDescription
            }
            .sorted()
            let descList = descriptions.joined(separator: ", ")
            print("⚠️ \(moduleName): all \(totalRequirements) requirements met, with redundant explicit registrations for [\(descList)]")
        } else {
            print("✅ \(moduleName): all \(totalRequirements) requirements met")
        }
    }
}
