//
//  ModuleLogger.swift
//  TMDBClientInterface
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.TMDBClientInterface"
)
