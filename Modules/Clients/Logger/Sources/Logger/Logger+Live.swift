import Foundation
@_exported import LoggerInterface

public extension Logger {

    static func live(domain: String) -> Logger {
        return Logger(
            log: { message, level in
                print("[\(level.rawValue)] \(domain): \(message())")
            }
        )
    }
}
