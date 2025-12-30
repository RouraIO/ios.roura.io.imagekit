//
//  ImageLoadable.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Protocol defining the interface for image loading and downloading operations.
///
/// This protocol provides a standardized interface for downloading images from remote URLs,
/// supporting features like progress tracking, background prefetching, and retry logic.
///
/// ## Overview
/// The protocol supports advanced image loading features:
/// - **Retry logic**: Automatic retry with exponential backoff
/// - **Progress tracking**: Real-time download progress updates
/// - **Background prefetching**: Preload images before they're needed
/// - **Cancellation**: Cancel ongoing prefetch operations
/// - **Background decoding**: Decode images off the main thread
///
/// ## Thread Safety
/// All methods are designed for concurrent access. Async methods should be awaited,
/// and implementations should handle task cancellation gracefully.
///
/// ## Example Usage
/// ```swift
/// let downloader: ImageLoadable = ImageDownloadService()
///
/// // Simple download
/// let image = try await downloader.loadImage(from: url)
///
/// // Download with progress
/// let image = try await downloader.loadImage(from: url) { progress in
///     print("Download progress: \(progress * 100)%")
/// }
///
/// // Prefetch images for better UX
/// await downloader.prefetchImages(urls: upcomingImageURLs)
/// ```
public protocol ImageLoadable: Sendable {
    
    /// Downloads an image from the specified URL.
    ///
    /// This method includes automatic retry logic with exponential backoff for
    /// transient network failures. Images are decoded in the background to prevent
    /// blocking the main thread.
    ///
    /// - Parameter url: The URL of the image to download.
    /// - Returns: The downloaded and decoded image.
    /// - Throws: `ImageCacheError.invalidImageData` if the data cannot be decoded as an image,
    ///           or `NetworkError` for network-related failures.
    ///
    /// - Note: This method will retry up to 3 times for retryable errors (network failures, timeouts).
    func loadImage(from url: URL) async throws -> PlatformImage
    
    
    /// Downloads an image with real-time progress tracking.
    ///
    /// Similar to `loadImage(from:)`, but provides progress updates through a callback.
    /// Useful for showing download progress indicators in the UI.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - progress: A closure called periodically with download progress (0.0 to 1.0).
    /// - Returns: The downloaded and decoded image.
    /// - Throws: `ImageCacheError.invalidImageData` if the data cannot be decoded as an image,
    ///           or `NetworkError` for network-related failures.
    ///
    /// - Note: Progress updates are approximate and may not be perfectly linear.
    func loadImage(from url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> PlatformImage
    
    
    /// Prefetches images in the background to improve perceived performance.
    ///
    /// This method downloads images at low priority without blocking the main thread.
    /// Prefetched images are typically stored in a cache for later use.
    ///
    /// - Parameter urls: An array of image URLs to prefetch.
    ///
    /// - Note: Prefetching runs at `.background` priority to avoid impacting user interactions.
    ///         Failed prefetch operations are silently ignored.
    func prefetchImages(urls: [URL]) async
    
    
    /// Cancels ongoing prefetch operations for the specified URLs.
    ///
    /// This allows you to cancel prefetching when images are no longer needed
    /// (e.g., user scrolled past them or navigated away).
    ///
    /// - Parameter urls: An array of image URLs to cancel prefetching for.
    ///
    /// - Note: This only affects prefetch operations, not active `loadImage()` calls.
    func cancelPrefetch(for urls: [URL])
}
