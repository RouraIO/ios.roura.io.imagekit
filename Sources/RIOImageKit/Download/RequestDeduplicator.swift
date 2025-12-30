//
//  RequestDeduplicator.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Prevents duplicate concurrent downloads of the same resource.
///
/// This actor tracks ongoing downloads and ensures that multiple requests
/// for the same URL share a single download operation, improving performance
/// and reducing network traffic.
///
/// ## Example Usage
/// ```swift
/// let deduplicator = RequestDeduplicator()
///
/// // Multiple concurrent requests for the same URL will share one download
/// async let image1 = deduplicator.download(url) { try await downloadService.download($0) }
/// async let image2 = deduplicator.download(url) { try await downloadService.download($0) }
/// async let image3 = deduplicator.download(url) { try await downloadService.download($0) }
///
/// // Only one actual download occurs
/// let results = try await [image1, image2, image3]
/// ```
public actor RequestDeduplicator {

    // MARK: - Properties

    /// Active download tasks keyed by URL
    private var activeTasks: [URL: Task<Data, any Error>] = [:]


    // MARK: - Initialization

    public init() {}


    // MARK: - Public Methods

    /// Downloads data for a URL, deduplicating concurrent requests.
    ///
    /// If a download for this URL is already in progress, returns the existing
    /// task instead of starting a new download. Otherwise, starts a new download
    /// using the provided closure.
    ///
    /// - Parameters:
    ///   - url: The URL to download.
    ///   - download: Closure that performs the actual download.
    /// - Returns: The downloaded data.
    /// - Throws: An error if the download fails.
    public func download(
        _ url: URL,
        download: @escaping @Sendable (URL) async throws -> Data
    ) async throws -> Data {

        // Return existing task if one is already running
        if let existingTask = activeTasks[url] {
            return try await existingTask.value
        }

        // Create new task
        let task = Task<Data, any Error> {
            do {
                let data = try await download(url)
                cleanup(url)
                return data
            } catch {
                cleanup(url)
                throw error
            }
        }

        activeTasks[url] = task
        return try await task.value
    }


    /// Cancels any active download for the specified URL.
    ///
    /// - Parameter url: The URL whose download should be cancelled.
    public func cancel(_ url: URL) {
        activeTasks[url]?.cancel()
        activeTasks[url] = nil
    }


    /// Cancels all active downloads.
    public func cancelAll() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }


    /// Returns the number of active downloads.
    public var activeDownloadCount: Int {
        activeTasks.count
    }


    // MARK: - Private Methods

    private func cleanup(_ url: URL) {
        activeTasks[url] = nil
    }
}
