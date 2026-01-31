//
//  ModuleLogger.swift
//  UIComponents
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Utility.UIComponents"
)
