//
//  ModuleLogger.swift
//  WatchlistDomain
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.WatchlistDomain"
)
