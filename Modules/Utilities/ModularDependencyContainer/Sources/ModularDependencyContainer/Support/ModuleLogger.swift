//
//  ModuleLogger.swift
//  ModularDependencyContainer
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Utility.ModularDependencyContainer"
)
