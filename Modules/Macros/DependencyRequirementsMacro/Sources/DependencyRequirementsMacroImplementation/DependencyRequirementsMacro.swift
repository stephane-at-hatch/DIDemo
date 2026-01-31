import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DependencyRequirementInfo {
    public let typeExpr: String // e.g. "AnalyticsClient.self" or "(any RoutineCoordinating).self"
    public let valueType: String // e.g. "AnalyticsClient" or "any RoutineCoordinating"
    public let keyExpr: String? // e.g. "AnalyticsClientKeys.amplitude" or nil
    public let accessorName: String? // e.g. "testClient" from `as: "testClient"`
    public let isOptional: Bool
    public let isMainActor: Bool // true if this dependency is @MainActor isolated
    public let isLocal: Bool // true if this is a local (non-inherited) dependency
}

public struct InputRequirementInfo {
    public let typeExpr: String // e.g. "LoggerConfiguration.self"
    public let valueType: String // e.g. "LoggerConfiguration"
}

public struct DependencyRequirementsMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Attach only to structs like `ModuleADependencies`
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.message("@DependencyRequirements may only be applied to structs.")
        }

        let typeName = structDecl.name.text

        // Parse arguments: @DependencyRequirements([...], mainActor: [...], local: [...], localMainActor: [...], inputs: [...])
        var requirementsArrayExpr: ArrayExprSyntax?
        var mainActorArrayExpr: ArrayExprSyntax?
        var localArrayExpr: ArrayExprSyntax?
        var localMainActorArrayExpr: ArrayExprSyntax?
        var inputsArrayExpr: ArrayExprSyntax?

        if let args = attribute.arguments?.as(LabeledExprListSyntax.self) {
            for arg in args {
                if arg.label == nil {
                    // First unlabeled argument is requirements
                    if let array = arg.expression.as(ArrayExprSyntax.self) {
                        requirementsArrayExpr = array
                    }
                } else if arg.label?.text == "mainActor" {
                    if let array = arg.expression.as(ArrayExprSyntax.self) {
                        mainActorArrayExpr = array
                    }
                } else if arg.label?.text == "local" {
                    if let array = arg.expression.as(ArrayExprSyntax.self) {
                        localArrayExpr = array
                    }
                } else if arg.label?.text == "localMainActor" {
                    if let array = arg.expression.as(ArrayExprSyntax.self) {
                        localMainActorArrayExpr = array
                    }
                } else if arg.label?.text == "inputs" {
                    if let array = arg.expression.as(ArrayExprSyntax.self) {
                        inputsArrayExpr = array
                    }
                }
            }
        }

        // Parse all Requirement(...) calls
        var dependencyInfos: [DependencyRequirementInfo] = []

        // Regular (inherited, non-MainActor)
        if let arrayExpr = requirementsArrayExpr {
            for element in arrayExpr.elements {
                if let info = parseRequirement(from: element, isMainActor: false, isLocal: false) {
                    dependencyInfos.append(info)
                }
            }
        }

        // MainActor (inherited)
        if let arrayExpr = mainActorArrayExpr {
            for element in arrayExpr.elements {
                if let info = parseRequirement(from: element, isMainActor: true, isLocal: false) {
                    dependencyInfos.append(info)
                }
            }
        }

        // Local (non-MainActor)
        if let arrayExpr = localArrayExpr {
            for element in arrayExpr.elements {
                if let info = parseRequirement(from: element, isMainActor: false, isLocal: true) {
                    dependencyInfos.append(info)
                }
            }
        }

        // Local MainActor
        if let arrayExpr = localMainActorArrayExpr {
            for element in arrayExpr.elements {
                if let info = parseRequirement(from: element, isMainActor: true, isLocal: true) {
                    dependencyInfos.append(info)
                }
            }
        }

        // Parse InputRequirement(...) calls
        var inputInfos: [InputRequirementInfo] = []

        if let arrayExpr = inputsArrayExpr {
            for element in arrayExpr.elements {
                guard let call = element.expression.as(FunctionCallExprSyntax.self) else { continue }
                guard call.calledExpression.trimmedDescription == "InputRequirement" else { continue }

                guard let typeArg = call.arguments.first else { continue }

                guard let member = typeArg.expression.as(MemberAccessExprSyntax.self),
                      member.declName.baseName.text == "self",
                      let base = member.base
                else { continue }

                let typeExpr = member.trimmedDescription
                let valueType = valueTypeString(from: base)

                inputInfos.append(
                    InputRequirementInfo(
                        typeExpr: typeExpr,
                        valueType: valueType
                    )
                )
            }
        }

        // Match struct visibility for public API bits
        let visibilityToken = structDecl.modifiers.first { modifier in
            let name = modifier.name.text
            return ["public", "internal", "fileprivate", "private", "package"].contains(name)
        }
        let vis = visibilityToken.map { $0.name.text + " " } ?? ""

        var members: [DeclSyntax] = []

        // 1) container property
        let containerDecl = DeclSyntax(stringLiteral:
            "let container: DependencyContainer<\(typeName)>\n"
        )
        members.append(containerDecl)

        // 2) init(_ container: DependencyContainer<Self>)
        let initSource = """
        \(vis)init(_ container: DependencyContainer<\(typeName)>) {
            self.container = container
        }
        """
        members.append(DeclSyntax(stringLiteral: initSource))

        // 3) static requirements: [Requirement]
        var reqBody = "\(vis)static let requirements: [Requirement] = [\n"
        if let arrayExpr = requirementsArrayExpr {
            for element in arrayExpr.elements {
                let exprSrc = element.expression.trimmedDescription
                reqBody += "    \(exprSrc),\n"
            }
        }
        reqBody += "]\n"
        members.append(DeclSyntax(stringLiteral: reqBody))

        // 4) static mainActorRequirements: [Requirement]
        let hasMainActorRequirements = mainActorArrayExpr?.elements.isEmpty == false
        if hasMainActorRequirements {
            var mainActorReqBody = "\(vis)static let mainActorRequirements: [Requirement] = [\n"
            if let arrayExpr = mainActorArrayExpr {
                for element in arrayExpr.elements {
                    let exprSrc = element.expression.trimmedDescription
                    mainActorReqBody += "    \(exprSrc),\n"
                }
            }
            mainActorReqBody += "]\n"
            members.append(DeclSyntax(stringLiteral: mainActorReqBody))
        }

        // 5) static localRequirements: [Requirement]
        let hasLocalRequirements = localArrayExpr?.elements.isEmpty == false
        if hasLocalRequirements {
            var localReqBody = "\(vis)static let localRequirements: [Requirement] = [\n"
            if let arrayExpr = localArrayExpr {
                for element in arrayExpr.elements {
                    let exprSrc = element.expression.trimmedDescription
                    localReqBody += "    \(exprSrc),\n"
                }
            }
            localReqBody += "]\n"
            members.append(DeclSyntax(stringLiteral: localReqBody))
        }

        // 6) static localMainActorRequirements: [Requirement]
        let hasLocalMainActorRequirements = localMainActorArrayExpr?.elements.isEmpty == false
        if hasLocalMainActorRequirements {
            var localMainActorReqBody = "\(vis)static let localMainActorRequirements: [Requirement] = [\n"
            if let arrayExpr = localMainActorArrayExpr {
                for element in arrayExpr.elements {
                    let exprSrc = element.expression.trimmedDescription
                    localMainActorReqBody += "    \(exprSrc),\n"
                }
            }
            localMainActorReqBody += "]\n"
            members.append(DeclSyntax(stringLiteral: localMainActorReqBody))
        }

        // 7) static inputRequirements: [InputRequirement]
        if !inputInfos.isEmpty {
            var inputReqBody = "\(vis)static let inputRequirements: [InputRequirement] = [\n"
            if let arrayExpr = inputsArrayExpr {
                for element in arrayExpr.elements {
                    let exprSrc = element.expression.trimmedDescription
                    inputReqBody += "    \(exprSrc),\n"
                }
            }
            inputReqBody += "]\n"
            members.append(DeclSyntax(stringLiteral: inputReqBody))
        }

        // 8) buildChild<T: DependencyRequirements>(_:) -> T
        let buildChildSource = """
        @MainActor
        \(vis)func buildChild<T: DependencyRequirements>(_ dependencyType: T.Type) -> T {
            container.buildChild(dependencyType)
        }
        """
        members.append(DeclSyntax(stringLiteral: buildChildSource))

        // 9) buildChild<T: DependencyRequirements>(_:configure:) -> T
        let buildChildConfigureSource = """
        @MainActor
        \(vis)func buildChild<T: DependencyRequirements>(
            _ dependencyType: T.Type,
            configure: @MainActor (DependencyBuilder<T>) -> Void
        ) -> T {
            container.buildChild(dependencyType, configure: configure)
        }
        """
        members.append(DeclSyntax(stringLiteral: buildChildConfigureSource))

        // 10) convenience accessors for dependencies
        var accessorsBody = ""

        for info in dependencyInfos {
            let valueType = info.valueType
            let typeExpr = info.typeExpr
            let keyExpr = info.keyExpr
            let isOptional = info.isOptional
            let isMainActor = info.isMainActor

            let propertyName: String

            // Derive base type name (used for both keyed and non-keyed)
            let baseTypeName: String = {
                if valueType.hasPrefix("any ") {
                    // "any RoutineCoordinating" -> "RoutineCoordinating"
                    return String(valueType.dropFirst("any ".count))
                }
                return valueType
            }()
            // Strip dots for nested types: "DeviceStateEmitterClient.Factory" -> "DeviceStateEmitterClientFactory"
            let typeSuffix = stripRedundantPrefix(from: baseTypeName).replacingOccurrences(of: ".", with: "")

            if let accessorName = info.accessorName {
                // Explicit alias provided via `accessorName:`
                propertyName = accessorName
            } else if let keyExpression = keyExpr {
                // If a key is provided, combine key name with type name
                // e.g., key: AnalyticsKey.statsig + AnalyticsClient.self -> statsigAnalyticsClient
                let keyName = String(keyExpression.split(separator: ".").last ?? "")
                propertyName = lowerFirst(keyName) + typeSuffix
            } else {
                // No key provided, derive name from the type alone
                propertyName = lowerFirst(typeSuffix)
            }

            let propertyType = isOptional ? "\(valueType)?" : valueType

            // Choose resolve method based on MainActor isolation
            // Note: Local dependencies use the same resolve methods - the container handles local-first lookup
            let resolveMethod = isMainActor ? "resolveMainActor" : "resolve"
            let mainActorAttr = isMainActor ? "@MainActor " : ""

            if isOptional {
                // Optional dependencies use try? with direct return
                if let keyExpr {
                    accessorsBody += """
                    \(mainActorAttr)var \(propertyName): \(propertyType) {
                        try? container.\(resolveMethod)(\(typeExpr), key: \(keyExpr))
                    }

                    """
                } else {
                    accessorsBody += """
                    \(mainActorAttr)var \(propertyName): \(propertyType) {
                        try? container.\(resolveMethod)(\(typeExpr))
                    }

                    """
                }
            } else {
                // Required dependencies use guard let + preconditionFailure for better error messages
                if let keyExpr {
                    accessorsBody += """
                    \(mainActorAttr)var \(propertyName): \(propertyType) {
                        guard let \(propertyName) = try? container.\(resolveMethod)(\(typeExpr), key: \(keyExpr)) else {
                            preconditionFailure("Could not resolve dependency \(valueType) with key \(keyExpr)")
                        }
                        return \(propertyName)
                    }

                    """
                } else {
                    accessorsBody += """
                    \(mainActorAttr)var \(propertyName): \(propertyType) {
                        guard let \(propertyName) = try? container.\(resolveMethod)(\(typeExpr)) else {
                            preconditionFailure("Could not resolve dependency \(valueType)")
                        }
                        return \(propertyName)
                    }

                    """
                }
            }
        }

        // 11) convenience accessors for inputs
        for info in inputInfos {
            let valueType = info.valueType
            let typeExpr = info.typeExpr

            let baseNameForSuffix: String = {
                if valueType.hasPrefix("any ") {
                    return String(valueType.dropFirst("any ".count))
                }
                return valueType
            }()

            let suffix = stripRedundantPrefix(from: baseNameForSuffix)
            let propertyName = lowerFirst(suffix)

            accessorsBody += """
            var \(propertyName): \(valueType) {
                guard let \(propertyName) = try? container.resolveInput(\(typeExpr)) else {
                    preconditionFailure("Could not resolve input \(valueType)")
                }
                return \(propertyName)
            }

            """
        }

        members.append(DeclSyntax(stringLiteral: accessorsBody))

        return members
    }
}

// MARK: - Helpers

private func parseRequirement(from element: ArrayElementSyntax, isMainActor: Bool, isLocal: Bool) -> DependencyRequirementInfo? {
    guard let call = element.expression.as(FunctionCallExprSyntax.self) else { return nil }
    guard call.calledExpression.trimmedDescription == "Requirement" else { return nil }

    // Arg 1: type, e.g. `ContentClient.self`
    // It can be labeled `optional:` or not
    guard let typeArg = call.arguments.first else { return nil }

    let isOptional = typeArg.label?.text == "optional"

    guard let member = typeArg.expression.as(MemberAccessExprSyntax.self),
          member.declName.baseName.text == "self",
          let base = member.base
    else { return nil }

    let typeExpr = member.trimmedDescription // "AnalyticsClient.self" or "(any RoutineCoordinating).self"
    let valueType = valueTypeString(from: base) // "AnalyticsClient" or "any RoutineCoordinating"

    // Arg 2: key (optional)
    let keyArg = call.arguments.dropFirst().first { $0.label?.text == "key" }
    let keyExpr = keyArg.map { $0.expression.trimmedDescription }

    // Arg 3: as (optional accessor name alias)
    let asArg = call.arguments.first { $0.label?.text == "accessorName" }
    let accessorName: String? = asArg.flatMap { arg in
        // Extract string literal content from `accessorName: "testClient"`
        if let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
           let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
            return segment.content.text
        }
        return nil
    }

    return DependencyRequirementInfo(
        typeExpr: typeExpr,
        valueType: valueType,
        keyExpr: keyExpr,
        accessorName: accessorName,
        isOptional: isOptional,
        isMainActor: isMainActor,
        isLocal: isLocal
    )
}

private func stripRedundantPrefix(from typeName: String) -> String {
    // strip once if present
    let prefixes = ["Hatch"]
    for prefix in prefixes where typeName.hasPrefix(prefix) {
        let dropped = String(typeName.dropFirst(prefix.count))
        return dropped.isEmpty ? typeName : dropped
    }
    return typeName
}

private func lowerFirst(_ s: String) -> String {
    guard let first = s.first else { return s }
    return String(first).lowercased() + s.dropFirst()
}

private func valueTypeString(from base: some SyntaxProtocol) -> String {
    let text = base.trimmedDescription // "AnalyticsClient" or "(any RoutineCoordinating)"
    if text.hasPrefix("(any "), text.hasSuffix(")") {
        // "(any RoutineCoordinating)" -> "any RoutineCoordinating"
        let inner = text.dropFirst("(".count).dropLast(")".count)
        return String(inner)
    }
    return text
}
