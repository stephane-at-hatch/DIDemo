//
//  TMDBNetworkClient.swift
//  TMDBClient
//
//  Created by Stephane Magne
//

import Foundation
import TMDBClientInterface

/// Internal network client for making TMDB API requests.
final class TMDBNetworkClient: Sendable {

    private let configuration: TMDBConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        configuration: TMDBConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    /// Fetches and decodes a response from the TMDB API.
    /// - Parameters:
    ///   - endpoint: The API endpoint path (e.g., "/movie/now_playing")
    ///   - queryItems: Additional query parameters
    /// - Returns: The decoded response
    func fetch<T: Decodable & Sendable>(
        endpoint: String,
        queryItems: [URLQueryItem]
    ) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, queryItems: queryItems)

        logger.debug("Fetching: \(request.url?.absoluteString ?? "nil")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBClientError.networkError("Invalid response type")
        }

        try validateResponse(httpResponse, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError {
            logger.error("Decoding error: \(decodingError)")
            throw TMDBClientError.decodingError(decodingError.localizedDescription)
        }
    }

    // MARK: - Private

    private func buildRequest(
        endpoint: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = configuration.apiBaseURL.scheme
        components.host = configuration.apiBaseURL.host
        components.path = configuration.apiBaseURL.path + endpoint

        // Add default language and any additional query items
        var allQueryItems = [
            URLQueryItem(name: "language", value: configuration.language)
        ]
        allQueryItems.append(contentsOf: queryItems)
        components.queryItems = allQueryItems

        guard let url = components.url else {
            throw TMDBClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "Bearer \(configuration.apiReadAccessToken)",
            forHTTPHeaderField: "Authorization"
        )

        return request
    }

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw TMDBClientError.unauthorized
        case 404:
            throw TMDBClientError.notFound
        case 429:
            throw TMDBClientError.rateLimited
        default:
            let message = parseErrorMessage(from: data)
            throw TMDBClientError.httpError(
                statusCode: response.statusCode,
                message: message
            )
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let statusMessage: String?

            private enum CodingKeys: String, CodingKey {
                case statusMessage = "status_message"
            }
        }

        return try? decoder.decode(ErrorResponse.self, from: data).statusMessage
    }
}
