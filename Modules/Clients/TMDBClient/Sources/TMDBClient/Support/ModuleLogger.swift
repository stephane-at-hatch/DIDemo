//
//  ModuleLogger.swift
//  TMDBClient
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.TMDBClient"
)
