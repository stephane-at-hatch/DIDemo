//
//  Plugin.swift
//
//  Created by Stephane Magne
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DependencyAccessorsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DependencyRequirementsMacro.self
    ]
}
