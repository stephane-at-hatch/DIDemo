//
//  ModuleLogger.swift
//  ModularDependencyContainer
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Utility.ModularDependencyContainer"
)
