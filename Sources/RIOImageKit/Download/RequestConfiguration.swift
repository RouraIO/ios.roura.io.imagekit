//
//  RequestConfiguration.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Configuration for customizing image download requests.
///
/// This struct allows you to add custom HTTP headers to image download requests,
/// enabling authentication, API keys, and other custom request modifications.
///
/// ## Example Usage
/// ```swift
/// // Add authorization header
/// let config = RequestConfiguration(headers: [
///     "Authorization": "Bearer \(token)",
///     "X-API-Key": apiKey
/// ])
///
/// let downloader = ImageDownloadService(requestConfiguration: config)
/// ```
///
/// ## Common Use Cases
/// - **Bearer tokens**: `Authorization: Bearer <token>`
/// - **API keys**: `X-API-Key: <key>`
/// - **Custom user agents**: `User-Agent: MyApp/1.0`
/// - **Accept types**: `Accept: image/webp,image/*`
public struct RequestConfiguration: Sendable {

    // MARK: - Properties

    /// Custom HTTP headers to include in every request
    public let headers: [String: String]

    /// Timeout interval for requests in seconds
    public let timeoutInterval: TimeInterval


    // MARK: - Initialization

    /// Creates a request configuration with custom headers and timeout.
    ///
    /// - Parameters:
    ///   - headers: Dictionary of HTTP header names and values. Defaults to empty.
    ///   - timeoutInterval: Request timeout in seconds. Defaults to 30 seconds.
    public init(
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = 30
    ) {
        self.headers = headers
        self.timeoutInterval = timeoutInterval
    }


    // MARK: - Convenience Initializers

    /// Creates a configuration with Bearer token authentication.
    ///
    /// - Parameter token: The Bearer token to include in requests.
    /// - Returns: Configuration with Authorization header set.
    public static func bearerToken(_ token: String) -> RequestConfiguration {
        RequestConfiguration(headers: ["Authorization": "Bearer \(token)"])
    }


    /// Creates a configuration with an API key header.
    ///
    /// - Parameters:
    ///   - key: The API key value.
    ///   - headerName: The header name. Defaults to "X-API-Key".
    /// - Returns: Configuration with the API key header set.
    public static func apiKey(_ key: String, headerName: String = "X-API-Key") -> RequestConfiguration {
        RequestConfiguration(headers: [headerName: key])
    }


    // MARK: - Methods

    /// Applies this configuration's headers to a URL request.
    ///
    /// - Parameter request: The URL request to modify.
    /// - Returns: A new request with headers applied.
    func apply(to request: inout URLRequest) {
        request.timeoutInterval = timeoutInterval
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
