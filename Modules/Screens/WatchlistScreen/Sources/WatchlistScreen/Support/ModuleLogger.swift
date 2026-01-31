//
//  ModuleLogger.swift
//  WatchlistScreen
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Screen.WatchlistScreen"
)
