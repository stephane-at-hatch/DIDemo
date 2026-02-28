//
//  ModuleLogger.swift
//  ShareComponent
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Component.ShareComponent"
)
