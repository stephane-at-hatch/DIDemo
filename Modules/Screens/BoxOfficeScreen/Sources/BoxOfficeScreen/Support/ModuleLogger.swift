//
//  ModuleLogger.swift
//  BoxOfficeScreen
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Screen.BoxOfficeScreen"
)
