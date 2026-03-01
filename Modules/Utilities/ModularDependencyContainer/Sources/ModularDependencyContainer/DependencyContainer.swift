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
    let inputs: [InputKey: any Sendable]
    let inputMetadata: [InputKey: InputMetadata]
    let parent: AnyFrozenContainer?
    let mode: ContainerMode

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
        inputs: [InputKey: any Sendable],
        inputMetadata: [InputKey: InputMetadata],
        parent: AnyFrozenContainer?,
        mode: ContainerMode
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
        self.mode = mode
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

    public func resolve<T, Key: Hashable & Sendable>(_ type: T.Type, key: Key) throws -> T {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        return try resolve(key: registrationKey, type: type, keyDescription: keyDescription)
    }

    public func resolveInput<T>(_ type: T.Type) throws -> T {
        let key = InputKey(type: type)
        guard let value = inputs[key], let typed = value as? T else {
            throw DependencyError.inputNotFound(String(describing: type))
        }
        return typed
    }

    public func resolveInput<T, Key: Hashable & Sendable>(_ type: T.Type, key: Key) throws -> T {
        let inputKey = InputKey(type: type, key: key)
        guard let value = inputs[inputKey], let typed = value as? T else {
            let keyDescription = "\(String(describing: Key.self)).\(key)"
            throw DependencyError.inputNotFound("\(String(describing: type)) [key: \(keyDescription)]")
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
    public func resolveMainActor<T, Key: Hashable & Sendable>(_ type: T.Type, key: Key) throws -> T {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        return try resolveMainActor(key: registrationKey, type: type, keyDescription: keyDescription)
    }

    // MARK: - Resolution (Internal)

    private func resolve<T>(key: RegistrationKey, type: T.Type, keyDescription: String?) throws -> T {
        let resolved: any Sendable
        do {
            resolved = try resolveAny(key: key)
        } catch DependencyError.resolutionFailed {
            // Enrich the error message with type information for "not found" errors
            throw DependencyError.resolutionFailed(
                buildResolutionErrorMessage(for: key, typeDescription: String(describing: T.self))
            )
        }

        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
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

        // 5. Walk up parent chain (inherited only - excludes parent's local factories)
        if let parent {
            return try parent.resolveInheritedErased(key: key)
        }

        // 6. Not found
        throw DependencyError.resolutionFailed(buildResolutionErrorMessage(for: key))
    }

    // MARK: - MainActor Resolution (Internal)

    @MainActor
    private func resolveMainActor<T>(key: RegistrationKey, type: T.Type, keyDescription: String?) throws -> T {
        let resolved: Any
        do {
            resolved = try resolveMainActorAny(key: key)
        } catch DependencyError.resolutionFailed {
            // Enrich the error message with type information for "not found" errors
            throw DependencyError.resolutionFailed(
                buildResolutionErrorMessage(for: key, typeDescription: String(describing: T.self))
            )
        }

        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
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

        // 5. Walk up parent chain (inherited only - excludes parent's local factories)
        if let parent {
            return try parent.resolveMainActorInheritedErased(key: key)
        }

        // 6. Not found
        throw DependencyError.resolutionFailed(buildResolutionErrorMessage(for: key))
    }

    // MARK: - Child Building

    @MainActor
    public func buildChild<T: DependencyRequirements>(_ type: T.Type) -> T {
        // Note: Child only inherits non-local factories through AnyFrozenContainer
        let builder = DependencyBuilder<T>(parent: AnyFrozenContainer(self), inputs: inputs, mode: mode)

        registerForMode(type, in: builder)

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
        let builder = DependencyBuilder<T>(parent: AnyFrozenContainer(self), inputs: inputs, mode: mode)

        configure(builder)
        registerForMode(type, in: builder)

        let childContainer = builder.freeze(
            requirements: T.requirements,
            mainActorRequirements: T.mainActorRequirements,
            localRequirements: T.localRequirements,
            localMainActorRequirements: T.localMainActorRequirements,
            inputRequirements: T.inputRequirements
        )

        return T(childContainer)
    }

    /// Builds a child in testing mode, then applies test-site-specific overrides.
    ///
    /// The overrides closure runs AFTER `mockRegistration`, giving it the highest
    /// priority in the two-tier override system:
    /// 1. `testingOverride` closure (highest — test-site-specific, always takes effect)
    /// 2. Base mock registrations from `mockRegistration` (parent-wins behavior)
    ///
    /// Only available in testing mode. Asserts in production.
    ///
    /// ```swift
    /// let child = parentContainer.buildChildWithOverrides(MyModule.self) { overrides in
    ///     overrides.provideInput(String.self, "test-value")
    ///     try overrides.registerSingleton(NetworkClient.self) { _ in
    ///         FailingNetworkClient(error: .timeout)
    ///     }
    /// }
    /// ```
    @MainActor
    public func buildChildWithOverrides<T: DependencyRequirements>(
        _ type: T.Type,
        testingOverride: @MainActor (MockDependencyBuilder<T>) throws -> Void
    ) rethrows -> T {
        guard case .testing = mode else {
            assertionFailure("buildChildWithOverrides is only available in testing mode. Current mode: \(mode)")
            // Fall back to standard buildChild in release builds
            return buildChild(type)
        }

        let parentContainer = AnyFrozenContainer(self)
        let builder = DependencyBuilder<T>(parent: parentContainer, inputs: inputs, mode: mode)

        // 1. Run standard mock/production registrations (skip validation — overrides haven't run yet)
        registerForMode(type, in: builder, skipValidation: true)

        // 2. Apply test-site overrides (isOverride: true — overrides always take effect)
        let mockBuilder = MockDependencyBuilder(builder: builder, parent: parentContainer, isOverride: true)
        try testingOverride(mockBuilder)

        // 3. Validate after both mockRegistration AND overrides have completed
        if let testableType = T.self as? any TestDependencyProvider.Type {
            testableType._validateMockRegistrationsExternally(builder: builder, parent: parentContainer)
        }

        let childContainer = builder.freeze(
            requirements: T.requirements,
            mainActorRequirements: T.mainActorRequirements,
            localRequirements: T.localRequirements,
            localMainActorRequirements: T.localMainActorRequirements,
            inputRequirements: T.inputRequirements
        )

        return T(childContainer)
    }

    // MARK: - Mode-Aware Registration

    /// Calls the appropriate registration function based on the container's mode.
    /// In `.testing` mode, uses `mockRegistration` if the type conforms to `TestDependencyProvider`.
    /// Falls back to `registerDependencies` with a warning if the module hasn't adopted test support.
    @MainActor
    private func registerForMode<T: DependencyRequirements>(_ type: T.Type, in builder: DependencyBuilder<T>, skipValidation: Bool = false) {
        switch mode {
        case .production:
            T.registerDependencies(in: builder)

        case .testing:
            if let testableType = T.self as? any TestDependencyProvider.Type {
                testableType._callMockRegistration(in: builder, parent: AnyFrozenContainer(self), skipValidation: skipValidation)
            } else {
#if DEBUG
                print("⚠️ [DependencyContainer] Testing mode active but \(T.self) does not conform to TestDependencyProvider. Falling back to registerDependencies.")
#endif
                T.registerDependencies(in: builder)
            }
        }
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
            parent: parent,
            mode: mode
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

    /// Resolves inherited factories only (excludes local). Used by children walking the parent chain.
    func resolveInheritedErased(key: RegistrationKey) throws -> any Sendable {
        if let factory = factories[key] {
            return try factory.resolve(in: AnyFrozenContainer(self))
        }

        if let factory = scopedFactories[key] {
            return try scopedCache.getOrCreate(key: key) {
                try factory.resolve(in: AnyFrozenContainer(self))
            }
        }

        if let parent {
            return try parent.resolveInheritedErased(key: key)
        }

        throw DependencyError.resolutionFailed(buildResolutionErrorMessage(for: key))
    }

    /// Resolves inherited MainActor factories only (excludes local). Used by children walking the parent chain.
    @MainActor
    func resolveMainActorInheritedErased(key: RegistrationKey) throws -> Any {
        if let factory = mainActorFactories[key] {
            return try factory.resolve(in: AnyFrozenContainer(self))
        }

        if let factory = mainActorScopedFactories[key] {
            return try mainActorScopedCache.getOrCreate(key: key) {
                try factory.resolve(in: AnyFrozenContainer(self))
            }
        }

        if let parent {
            return try parent.resolveMainActorInheritedErased(key: key)
        }

        throw DependencyError.resolutionFailed(buildResolutionErrorMessage(for: key))
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

// MARK: - Graph Root Marker

public enum GraphRoot {}
