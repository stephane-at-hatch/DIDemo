//
//  DependencyBuilder.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne on 2026-01-05.
//

import Foundation

@MainActor
public enum RootDependencyBuilder {
    public static func buildChild<T: DependencyRequirements>(_ type: T.Type) -> T {
        let dependencyBuilder = DependencyBuilder<AppRoot>()
        let dependencyContainer = dependencyBuilder.freeze()
        return dependencyContainer.buildChild(T.self)
    }
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
    private var inputs: [ObjectIdentifier: any Sendable]
    private var inputMetadata: [ObjectIdentifier: InputMetadata] = [:]
    private let parent: AnyFrozenContainer?

    // MARK: - Namespace Accessors

    public var mainActor: MainActorRegistrar<Marker> {
        MainActorRegistrar(builder: self)
    }

    public var local: LocalRegistrar<Marker> {
        LocalRegistrar(builder: self)
    }

    // MARK: - Initialization

    /// Creates a root builder (no parent).
    public init() where Marker == AppRoot {
        self.parent = nil
        self.inputs = [:]
    }

    /// Creates a child builder with a frozen parent.
    public init(parent: AnyFrozenContainer, inputs: [ObjectIdentifier: any Sendable] = [:]) {
        self.parent = parent
        self.inputs = inputs
    }

    // MARK: - Input Management

    public func provideInput<T: Sendable>(
        _ type: T.Type,
        _ value: T,
        file: String = #file,
        line: Int = #line
    ) {
        let key = ObjectIdentifier(type)
        inputs[key] = value
        inputMetadata[key] = InputMetadata(
            typeDescription: String(describing: T.self),
            file: file,
            line: line
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

    public func registerInstance<T: Sendable, Key: Hashable>(
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

    public func registerSingleton<T: Sendable, Key: Hashable>(
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

    public func registerScoped<T: Sendable, Key: Hashable>(
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
        // Check for existing registration
        if factories[key] != nil, !override {
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
        if scopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
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
        // Check for existing registration
        if mainActorFactories[key] != nil, !override {
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
        if mainActorScopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "MainActor scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
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
        if localFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
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
        if localScopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
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
        if localMainActorFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local MainActor dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
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
        if localMainActorScopedFactories[key] != nil, !override {
            let keyDesc = keyDescription ?? "type-only"
            throw DependencyError.registrationExists(
                "Local MainActor scoped dependency \(type) with key \(keyDesc) already registered. Use override: true to replace."
            )
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

    // MARK: - Freezing

    public func freeze(
        requirements: [Requirement] = [],
        mainActorRequirements: [Requirement] = [],
        localRequirements: [Requirement] = [],
        localMainActorRequirements: [Requirement] = [],
        inputRequirements: [InputRequirement] = []
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
            parent: parent
        )
    }

    // MARK: - Validation

    private func validateInputRequirements(_ inputRequirements: [InputRequirement]) {
        let missing = inputRequirements.filter { req in
            inputs[req.typeId] == nil
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

extension DependencyBuilder where Marker == AppRoot {
    /// Freezes a root builder into an immutable container.
    public func freeze() -> DependencyContainer<AppRoot> {
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

    public func registerInstance<T, Key: Hashable>(
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

    public func registerSingleton<T, Key: Hashable>(
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

    public func registerScoped<T, Key: Hashable>(
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

    public func registerInstance<T: Sendable, Key: Hashable>(
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

    public func registerSingleton<T: Sendable, Key: Hashable>(
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

    public func registerScoped<T: Sendable, Key: Hashable>(
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

    public func registerInstance<T, Key: Hashable>(
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

    public func registerSingleton<T, Key: Hashable>(
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

    public func registerScoped<T, Key: Hashable>(
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
