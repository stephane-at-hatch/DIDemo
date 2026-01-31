//
//  ModuleLogger.swift
//  DetailScreen
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Screen.DetailScreen"
)
