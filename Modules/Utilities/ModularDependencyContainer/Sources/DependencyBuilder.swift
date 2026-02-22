//
//  DependencyBuilder.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne on 2026-01-05.
//

import Foundation

@MainActor
public enum RootDependencyBuilder {
    public static func buildChild<T: DependencyRequirements>(_ type: T.Type, mode: ContainerMode = .production) -> T {
        let dependencyBuilder = DependencyBuilder<GraphRoot>(mode: mode)
        let dependencyContainer = dependencyBuilder.freeze()
        return dependencyContainer.buildChild(T.self)
    }

    /// Builds a root-level child in testing mode with test-site-specific overrides.
    ///
    /// Convenience for unit tests that don't have a parent container.
    /// Only available in testing mode. Asserts if called with `.production`.
    ///
    /// ```swift
    /// let module = RootDependencyBuilder.buildChildWithOverrides(
    ///     MyModule.self,
    ///     mode: .testing
    /// ) { overrides in
    ///     overrides.provideInput(String.self, "test-value")
    ///     try overrides.registerSingleton(NetworkClient.self) { _ in
    ///         FailingNetworkClient(error: .timeout)
    ///     }
    /// }
    /// ```
    public static func buildChildWithOverrides<T: DependencyRequirements>(
        _ type: T.Type,
        mode: ContainerMode,
        testingOverride: @MainActor (MockDependencyBuilder<T>) throws -> Void
    ) rethrows -> T {
        let dependencyBuilder = DependencyBuilder<GraphRoot>(mode: mode)
        let dependencyContainer = dependencyBuilder.freeze()
        return try dependencyContainer.buildChildWithOverrides(T.self, testingOverride: testingOverride)
    }
}

// MARK: - Exported Registrations (for importDependencies)

/// Snapshot of non-local registrations for transfer between builders.
/// Local-scoped registrations are excluded by design — they are module-private
/// and may reference module-internal types invisible to the importing module.
///
/// This is a top-level type (not nested in `DependencyBuilder<Marker>`) so that
/// exports from `DependencyBuilder<T>` can be imported into `DependencyBuilder<U>`
/// without generic type mismatches.
@MainActor
struct ExportedRegistrations {
    let factories: [RegistrationKey: Factory]
    let scopedFactories: [RegistrationKey: Factory]
    let mainActorFactories: [RegistrationKey: MainActorFactory]
    let mainActorScopedFactories: [RegistrationKey: MainActorFactory]
    let metadata: [RegistrationKey: RegistrationMetadata]
    let inputs: [InputKey: any Sendable]
    let inputMetadata: [InputKey: InputMetadata]
}

// MARK: - Dependency Builder (Mutable, Non-Sendable)

/// Mutable builder for constructing dependency graphs.
/// NOT Sendable—cannot cross concurrency boundaries. This is the safety mechanism.
@MainActor
public final class DependencyBuilder<Marker> {
    // MARK: - Inherited Storage (copied to children via buildChild)

    private var factories: [RegistrationKey: Factory] = [:]
    private var scopedFactories: [RegistrationKey: Factory] = [:]
    private var mainActorFactories: [RegistrationKey: MainActorFactory] = [:]
    private var mainActorScopedFactories: [RegistrationKey: MainActorFactory] = [:]

    // MARK: - Local Storage (NOT copied to children)

    private var localFactories: [RegistrationKey: Factory] = [:]
    private var localScopedFactories: [RegistrationKey: Factory] = [:]
    private var localMainActorFactories: [RegistrationKey: MainActorFactory] = [:]
    private var localMainActorScopedFactories: [RegistrationKey: MainActorFactory] = [:]

    // MARK: - Shared Storage

    private var metadata: [RegistrationKey: RegistrationMetadata] = [:]
    private var inputs: [InputKey: any Sendable]
    private var inputMetadata: [InputKey: InputMetadata] = [:]
    private let parent: AnyFrozenContainer?
    private let mode: ContainerMode

    // MARK: - Import Tracking (for importDependencies validation)

    /// Keys that were brought in via `importDependencies` (not explicitly registered).
    var importedRegistrationKeys: Set<RegistrationKey> = []
    var importedInputKeys: Set<InputKey> = []

    /// Keys that were explicitly registered via `MockDependencyBuilder` registration methods
    /// (not via import). Used to detect redundant explicit registrations.
    var explicitRegistrationKeys: Set<RegistrationKey> = []

    /// When true, the post-registration validation in `mockRegistration` skips the
    /// missing-requirement assertion. Modules in mid-adoption use this as an explicit
    /// opt-in escape hatch.
    var isMissingRequirementAssertionsSuppressed = false

    // MARK: - Namespace Accessors

    public var mainActor: MainActorRegistrar<Marker> {
        MainActorRegistrar(builder: self)
    }

    public var local: LocalRegistrar<Marker> {
        LocalRegistrar(builder: self)
    }

    // MARK: - Initialization

    /// Creates a root builder (no parent).
    public init(mode: ContainerMode = .production) where Marker == GraphRoot {
        self.parent = nil
        self.inputs = [:]
        self.mode = mode
    }

    /// Creates a child builder with a frozen parent.
    init(parent: AnyFrozenContainer, inputs: [InputKey: any Sendable] = [:], mode: ContainerMode = .production) {
        self.parent = parent
        self.inputs = inputs
        self.mode = mode
    }

    /// Creates a scratch builder for import operations (no parent, testing mode).
    /// Used internally by `importDependencies` to run a child module's `mockRegistration`
    /// in an isolated builder, then export the non-local registrations.
    init(scratchForImport mode: ContainerMode) {
        self.parent = nil
        self.inputs = [:]
        self.mode = mode
    }

    // MARK: - Input Management

    public func provideInput<T: Sendable>(
        _ type: T.Type,
        _ value: T,
        file: String = #file,
        line: Int = #line
    ) {
        let key = InputKey(type: type)
        inputs[key] = value
        inputMetadata[key] = InputMetadata(
            typeDescription: String(describing: T.self),
            file: file,
            line: line,
            keyDescription: nil
        )
    }

    public func provideInput<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        _ value: T,
        file: String = #file,
        line: Int = #line
    ) {
        let inputKey = InputKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        inputs[inputKey] = value
        inputMetadata[inputKey] = InputMetadata(
            typeDescription: String(describing: T.self),
            file: file,
            line: line,
            keyDescription: keyDescription
        )
    }

    // MARK: - Registration (Type-Only)

    public func registerInstance<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try register(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try register(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try registerScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Registration (Keyed)

    public func registerInstance<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try register(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try register(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try registerScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Registration (Internal - Inherited)

    private func register<T: Sendable>(
        key: RegistrationKey,
        type: T.Type,
        scope: RegistrationScope,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check scoped)
        if factories[key] != nil || scopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Check for shadowing parent
        if factories[key] == nil, parent?.canResolve(key: key) ?? false, !override {
#if DEBUG
            let keyDesc = keyDescription ?? "type-only"
            assertionFailure("""
            ⚠️ Dependency Shadowing Detected ⚠️
            Type: \(type) (key: \(keyDesc))
            Parent already provides this dependency.
            To use the parent's version, remove this registration.
            To replace it, set override: true.
            """)
#endif
        }

        // Clean up cross-map entry when overriding
        if override {
            scopedFactories.removeValue(forKey: key)
        }

        // Type-erase the factory
        let erasedFactory: @Sendable (AnyFrozenContainer) throws -> any Sendable = { container in
            try factory(container)
        }

        factories[key] = Factory(scope: scope, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: scope,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: false
        )
    }

    private func registerScoped<T: Sendable>(
        key: RegistrationKey,
        type: T.Type,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check non-scoped)
        if scopedFactories[key] != nil || factories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Clean up cross-map entry when overriding
        if override {
            factories.removeValue(forKey: key)
        }

        let erasedFactory: @Sendable (AnyFrozenContainer) throws -> any Sendable = { container in
            try factory(container)
        }

        scopedFactories[key] = Factory(scope: .scoped, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: .scoped,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: false
        )
    }

    // MARK: - MainActor Registration (Internal - called by MainActorRegistrar)

    func registerMainActor<T>(
        key: RegistrationKey,
        type: T.Type,
        scope: RegistrationScope,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check scoped)
        if mainActorFactories[key] != nil || mainActorScopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "MainActor dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Check for shadowing parent
        if mainActorFactories[key] == nil, parent?.canResolve(key: key) ?? false, !override {
#if DEBUG
            let keyDesc = keyDescription ?? "type-only"
            assertionFailure("""
            ⚠️ MainActor Dependency Shadowing Detected ⚠️
            Type: \(type) (key: \(keyDesc))
            Parent already provides this dependency.
            To use the parent's version, remove this registration.
            To replace it, set override: true.
            """)
#endif
        }

        // Clean up cross-map entry when overriding
        if override {
            mainActorScopedFactories.removeValue(forKey: key)
        }

        // Type-erase the factory to Any (not `any Sendable`)
        // MainActor types don't need Sendable - actor isolation is the safety mechanism
        let erasedFactory: @MainActor (AnyFrozenContainer) throws -> Any = { container in
            try factory(container)
        }

        mainActorFactories[key] = MainActorFactory(scope: scope, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: scope,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: false
        )
    }

    func registerMainActorScoped<T>(
        key: RegistrationKey,
        type: T.Type,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check non-scoped)
        if mainActorScopedFactories[key] != nil || mainActorFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "MainActor scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Clean up cross-map entry when overriding
        if override {
            mainActorFactories.removeValue(forKey: key)
        }

        // Type-erase to Any (not `any Sendable`) - MainActor isolation is the safety mechanism
        let erasedFactory: @MainActor (AnyFrozenContainer) throws -> Any = { container in
            try factory(container)
        }

        mainActorScopedFactories[key] = MainActorFactory(scope: .scoped, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: .scoped,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: false
        )
    }

    // MARK: - Local Registration (Internal - called by LocalRegistrar)

    func registerLocal<T: Sendable>(
        key: RegistrationKey,
        type: T.Type,
        scope: RegistrationScope,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check scoped)
        if localFactories[key] != nil || localScopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Clean up cross-map entry when overriding
        if override {
            localScopedFactories.removeValue(forKey: key)
        }

        let erasedFactory: @Sendable (AnyFrozenContainer) throws -> any Sendable = { container in
            try factory(container)
        }

        localFactories[key] = Factory(scope: scope, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: scope,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: true
        )
    }

    func registerLocalScoped<T: Sendable>(
        key: RegistrationKey,
        type: T.Type,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check non-scoped)
        if localScopedFactories[key] != nil || localFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Clean up cross-map entry when overriding
        if override {
            localFactories.removeValue(forKey: key)
        }

        let erasedFactory: @Sendable (AnyFrozenContainer) throws -> any Sendable = { container in
            try factory(container)
        }

        localScopedFactories[key] = Factory(scope: .scoped, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: .scoped,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: true
        )
    }

    // MARK: - Local MainActor Registration (Internal - called by LocalMainActorRegistrar)

    func registerLocalMainActor<T>(
        key: RegistrationKey,
        type: T.Type,
        scope: RegistrationScope,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check scoped)
        if localMainActorFactories[key] != nil || localMainActorScopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local MainActor dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Clean up cross-map entry when overriding
        if override {
            localMainActorScopedFactories.removeValue(forKey: key)
        }

        // Type-erase to Any (not `any Sendable`) - MainActor isolation is the safety mechanism
        let erasedFactory: @MainActor (AnyFrozenContainer) throws -> Any = { container in
            try factory(container)
        }

        localMainActorFactories[key] = MainActorFactory(scope: scope, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: scope,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: true
        )
    }

    func registerLocalMainActorScoped<T>(
        key: RegistrationKey,
        type: T.Type,
        keyDescription: String?,
        override: Bool,
        file: String,
        line: Int,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        // Check for existing registration (cross-map: also check non-scoped)
        if localMainActorScopedFactories[key] != nil || localMainActorFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local MainActor scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
        }

        // Clean up cross-map entry when overriding
        if override {
            localMainActorFactories.removeValue(forKey: key)
        }

        // Type-erase to Any (not `any Sendable`) - MainActor isolation is the safety mechanism
        let erasedFactory: @MainActor (AnyFrozenContainer) throws -> Any = { container in
            try factory(container)
        }

        localMainActorScopedFactories[key] = MainActorFactory(scope: .scoped, factory: erasedFactory)
        metadata[key] = RegistrationMetadata(
            typeDescription: String(describing: T.self),
            scope: .scoped,
            file: file,
            line: line,
            keyDescription: keyDescription,
            isLocal: true
        )
    }

    // MARK: - Container-Agnostic Registration (for MockDependencyBuilder)

    /// Registers a factory that receives `AnyFrozenContainer` instead of a typed container.
    /// This avoids baking the `Marker` type into the factory closure, making the resulting
    /// `Factory` safe to transfer between builders with different `Marker` types via import.
    func registerAgnosticInstance<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        try register(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticSingleton<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        try register(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticScoped<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        try registerScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticInstance<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        try register(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticSingleton<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        try register(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticScoped<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        try registerScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    // MainActor container-agnostic variants

    func registerAgnosticMainActorInstance<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        try registerMainActor(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticMainActorSingleton<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        try registerMainActor(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticMainActorScoped<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        try registerMainActorScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticMainActorInstance<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        try registerMainActor(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticMainActorSingleton<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        try registerMainActor(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    func registerAgnosticMainActorScoped<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        try registerMainActorScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: factory
        )
    }

    // MARK: - Import / Export (for importDependencies)

    /// Exports the non-local registration dictionaries for transfer into another builder.
    func exportNonLocalRegistrations() -> ExportedRegistrations {
        ExportedRegistrations(
            factories: factories,
            scopedFactories: scopedFactories,
            mainActorFactories: mainActorFactories,
            mainActorScopedFactories: mainActorScopedFactories,
            metadata: metadata.filter { !$0.value.isLocal },
            inputs: inputs,
            inputMetadata: inputMetadata
        )
    }

    /// Merges imported registrations into this builder using first-in-wins semantics.
    /// Keys that already exist (from earlier imports or explicit registrations) are skipped silently.
    /// All imported keys are tracked in `importedRegistrationKeys` / `importedInputKeys`.
    func importRegistrations(_ exported: ExportedRegistrations) {
        for (key, factory) in exported.factories {
            if factories[key] == nil, scopedFactories[key] == nil {
                factories[key] = factory
                importedRegistrationKeys.insert(key)
            }
        }

        for (key, factory) in exported.scopedFactories {
            if scopedFactories[key] == nil, factories[key] == nil {
                scopedFactories[key] = factory
                importedRegistrationKeys.insert(key)
            }
        }

        for (key, factory) in exported.mainActorFactories {
            if mainActorFactories[key] == nil, mainActorScopedFactories[key] == nil {
                mainActorFactories[key] = factory
                importedRegistrationKeys.insert(key)
            }
        }

        for (key, factory) in exported.mainActorScopedFactories {
            if mainActorScopedFactories[key] == nil, mainActorFactories[key] == nil {
                mainActorScopedFactories[key] = factory
                importedRegistrationKeys.insert(key)
            }
        }

        // Merge metadata (first-in-wins, matching factory behavior)
        for (key, meta) in exported.metadata {
            if metadata[key] == nil {
                metadata[key] = meta
            }
        }

        // Merge inputs (first-in-wins)
        for (key, value) in exported.inputs {
            if inputs[key] == nil {
                inputs[key] = value
                importedInputKeys.insert(key)
            }
        }

        for (key, meta) in exported.inputMetadata {
            if inputMetadata[key] == nil {
                inputMetadata[key] = meta
            }
        }
    }

    /// Checks whether a registration key already exists in the inherited (non-local) dictionaries.
    func hasRegistration(for key: RegistrationKey) -> Bool {
        factories[key] != nil
            || scopedFactories[key] != nil
            || mainActorFactories[key] != nil
            || mainActorScopedFactories[key] != nil
    }

    /// Checks whether an input key already exists.
    func hasInput(for key: InputKey) -> Bool {
        inputs[key] != nil
    }

    /// Returns all requirement keys for the current Marker type's DependencyRequirements.
    /// Used by validation to check coverage after mockRegistration completes.
    func allRequirementKeys(for type: (some DependencyRequirements).Type) -> Set<RegistrationKey> {
        var keys = Set<RegistrationKey>()

        for req in type.requirements {
            keys.insert(req.key)
        }
        for req in type.mainActorRequirements {
            keys.insert(req.key.withIsolation(.mainActor))
        }
        for req in type.localRequirements {
            keys.insert(req.key)
        }
        for req in type.localMainActorRequirements {
            keys.insert(req.key.withIsolation(.mainActor))
        }

        return keys
    }

    /// Returns all input requirement keys for the current Marker type.
    func allInputRequirementKeys(for type: (some DependencyRequirements).Type) -> Set<InputKey> {
        Set(type.inputRequirements.map { $0.key })
    }

    /// Checks whether a registration key can be resolved — either in this builder's
    /// storage (inherited + local) or from the parent container.
    func canResolveForValidation(key: RegistrationKey, isMainActor: Bool, isLocal: Bool) -> Bool {
        canResolve(key: key, isMainActor: isMainActor, isLocal: isLocal)
    }

    /// Returns metadata for a registration key, if available.
    func registrationMetadata(for key: RegistrationKey) -> RegistrationMetadata? {
        metadata[key]
    }

    // MARK: - Freezing

    public func freeze(
        requirements: [Requirement] = [],
        mainActorRequirements: [Requirement] = [],
        localRequirements: [Requirement] = [],
        localMainActorRequirements: [Requirement] = [],
        inputRequirements: [InputRequirement] = [],
        mode: ContainerMode? = nil
    ) -> DependencyContainer<Marker> {
        validateInputRequirements(inputRequirements)
        validateRequirements(requirements, isMainActor: false, isLocal: false)
        validateRequirements(mainActorRequirements, isMainActor: true, isLocal: false)
        validateRequirements(localRequirements, isMainActor: false, isLocal: true)
        validateRequirements(localMainActorRequirements, isMainActor: true, isLocal: true)

        return DependencyContainer(
            factories: factories,
            scopedFactories: scopedFactories,
            mainActorFactories: mainActorFactories,
            mainActorScopedFactories: mainActorScopedFactories,
            localFactories: localFactories,
            localScopedFactories: localScopedFactories,
            localMainActorFactories: localMainActorFactories,
            localMainActorScopedFactories: localMainActorScopedFactories,
            metadata: metadata,
            inputs: inputs,
            inputMetadata: inputMetadata,
            parent: parent,
            mode: mode ?? self.mode
        )
    }

    // MARK: - Validation

    private func validateInputRequirements(_ inputRequirements: [InputRequirement]) {
        let missing = inputRequirements.filter { req in
            inputs[req.key] == nil
        }

        if !missing.isEmpty {
            let descriptions = missing.map { $0.description }
            let missingList = descriptions.joined(separator: ", ")
            fatalError("""
            Missing inputs: \(missingList)

            Ensure provideInput(Type.self, value) is called BEFORE buildChild().
            """)
        }
    }

    private func validateRequirements(_ requirements: [Requirement], isMainActor: Bool, isLocal: Bool) {
        let missing = requirements.filter { req in
            !req.isOptional && !canResolve(key: req.key, isMainActor: isMainActor, isLocal: isLocal)
        }

        if !missing.isEmpty {
            let descriptions = missing.map { buildMissingDependencyMessage(for: $0, isLocal: isLocal) }
            fatalError(DependencyError.missingDependencies(descriptions).description)
        }
    }

    private func canResolve(key: RegistrationKey, isMainActor: Bool, isLocal: Bool) -> Bool {
        // Create lookup key with correct isolation context
        let lookupKey = isMainActor ? key.withIsolation(.mainActor) : key

        if isLocal {
            // Local dependencies only check local storage
            if isMainActor {
                if localMainActorFactories[lookupKey] != nil { return true }
                if localMainActorScopedFactories[lookupKey] != nil { return true }
            } else {
                if localFactories[lookupKey] != nil { return true }
                if localScopedFactories[lookupKey] != nil { return true }
            }
            return false
        } else {
            // Inherited dependencies check inherited storage + parent
            if isMainActor {
                if mainActorFactories[lookupKey] != nil { return true }
                if mainActorScopedFactories[lookupKey] != nil { return true }
            } else {
                if factories[lookupKey] != nil { return true }
                if scopedFactories[lookupKey] != nil { return true }
            }
            return parent?.canResolve(key: lookupKey) ?? false
        }
    }

    private func buildMissingDependencyMessage(for requirement: Requirement, isLocal: Bool) -> String {
        let typeId = requirement.key.typeId
        var keyedRegistrations: [String] = []
        var hasNonKeyed = false

        // Check local metadata
        for (key, meta) in metadata {
            if key.typeId == typeId, meta.isLocal == isLocal {
                if key.isKeyed, let desc = meta.keyDescription {
                    keyedRegistrations.append(desc)
                } else {
                    hasNonKeyed = true
                }
            }
        }

        // Check parent (only for non-local)
        if !isLocal, let parent {
            keyedRegistrations.append(contentsOf: parent.findKeyedRegistrations(for: typeId))
            if parent.hasNonKeyedRegistration(for: typeId) {
                hasNonKeyed = true
            }
        }

        let localPrefix = isLocal ? "Local " : ""
        var message = "\(localPrefix)\(requirement.description)"

        var availableRegistrations: [String] = []
        if hasNonKeyed {
            availableRegistrations.append("(no key)")
        }
        availableRegistrations.append(contentsOf: keyedRegistrations)

        if !availableRegistrations.isEmpty {
            let registrations = availableRegistrations.joined(separator: ", ")
            message += ". Available registrations: \(registrations)"
        }

        return message
    }
}

// MARK: - Root Builder Extension

extension DependencyBuilder where Marker == GraphRoot {
    /// Freezes a root builder into an immutable container.
    public func freeze() -> DependencyContainer<GraphRoot> {
        freeze(
            requirements: [],
            mainActorRequirements: [],
            localRequirements: [],
            localMainActorRequirements: [],
            inputRequirements: []
        )
    }
}

// MARK: - MainActor Registrar

/// Namespace for MainActor-isolated dependency registration.
@MainActor
public struct MainActorRegistrar<Marker> {
    private let builder: DependencyBuilder<Marker>

    init(builder: DependencyBuilder<Marker>) {
        self.builder = builder
    }

    // MARK: - Type-Only Registration

    public func registerInstance<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerMainActor(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerMainActor(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerMainActorScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Keyed Registration

    public func registerInstance<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerMainActor(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerMainActor(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerMainActorScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }
}

// MARK: - Local Registrar

/// Namespace for local (non-inherited) dependency registration.
/// Local factories receive `DependencyContainer<Marker>` for typed access to dependencies.
@MainActor
public struct LocalRegistrar<Marker> {
    private let builder: DependencyBuilder<Marker>

    init(builder: DependencyBuilder<Marker>) {
        self.builder = builder
    }

    /// Access MainActor-isolated local registrations.
    public var mainActor: LocalMainActorRegistrar<Marker> {
        LocalMainActorRegistrar(builder: builder)
    }

    // MARK: - Type-Only Registration

    public func registerInstance<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocal(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocal(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T: Sendable>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Keyed Registration

    public func registerInstance<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocal(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocal(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }
}

// MARK: - Local MainActor Registrar

/// Namespace for local MainActor-isolated dependency registration.
/// Local factories receive `DependencyContainer<Marker>` for typed access to dependencies.
@MainActor
public struct LocalMainActorRegistrar<Marker> {
    private let builder: DependencyBuilder<Marker>

    init(builder: DependencyBuilder<Marker>) {
        self.builder = builder
    }

    // MARK: - Type-Only Registration

    public func registerInstance<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalMainActor(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalMainActor(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T>(
        _ type: T.Type,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalMainActorScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Keyed Registration

    public func registerInstance<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalMainActor(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalMainActor(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        override: Bool = false,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (DependencyContainer<Marker>) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = { anyContainer in
            try factory(anyContainer.typed(DependencyContainer<Marker>.self))
        }
        try builder.registerLocalMainActorScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: override,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }
}
