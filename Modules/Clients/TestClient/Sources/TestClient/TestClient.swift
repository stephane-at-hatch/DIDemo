import Foundation
@_exported import TestClientInterface

/// Concrete implementation of TestClient
public final class TestClient: TestClientProtocol, @unchecked Sendable {

    public init() {}

    public func fetchData() async throws -> TestClientData {
        // Real implementation would fetch from network, database, etc.
        try await Task.sleep(for: .milliseconds(500))

        return TestClientData(
            id: UUID().uuidString,
            title: "Real Data from TestClient",
            timestamp: Date()
        )
    }

    public func saveData(_ data: TestClientData) async throws {
        // Real implementation would save to storage
        print("Saving data: \(data)")
    }
}
