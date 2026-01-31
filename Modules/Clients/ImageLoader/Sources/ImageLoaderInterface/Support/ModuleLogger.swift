//
//  ModuleLogger.swift
//  ImageLoaderInterface
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.ImageLoaderInterface"
)
