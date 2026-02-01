//
//  DependencyContainer.swift
//  Modules
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - Dependency Container (Frozen, Immutable)

public struct DependencyContainer<Marker>: Sendable {
    // MARK: - Inherited Storage (copied to children via buildChild)

    let factories: [RegistrationKey: Factory]
    let scopedFactories: [RegistrationKey: Factory]
    let mainActorFactories: [RegistrationKey: MainActorFactory]
    let mainActorScopedFactories: [RegistrationKey: MainActorFactory]

    // MARK: - Local Storage (NOT copied to children, but preserved in newScope)

    let localFactories: [RegistrationKey: Factory]
    let localScopedFactories: [RegistrationKey: Factory]
    let localMainActorFactories: [RegistrationKey: MainActorFactory]
    let localMainActorScopedFactories: [RegistrationKey: MainActorFactory]

    // MARK: - Shared Storage

    let metadata: [RegistrationKey: RegistrationMetadata]
    let inputs: [ObjectIdentifier: any Sendable]
    let inputMetadata: [ObjectIdentifier: InputMetadata]
    let parent: AnyFrozenContainer?

    // MARK: - Caches

    let scopedCache: ScopedCache
    let mainActorScopedCache: MainActorAnyScopedCache
    let localScopedCache: ScopedCache
    let localMainActorScopedCache: MainActorAnyScopedCache

    // No public initializer—only created by Builder.freeze()
    init(
        factories: [RegistrationKey: Factory],
        scopedFactories: [RegistrationKey: Factory],
        mainActorFactories: [RegistrationKey: MainActorFactory],
        mainActorScopedFactories: [RegistrationKey: MainActorFactory],
        localFactories: [RegistrationKey: Factory],
        localScopedFactories: [RegistrationKey: Factory],
        localMainActorFactories: [RegistrationKey: MainActorFactory],
        localMainActorScopedFactories: [RegistrationKey: MainActorFactory],
        metadata: [RegistrationKey: RegistrationMetadata],
        inputs: [ObjectIdentifier: any Sendable],
        inputMetadata: [ObjectIdentifier: InputMetadata],
        parent: AnyFrozenContainer?
    ) {
        self.factories = factories
        self.scopedFactories = scopedFactories
        self.mainActorFactories = mainActorFactories
        self.mainActorScopedFactories = mainActorScopedFactories
        self.localFactories = localFactories
        self.localScopedFactories = localScopedFactories
        self.localMainActorFactories = localMainActorFactories
        self.localMainActorScopedFactories = localMainActorScopedFactories
        self.metadata = metadata
        self.inputs = inputs
        self.inputMetadata = inputMetadata
        self.parent = parent
        self.scopedCache = ScopedCache()
        self.mainActorScopedCache = MainActorAnyScopedCache()
        self.localScopedCache = ScopedCache()
        self.localMainActorScopedCache = MainActorAnyScopedCache()
    }

    // MARK: - Resolution (Public API)

    public func resolve<T>(_ type: T.Type) throws -> T {
        let key = RegistrationKey(type: type)
        return try resolve(key: key, type: type, keyDescription: nil)
    }

    public func resolve<T, Key: Hashable>(_ type: T.Type, key: Key) throws -> T {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        return try resolve(key: registrationKey, type: type, keyDescription: keyDescription)
    }

    public func resolveInput<T>(_ type: T.Type) throws -> T {
        let key = ObjectIdentifier(type)
        guard let value = inputs[key], let typed = value as? T else {
            throw DependencyError.inputNotFound(String(describing: type))
        }
        return typed
    }

    // MARK: - MainActor Resolution (Public API)

    @MainActor
    public func resolveMainActor<T>(_ type: T.Type) throws -> T {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        return try resolveMainActor(key: key, type: type, keyDescription: nil)
    }

    @MainActor
    public func resolveMainActor<T, Key: Hashable>(_ type: T.Type, key: Key) throws -> T {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        return try resolveMainActor(key: registrationKey, type: type, keyDescription: keyDescription)
    }

    // MARK: - Resolution (Internal)

    private func resolve<T>(key: RegistrationKey, type: T.Type, keyDescription: String?) throws -> T {
        do {
            let resolved = try resolveAny(key: key)

            guard let typed = resolved as? T else {
                throw DependencyError.resolutionFailed(
                    "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
                )
            }
            return typed
        } catch DependencyError.resolutionFailed {
            // Enrich the error message with type information if it's a generic "not found" error
            throw DependencyError.resolutionFailed(
                buildResolutionErrorMessage(for: key, typeDescription: String(describing: T.self))
            )
        }
    }

    private func resolveAny(key: RegistrationKey) throws -> any Sendable {
        // 1. Check LOCAL transient/singleton factories first
        if let factory = localFactories[key] {
            return try factory.resolve(in: AnyFrozenContainer(self))
        }

        // 2. Check LOCAL scoped factories (with caching)
        if let factory = localScopedFactories[key] {
            return try localScopedCache.getOrCreate(key: key) {
                try factory.resolve(in: AnyFrozenContainer(self))
            }
        }

        // 3. Check INHERITED transient/singleton factories
        if let factory = factories[key] {
            return try factory.resolve(in: AnyFrozenContainer(self))
        }

        // 4. Check INHERITED scoped factories (with caching)
        if let factory = scopedFactories[key] {
            return try scopedCache.getOrCreate(key: key) {
                try factory.resolve(in: AnyFrozenContainer(self))
            }
        }

        // 5. Walk up parent chain (parent only has inherited factories visible)
        if let parent {
            return try parent.resolveErased(key: key)
        }

        // 6. Not found
        throw DependencyError.resolutionFailed(buildResolutionErrorMessage(for: key))
    }

    // MARK: - MainActor Resolution (Internal)

    @MainActor
    private func resolveMainActor<T>(key: RegistrationKey, type: T.Type, keyDescription: String?) throws -> T {
        do {
            let resolved = try resolveMainActorAny(key: key)

            guard let typed = resolved as? T else {
                throw DependencyError.resolutionFailed(
                    "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
                )
            }
            return typed
        } catch DependencyError.resolutionFailed {
            throw DependencyError.resolutionFailed(
                buildResolutionErrorMessage(for: key, typeDescription: String(describing: T.self))
            )
        }
    }

    @MainActor
    private func resolveMainActorAny(key: RegistrationKey) throws -> Any {
        // 1. Check LOCAL MainActor transient/singleton factories first
        if let factory = localMainActorFactories[key] {
            return try factory.resolve(in: AnyFrozenContainer(self))
        }

        // 2. Check LOCAL MainActor scoped factories (with caching)
        if let factory = localMainActorScopedFactories[key] {
            return try localMainActorScopedCache.getOrCreate(key: key) {
                try factory.resolve(in: AnyFrozenContainer(self))
            }
        }

        // 3. Check INHERITED MainActor transient/singleton factories
        if let factory = mainActorFactories[key] {
            return try factory.resolve(in: AnyFrozenContainer(self))
        }

        // 4. Check INHERITED MainActor scoped factories (with caching)
        if let factory = mainActorScopedFactories[key] {
            return try mainActorScopedCache.getOrCreate(key: key) {
                try factory.resolve(in: AnyFrozenContainer(self))
            }
        }

        // 5. Walk up parent chain (parent only has inherited factories visible)
        if let parent {
            return try parent.resolveMainActorErased(key: key)
        }

        // 6. Not found
        throw DependencyError.resolutionFailed(buildResolutionErrorMessage(for: key))
    }

    // MARK: - Child Building

    @MainActor
    public func buildChild<T: DependencyRequirements>(_ type: T.Type) -> T {
        // Note: Child only inherits non-local factories through AnyFrozenContainer
        let builder = DependencyBuilder<T>(parent: AnyFrozenContainer(self), inputs: inputs)

        T.registerDependencies(in: builder)

        let childContainer = builder.freeze(
            requirements: T.requirements,
            mainActorRequirements: T.mainActorRequirements,
            localRequirements: T.localRequirements,
            localMainActorRequirements: T.localMainActorRequirements,
            inputRequirements: T.inputRequirements
        )

        return T(childContainer)
    }

    /// Builds a child with a configuration closure for providing inputs.
    @MainActor
    public func buildChild<T: DependencyRequirements>(
        _ type: T.Type,
        configure: @MainActor (DependencyBuilder<T>) -> Void
    ) -> T {
        let builder = DependencyBuilder<T>(parent: AnyFrozenContainer(self), inputs: inputs)

        configure(builder)
        T.registerDependencies(in: builder)

        let childContainer = builder.freeze(
            requirements: T.requirements,
            mainActorRequirements: T.mainActorRequirements,
            localRequirements: T.localRequirements,
            localMainActorRequirements: T.localMainActorRequirements,
            inputRequirements: T.inputRequirements
        )

        return T(childContainer)
    }

    /// Creates a new scope - preserves ALL factories (including local) but resets scoped caches.
    @MainActor
    public func newScope() -> DependencyContainer<Marker> {
        DependencyContainer(
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

    // MARK: - Helpers (for type erasure)

    func resolveErased(key: RegistrationKey) throws -> any Sendable {
        try resolveAny(key: key)
    }

    @MainActor
    func resolveMainActorErased(key: RegistrationKey) throws -> Any {
        try resolveMainActorAny(key: key)
    }

    /// Checks if a dependency can be resolved (used by parent lookups).
    /// Note: Only checks INHERITED factories - local factories are not visible to children.
    func canResolve(key: RegistrationKey) -> Bool {
        if factories[key] != nil { return true }
        if scopedFactories[key] != nil { return true }
        if mainActorFactories[key] != nil { return true }
        if mainActorScopedFactories[key] != nil { return true }
        return parent?.canResolve(key: key) ?? false
    }

    func findKeyedRegistrations(for typeId: ObjectIdentifier) -> [String] {
        var descriptions: [String] = []

        for (key, meta) in metadata {
            if key.typeId == typeId, key.isKeyed, let desc = meta.keyDescription {
                descriptions.append(desc)
            }
        }

        if let parent {
            descriptions.append(contentsOf: parent.findKeyedRegistrations(for: typeId))
        }

        return descriptions
    }

    func hasNonKeyedRegistration(for typeId: ObjectIdentifier) -> Bool {
        let hasLocal = factories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || scopedFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || mainActorFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || mainActorScopedFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || localFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || localScopedFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || localMainActorFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }
            || localMainActorScopedFactories.keys.contains { $0.typeId == typeId && !$0.isKeyed }

        if hasLocal { return true }
        return parent?.hasNonKeyedRegistration(for: typeId) ?? false
    }

    // MARK: - Diagnostics

    public func diagnose() -> String {
        diagnose(level: 0)
    }

    func diagnose(level: Int) -> String {
        var output = ""
        let indent = String(repeating: "  ", count: level)

        if let parent {
            output += parent.diagnose(level: level)
        }

        let markerName = Self.fullyQualifiedTypeName(Marker.self)
        output += "\n\(indent)▶︎ \(markerName) Container\n"

        let allMetadata = metadata.sorted { $0.value.line < $1.value.line }

        for (_, meta) in allMetadata {
            let fileName = URL(fileURLWithPath: meta.file).lastPathComponent
            let keyPart = meta.keyDescription.map { "(key: \($0)) " } ?? ""
            let localPart = meta.isLocal ? "[local] " : ""
            output += "\(indent)  ├─ \(meta.scope.rawValue): \(localPart)\(meta.typeDescription) \(keyPart)@ \(fileName):\(meta.line)\n"
        }

        let allInputMetadata = inputMetadata.sorted { $0.value.line < $1.value.line }

        for (_, inputMeta) in allInputMetadata {
            let fileName = URL(fileURLWithPath: inputMeta.file).lastPathComponent
            output += "\(indent)  ├─ input: \(inputMeta.typeDescription) @ \(fileName):\(inputMeta.line)\n"
        }

        return output
    }

    // MARK: - Helpers (for diagnostics)

    /// Returns the fully qualified type name, stripping the module prefix.
    /// For example: `MyModule.Dependencies` instead of just `Dependencies`.
    private static func fullyQualifiedTypeName(_ type: Any.Type) -> String {
        // _typeName gives us something like "ModuleName.ParentType.NestedType"
        let fullName = _typeName(type, qualified: true)

        // Strip the module name (first component) if present
        if let dotIndex = fullName.firstIndex(of: ".") {
            let afterModule = fullName[fullName.index(after: dotIndex)...]
            // Only return the shortened version if there's still meaningful content
            if !afterModule.isEmpty {
                return String(afterModule)
            }
        }

        return fullName
    }

    // Two overloads of buildResolutionErrorMessage
    private func buildResolutionErrorMessage(for key: RegistrationKey) -> String {
        buildResolutionErrorMessage(for: key, typeDescription: nil)
    }

    private func buildResolutionErrorMessage(for key: RegistrationKey, typeDescription: String?) -> String {
        let typeId = key.typeId
        let keyedRegistrations = findKeyedRegistrations(for: typeId)
        let hasNonKeyed = hasNonKeyedRegistration(for: typeId)

        let keyDesc = key.isKeyed ? "keyed" : "nil"
        let typePart = typeDescription ?? "unknown type"
        var message = "No registration found for \(typePart) (key: \(keyDesc))."

        var available: [String] = []
        if hasNonKeyed { available.append("(no key)") }
        available.append(contentsOf: keyedRegistrations)

        if !available.isEmpty {
            let count = available.count
            message += " However, there \(count == 1 ? "is" : "are") \(count) registration\(count == 1 ? "" : "s"): \(available.joined(separator: ", "))"
        }

        return message
    }
}

// MARK: - App Root Marker

public enum AppRoot {}
