//
//  ModuleLogger.swift
//  TabCoordinator
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Coordinator.TabCoordinator"
)
