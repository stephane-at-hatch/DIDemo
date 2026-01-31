//
//  ModuleLogger.swift
//  SharedUI
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Utility.SharedUI"
)
