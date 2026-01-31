//
//  ModuleLogger.swift
//  AppCoordinator
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Coordinator.AppCoordinator"
)
