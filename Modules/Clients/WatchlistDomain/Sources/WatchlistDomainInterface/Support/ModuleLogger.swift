//
//  ModuleLogger.swift
//  WatchlistDomainInterface
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.WatchlistDomainInterface"
)
