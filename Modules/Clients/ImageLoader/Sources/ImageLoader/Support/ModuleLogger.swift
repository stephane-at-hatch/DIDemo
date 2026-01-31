//
//  ModuleLogger.swift
//  ImageLoader
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.ImageLoader"
)
