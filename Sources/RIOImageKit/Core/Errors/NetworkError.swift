//
//  NetworkError.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Errors that can occur during network operations.
public enum NetworkError: Error, Sendable {
    /// The URL is invalid or malformed
    case invalidUrl

    /// The server returned an invalid response (includes HTTP status code)
    case invalidResponse(Int)

    /// Network request failed with an underlying error
    case unknown((any Error)?)

    /// Failed to decode response data
    case decodingError(any Error)
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "The URL is invalid or malformed"

        case .invalidResponse(let statusCode):
            switch statusCode {
            case 400: return "Bad Request (400)"
            case 401: return "Unauthorized (401)"
            case 403: return "Forbidden (403)"
            case 404: return "Not Found (404)"
            case 408: return "Request Timeout (408)"
            case 429: return "Too Many Requests (429)"
            case 500: return "Internal Server Error (500)"
            case 502: return "Bad Gateway (502)"
            case 503: return "Service Unavailable (503)"
            default: return "Invalid Response (\(statusCode))"
            }

        case .unknown(let error):
            if let error = error {
                return "Network error: \(error.localizedDescription)"
            }
            return "An unknown network error occurred"

        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
