//
//  ImageCacheError.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Errors that can occur during image caching and loading operations.
///
/// This enum defines all error cases specific to image caching, downloading,
/// and decoding. It provides user-friendly localized descriptions suitable
/// for display in UI.
///
/// ## Overview
/// Error cases:
/// - **`invalidImageData`**: Downloaded or cached data cannot be decoded as an image
/// - **`invalidResponse`**: Network request returned an invalid or error response
///
/// ## Error Handling
/// ```swift
/// do {
///     let image = try await imageCache.loadImage(from: url)
///     displayImage(image)
/// } catch ImageCacheError.invalidImageData {
///     // Data was downloaded but isn't a valid image
///     logger.error("Invalid image format for URL: \(url)")
///     showPlaceholderImage()
/// } catch {
///     // Handle other errors (network, etc.)
///     showErrorAlert(error.localizedDescription)
/// }
/// ```
///
/// ## Common Scenarios
/// ### Invalid Image Data
/// This error occurs when:
/// - Server returns non-image content (HTML, JSON, etc.)
/// - Image file is corrupted
/// - Unsupported image format (though iOS supports most common formats)
/// - Downloaded data is incomplete
///
/// ### Example
/// ```swift
/// // Server returns HTML instead of image
/// let url = URL(string: "https://example.com/image.jpg")!
/// do {
///     let image = try await downloader.loadImage(from: url)
/// } catch ImageCacheError.invalidImageData {
///     // The URL returned HTML instead of an image
///     print("URL does not point to a valid image")
/// }
/// ```
///
/// - SeeAlso: ``ImageDownloadService`` for operations that can throw these errors.
/// - SeeAlso: ``ImageDecoder`` for image decoding operations.
public enum ImageCacheError: Error {

    /// The data cannot be decoded as a valid image.
    ///
    /// Thrown when image initialization from data returns `nil`, indicating the data
    /// is not a valid image format or is corrupted.
    ///
    /// **Common Causes:**
    /// - Server returned wrong content type (HTML, JSON, plain text)
    /// - Image file is corrupted or incomplete
    /// - Unsupported image format (rare - iOS supports JPEG, PNG, GIF, HEIC, etc.)
    /// - Network interrupted during download (partial data)
    ///
    /// **Resolution Strategies:**
    /// 1. Verify the URL points to an actual image
    /// 2. Check server Content-Type header
    /// 3. Retry the download (may have been interrupted)
    /// 4. Fall back to placeholder image
    ///
    /// **Example:**
    /// ```swift
    /// do {
    ///     let image = try await ImageDecoder.decode(data: imageData)
    ///     return image
    /// } catch ImageCacheError.invalidImageData {
    ///     // Data is not a valid image
    ///     logger.error("Failed to decode image - invalid format")
    ///     return placeholderImage
    /// }
    /// ```
    case invalidImageData


    /// The network response is invalid or indicates an error.
    ///
    /// Thrown when the HTTP response has a non-2xx status code or is missing entirely.
    ///
    /// **Common Causes:**
    /// - Server returned error status (404, 500, etc.)
    /// - Network request failed to complete
    /// - Invalid or missing HTTP response
    ///
    /// **Example:**
    /// ```swift
    /// do {
    ///     let image = try await downloader.loadImage(from: url)
    /// } catch ImageCacheError.invalidResponse(let statusCode) {
    ///     if statusCode == 404 {
    ///         print("Image not found")
    ///     } else {
    ///         print("Server error: \(statusCode)")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter statusCode: The HTTP status code, or -1 if response is missing
    case invalidResponse(Int)
}


// MARK: - LocalizedError Conformance

extension ImageCacheError: LocalizedError {

    /// User-friendly error description suitable for UI display.
    ///
    /// Provides a localized, non-technical explanation of what went wrong
    /// that can be shown directly to users in alerts or error messages.
    ///
    /// ## Example Usage
    /// ```swift
    /// catch let error as ImageCacheError {
    ///     // Show user-friendly message
    ///     showAlert(
    ///         title: "Image Error",
    ///         message: error.localizedDescription
    ///     )
    /// }
    /// ```
    ///
    /// - Returns: A user-friendly description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "The downloaded data could not be converted to an image."
        case .invalidResponse(let statusCode):
            if statusCode == -1 {
                "Invalid network response. Please try again."
            } else {
                "Server returned error \(statusCode). Please try again."
            }
        }
    }
}
