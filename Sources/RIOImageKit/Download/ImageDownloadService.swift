//
//  ImageDownloadService.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Production-grade image download service with retry logic and progress tracking.
///
/// This service provides robust image downloading with features comparable to SDWebImage:
/// - **Automatic retry**: Exponential backoff for transient network failures
/// - **Progress tracking**: Real-time download progress updates
/// - **Background decoding**: Prevents main thread blocking
/// - **Smart error handling**: Differentiates between retryable and permanent errors
/// - **Background prefetching**: Low-priority preloading of upcoming images
/// - **Cancellation support**: Can cancel ongoing prefetch operations
///
/// ## Retry Strategy
/// The service automatically retries failed downloads up to 3 times (configurable) with
/// exponential backoff. Client errors (4xx except 408/429) are not retried.
///
/// ## Example Usage
/// ```swift
/// let downloader = ImageDownloadService()
///
/// // Simple download
/// let image = try await downloader.loadImage(from: url)
///
/// // Download with progress tracking
/// let image = try await downloader.loadImage(from: url) { progress in
///     print("Progress: \(progress * 100)%")
/// }
///
/// // Prefetch for better UX
/// await downloader.prefetchImages(urls: upcomingURLs)
/// ```
public struct ImageDownloadService {

    // MARK: - Static Properties

    /// Shared URLSession configured for image downloads
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    /// Actor for managing prefetch tasks in a concurrency-safe manner
    private actor PrefetchManager {
        private var tasks: [URL: Task<Void, Never>] = [:]

        func addTask(_ task: Task<Void, Never>, for url: URL) {
            tasks[url] = task
        }

        func cancelTask(for url: URL) {
            tasks[url]?.cancel()
            tasks.removeValue(forKey: url)
        }
    }

    /// Shared prefetch manager
    private static let prefetchManager = PrefetchManager()

    /// Shared request deduplicator to prevent duplicate concurrent downloads
    private static let deduplicator = RequestDeduplicator()

    /// Shared download limiter to prevent too many concurrent downloads
    private static let downloadLimiter = DownloadLimiter(maxConcurrent: 6)

    // MARK: - Properties

    /// Maximum number of retry attempts for failed downloads
    private let maxRetries: Int

    /// Initial delay between retries (doubles with each attempt for exponential backoff)
    private let retryDelay: TimeInterval

    /// Optional request configuration for custom headers and authentication
    private let requestConfiguration: RequestConfiguration?


    // MARK: - Initialization

    /// Creates a new image download service with the specified configuration.
    ///
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts. Defaults to 3.
    ///   - retryDelay: Initial retry delay in seconds. Defaults to 0.5.
    ///                 The delay doubles with each retry (exponential backoff).
    ///   - requestConfiguration: Optional configuration for custom headers and authentication.
    public init(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 0.5,
        requestConfiguration: RequestConfiguration? = nil
    ) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.requestConfiguration = requestConfiguration
    }
}

// MARK: - ImageLoadable Conformance

extension ImageDownloadService: ImageLoadable {

    /// Downloads an image from the specified URL.
    ///
    /// This is a convenience method that calls `loadImage(from:progress:)` with an empty progress handler.
    ///
    /// - Parameter url: The URL of the image to download.
    /// - Returns: The downloaded and decoded image.
    /// - Throws: `ImageCacheError.invalidImageData` if the data cannot be decoded,
    ///           or `NetworkError` for network-related failures.
    public func loadImage(from url: URL) async throws -> PlatformImage {
        try await loadImage(from: url, progress: { _ in })
    }


    /// Downloads an image with real-time progress tracking and automatic retry logic.
    ///
    /// This method implements:
    /// - **Concurrency limiting**: Maximum of 6 simultaneous downloads
    /// - **Request deduplication**: Multiple concurrent requests for the same URL share one download
    /// - Automatic retry with exponential backoff (up to `maxRetries` attempts)
    /// - Smart error handling (doesn't retry permanent client errors)
    /// - Real-time progress updates via callback
    /// - Background image decoding to prevent main thread blocking
    ///
    /// ## Retry Behavior
    /// - Retries network errors, timeouts, and rate limits (408, 429)
    /// - Does NOT retry client errors (400-499 except 408/429)
    /// - Uses exponential backoff: 0.5s, 1s, 2s (for default configuration)
    ///
    /// - Parameters:
    ///   - url: The URL of the image to download.
    ///   - progress: A closure called periodically with download progress (0.0 to 1.0).
    /// - Returns: The downloaded and decoded image.
    /// - Throws: `ImageCacheError.invalidImageData` if the data cannot be decoded,
    ///           or `NetworkError` for network-related failures.
    public func loadImage(from url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> PlatformImage {
        // Use deduplicator to prevent duplicate downloads
        let data = try await Self.deduplicator.download(url) { url in
            // Limit concurrent downloads
            try await Self.downloadLimiter.withLimit {
                try await self.downloadData(from: url, progress: progress)
            }
        }

        // Decode in background to avoid blocking
        return try await ImageDecoder.decode(data: data)
    }


    /// Downloads raw data with retry logic and progress tracking.
    ///
    /// - Parameters:
    ///   - url: The URL to download from.
    ///   - progress: Progress callback.
    /// - Returns: The downloaded data.
    /// - Throws: Network errors or timeout errors.
    private func downloadData(from url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> Data {
        var lastError: (any Error)?

        // Retry logic with exponential backoff
        for attempt in 0..<maxRetries {
            do {
                // Create request with custom headers if configured
                var request = URLRequest(url: url)
                requestConfiguration?.apply(to: &request)

                let (asyncBytes, response) = try await Self.session.bytes(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ImageCacheError.invalidResponse(-1)
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw ImageCacheError.invalidResponse(httpResponse.statusCode)
                }

                // Collect data with progress tracking
                let expectedLength = httpResponse.expectedContentLength
                var data = Data()
                data.reserveCapacity(Int(expectedLength))

                for try await byte in asyncBytes {
                    data.append(byte)

                    // Report progress
                    if expectedLength > 0 {
                        let currentProgress = Double(data.count) / Double(expectedLength)
                        progress(currentProgress)
                    }
                }

                return data

            } catch {
                lastError = error

                // Don't retry on certain errors
                if case ImageCacheError.invalidResponse(let code) = error,
                   (400..<500).contains(code) && code != 408 && code != 429 {
                    // Client errors (except timeout/rate limit) shouldn't be retried
                    throw error
                }

                // If this isn't the last attempt, wait before retrying
                if attempt < maxRetries - 1 {
                    let delay = retryDelay * Double(1 << attempt) // Exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        // All retries failed
        throw lastError ?? ImageCacheError.invalidImageData
    }


    /// Prefetches images in the background at low priority.
    ///
    /// This creates detached tasks with `.background` priority for each URL.
    /// Failed downloads are silently ignored. Tasks can be cancelled using `cancelPrefetch(for:)`.
    ///
    /// - Parameter urls: An array of image URLs to prefetch.
    ///
    /// - Note: Prefetched images should be cached by the calling code (e.g., `ImageCacheManager`).
    public func prefetchImages(urls: [URL]) async {
        for url in urls {
            // Use detached task with background priority for prefetching
            let task = Task.detached(priority: .background) {
                _ = try? await ImageDownloadService().loadImage(from: url)
            }
            await Self.prefetchManager.addTask(task, for: url)
        }
    }


    /// Cancels ongoing prefetch operations for the specified URLs.
    ///
    /// This cancels the background tasks and removes them from tracking.
    ///
    /// - Parameter urls: An array of image URLs to cancel prefetching for.
    public func cancelPrefetch(for urls: [URL]) {
        Task {
            for url in urls {
                await Self.prefetchManager.cancelTask(for: url)
            }
        }
    }
}
