//
//  ModuleLogger.swift
//  SharedUI
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Utility.SharedUI"
)
