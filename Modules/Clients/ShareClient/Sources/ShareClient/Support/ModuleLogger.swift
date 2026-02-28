//
//  ModuleLogger.swift
//  ShareClient
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.ShareClient"
)
