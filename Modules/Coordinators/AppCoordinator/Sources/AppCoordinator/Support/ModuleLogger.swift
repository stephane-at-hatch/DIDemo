//
//  ModuleLogger.swift
//  AppCoordinator
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Coordinator.AppCoordinator"
)
