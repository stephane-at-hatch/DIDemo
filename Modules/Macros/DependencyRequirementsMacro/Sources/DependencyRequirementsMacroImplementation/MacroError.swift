//
//  MacroError.swift
//  DependencyAccessors
//
//  Created by Stephane Magne
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum MacroError: Error, CustomStringConvertible {
    case message(String)

    public var description: String {
        switch self {
        case .message(let msg): msg
        }
    }
}

extension MacroError: DiagnosticMessage {
    public var severity: SwiftDiagnostics.DiagnosticSeverity {
        .error
    }

    public var message: String {
        description
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "DependencyAccessorsMacros", id: "MacroError")
    }
}

extension MacroExpansionContext {
    public func diagnose(_ error: MacroError, node: some SyntaxProtocol) {
        diagnose(
            Diagnostic(node: Syntax(node), message: error)
        )
    }
}
