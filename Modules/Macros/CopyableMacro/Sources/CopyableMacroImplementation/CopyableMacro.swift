import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CopyableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure this is a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.notAStruct
        }

        // Determine access level
        let accessLevel = structDecl.modifiers.first { modifier in
            ["public", "private", "fileprivate", "internal"].contains(modifier.name.text)
        }?.name.text ?? "internal"

        // Extract all stored properties
        let properties = structDecl.memberBlock.members.compactMap { member -> PropertyInfo? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindings.count == 1,
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                  let type = binding.typeAnnotation?.type else {
                return nil
            }

            // Skip computed properties
            if binding.accessorBlock != nil {
                return nil
            }

            let isOptional = type.is(OptionalTypeSyntax.self)

            return PropertyInfo(
                name: identifier.text,
                type: type.description.trimmingCharacters(in: .whitespaces),
                isOptional: isOptional
            )
        }

        guard !properties.isEmpty else {
            return []
        }

        // Generate copy method
        let copyDecl = try generateCopy(properties: properties, structName: structDecl.name.text, accessLevel: accessLevel)

        return [copyDecl]
    }

    private static func generateCopy(properties: [PropertyInfo], structName: String, accessLevel: String) throws -> DeclSyntax {
        let parameters = properties
            .map { property -> String in
                if property.isOptional {
                    // For optional properties, use triple optional with .some(nil) sentinel.
                    // This distinguishes between:
                    // - Default (keep existing): .some(nil) sentinel
                    // - Explicit nil literal: .none
                    // - Variable containing nil: .some(.some(.none)) — promoted twice
                    return "    \(property.name): \(property.type)?? = .some(nil)"
                } else {
                    // For non-optional properties, use single optional
                    return "    \(property.name): \(property.type)? = nil"
                }
            }
            .joined(separator: ",\n")

        let arguments = properties
            .map { property -> String in
                if property.isOptional {
                    // For optional properties: .some(nil) means keep, anything else double-unwraps
                    return "        \(property.name): \(property.name) == .some(nil) ? self.\(property.name) : ((\(property.name) ?? nil) ?? nil)"
                } else {
                    // For non-optional properties: nil means keep
                    return "        \(property.name): \(property.name) ?? self.\(property.name)"
                }
            }
            .joined(separator: ",\n")

        let accessModifier = accessLevel == "internal" ? "" : "\(accessLevel) "

        return """
        \(raw: accessModifier)func copy(
        \(raw: parameters)
        ) -> \(raw: structName) {
            \(raw: structName)(
        \(raw: arguments)
            )
        }
        """
    }
}

struct PropertyInfo {
    let name: String
    let type: String
    let isOptional: Bool
}

enum MacroError: Error, CustomStringConvertible {
    case notAStruct

    var description: String {
        switch self {
        case .notAStruct:
            "@ViewState can only be applied to structs"
        }
    }
}
