//
//  ImageNetworkError.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/30/25.
//

import Foundation

/// Errors that can occur during network operations.
///
/// This enum provides structured error handling for all network-related failures,
/// including malformed URLs, HTTP errors, and JSON decoding issues.
///
/// ## Overview
/// Network errors are categorized into four types:
/// - **`invalidUrl`**: URL construction or validation failed
/// - **`invalidResponse`**: HTTP request returned non-2xx status code
/// - **`decodingError`**: JSON parsing failed
/// - **`unknown`**: Unexpected or unhandled error
///
/// ## Error Handling Strategy
/// Each error case provides user-friendly localized descriptions suitable
/// for displaying directly in UI, following Apple's error presentation guidelines.
///
/// ## Example Usage
/// ```swift
/// do {
///     let users: [User] = try await networkClient.request(url)
///     // Process users...
/// } catch NetworkError.invalidResponse(let statusCode) {
///     if statusCode == 401 {
///         // Handle authentication failure
///         showLoginScreen()
///     } else if statusCode == 404 {
///         // Handle missing resource
///         showNotFoundMessage()
///     }
/// } catch NetworkError.decodingError(let underlying) {
///     // Log parsing issue for debugging
///     logger.error("Failed to parse response: \(underlying)")
///     showGenericErrorAlert()
/// } catch {
///     // Handle other errors
///     showGenericErrorAlert()
/// }
/// ```
///
/// ## Displaying Errors to Users
/// ```swift
/// // All errors conform to LocalizedError
/// catch let error as NetworkError {
///     alertTitle = "Network Error"
///     alertMessage = error.localizedDescription // User-friendly message
/// }
/// ```
///
/// - SeeAlso: ``NetworkClient`` for throwing these errors.
public enum ImageNetworkError: Error {

    /// The URL is malformed or invalid.
    ///
    /// Thrown when `URLComponents` or `URLBuilder` fails to construct a valid URL
    /// from the provided components (scheme, host, path, query parameters).
    ///
    /// **Common Causes:**
    /// - Invalid characters in URL components
    /// - Missing required components (e.g., host)
    /// - Malformed query parameters
    ///
    /// **Example:**
    /// ```swift
    /// // This might throw .invalidUrl due to invalid characters
    /// let url = try URLBuilder(host: "api.example.com")
    ///     .path("users/[invalid]")
    ///     .build()
    /// ```
    case invalidUrl


    /// The HTTP response has a non-2xx status code.
    ///
    /// Contains the HTTP status code for detailed error handling.
    /// Common codes: 400 (Bad Request), 401 (Unauthorized), 404 (Not Found),
    /// 500 (Server Error), etc.
    ///
    /// **Retry Behavior:**
    /// - `NetworkClient` does NOT retry 4xx errors (except 408 timeout, 429 rate limit)
    /// - `NetworkClient` DOES retry 5xx errors with exponential backoff
    ///
    /// **Example:**
    /// ```swift
    /// catch NetworkError.invalidResponse(let code) {
    ///     switch code {
    ///     case 401: showLoginScreen()
    ///     case 403: showAccessDenied()
    ///     case 404: showNotFound()
    ///     case 500...599: showServerError()
    ///     default: showGenericError()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter Int: The HTTP status code (e.g., 404, 500).
    case invalidResponse(Int)


    /// JSON decoding failed when parsing the response.
    ///
    /// Contains the underlying `DecodingError` for detailed debugging.
    /// Common causes include:
    /// - Response JSON structure doesn't match expected model
    /// - Missing required fields
    /// - Type mismatches (e.g., expecting Int but got String)
    /// - Invalid JSON syntax
    ///
    /// **Debugging Tips:**
    /// ```swift
    /// catch NetworkError.decodingError(let underlyingError) {
    ///     // Print detailed parsing error
    ///     print("Decoding failed: \(underlyingError)")
    ///
    ///     // Extract specific decoding error details
    ///     if let decodingError = underlyingError as? DecodingError {
    ///         switch decodingError {
    ///         case .keyNotFound(let key, _):
    ///             print("Missing key: \(key)")
    ///         case .typeMismatch(let type, _):
    ///             print("Type mismatch for: \(type)")
    ///         case .valueNotFound(let type, _):
    ///             print("Value not found for: \(type)")
    ///         case .dataCorrupted(let context):
    ///             print("Data corrupted: \(context)")
    ///         @unknown default:
    ///             print("Unknown decoding error")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter Error: The underlying decoding error.
    case decodingError(any Error)


    /// An unexpected or unhandled error occurred.
    ///
    /// This is a catch-all for errors that don't fit other categories,
    /// such as system-level failures or unexpected exceptions.
    ///
    /// **When This Occurs:**
    /// - Network stack errors that aren't caught specifically
    /// - SSL/TLS certificate errors
    /// - DNS resolution failures
    /// - System resource exhaustion
    ///
    /// **Example:**
    /// ```swift
    /// catch NetworkError.unknown {
    ///     // Log for investigation
    ///     logger.error("Unexpected network error occurred")
    ///     showGenericErrorAlert()
    /// }
    /// ```
    case unknown
}


// MARK: - LocalizedError Conformance

extension ImageNetworkError: LocalizedError {

    /// User-friendly error descriptions suitable for UI display.
    ///
    /// These descriptions follow Apple's guidelines for error messages:
    /// - Clear and concise
    /// - Explain what went wrong
    /// - Suggest what the user can do
    /// - Avoid technical jargon
    ///
    /// ## Status Code Descriptions
    /// Provides specific, actionable messages for common HTTP status codes:
    /// - **400**: Bad Request - Check your input
    /// - **401**: Unauthorized - Sign in required
    /// - **403**: Forbidden - Access denied
    /// - **404**: Not Found - Resource doesn't exist
    /// - **408**: Request Timeout - Connection issue
    /// - **429**: Too Many Requests - Rate limited
    /// - **500**: Internal Server Error - Server issue
    /// - **503**: Service Unavailable - Temporary outage
    ///
    /// - Returns: A localized description of the error suitable for displaying to users.
    public var errorDescription: String? {
        switch self {
        case .invalidUrl: "Something went wrong while preparing the request. Please try again."
        case .invalidResponse(let statusCode):
            switch statusCode {
            case 400: "Bad request. Please check your input and try again."
            case 401: "Authentication required. Please sign in."
            case 403: "Access denied. You don't have permission to access this resource."
            case 404: "The requested resource was not found."
            case 408: "Request timeout. Please check your connection and try again."
            case 429: "Too many requests. Please wait a moment and try again."
            case 500: "Server error. Please try again later."
            case 503: "Service temporarily unavailable. Please try again later."
            default: "The server returned an unexpected response (code \(statusCode)). Please try again."
            }
        case .decodingError(let underlying): "Failed to decode response: \(underlying.localizedDescription)"
        case .unknown: "An unknown error occurred. Please try again later."
        }
    }
}
