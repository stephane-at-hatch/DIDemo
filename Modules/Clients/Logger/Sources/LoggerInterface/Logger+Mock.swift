//
//  Logger+Mock.swift
//  Logger
//
//  Created by Stephane Magne
//

public extension Logger {

    static func mock() -> Logger {
        return Logger(
            log: { message, level in
                print("[\(level.rawValue)] Mock: \(message())")
            }
        )
    }
}
