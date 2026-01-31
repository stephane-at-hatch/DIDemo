//
//  ModuleLogger.swift
//  TMDBClientInterface
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.TMDBClientInterface"
)
