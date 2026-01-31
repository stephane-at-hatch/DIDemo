//
//  ModuleLogger.swift
//  UIComponents
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Utility.UIComponents"
)
