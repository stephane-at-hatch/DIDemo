//
//  Plugin.swift
//
//  Created by Stephane Magne
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DependencyAccessorsPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        DependencyRequirementsMacro.self
    ]
}
