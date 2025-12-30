//
//  DownloadLimiter.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Limits the number of concurrent download operations.
///
/// This actor implements a semaphore-like mechanism to prevent too many
/// simultaneous downloads from overwhelming the network or system resources.
///
/// ## Why Limit Concurrent Downloads?
/// - **Network Efficiency**: Too many connections can saturate bandwidth
/// - **System Resources**: Each download uses memory and file handles
/// - **Server Courtesy**: Avoid overwhelming servers with too many requests
/// - **Better UX**: Prioritizing fewer downloads provides faster individual completion
///
/// ## Example Usage
/// ```swift
/// let limiter = DownloadLimiter(maxConcurrent: 4)
///
/// // Only 4 downloads will run simultaneously
/// await limiter.withLimit {
///     return try await downloadImage(url)
/// }
/// ```
public actor DownloadLimiter {

    // MARK: - Properties

    /// Maximum number of concurrent downloads allowed
    private let maxConcurrent: Int

    /// Current number of active downloads
    private var activeCount: Int = 0

    /// Queue of waiting download continuations
    private var waitQueue: [CheckedContinuation<Void, Never>] = []


    // MARK: - Initialization

    /// Creates a download limiter with the specified concurrency limit.
    ///
    /// - Parameter maxConcurrent: Maximum number of simultaneous downloads.
    ///                            Defaults to 6, which is a good balance for most cases.
    public init(maxConcurrent: Int = 6) {
        self.maxConcurrent = max(1, maxConcurrent)
    }


    // MARK: - Public Methods

    /// Executes a download operation, limiting concurrency.
    ///
    /// If the concurrent download limit is reached, this suspends until a slot becomes available.
    ///
    /// - Parameter operation: The download operation to execute.
    /// - Returns: The result of the download operation.
    /// - Throws: Any error thrown by the operation.
    public func withLimit<T>(_ operation: @Sendable () async throws -> T) async rethrows -> T {
        // Wait for a slot if at capacity
        await acquireSlot()

        defer {
            // Release slot when done
            Task { await releaseSlot() }
        }

        return try await operation()
    }


    /// Current number of active downloads.
    public var currentCount: Int {
        activeCount
    }


    /// Number of downloads waiting for a slot.
    public var queuedCount: Int {
        waitQueue.count
    }


    // MARK: - Private Methods

    private func acquireSlot() async {
        if activeCount < maxConcurrent {
            activeCount += 1
            return
        }

        // Wait in queue
        await withCheckedContinuation { continuation in
            waitQueue.append(continuation)
        }

        activeCount += 1
    }


    private func releaseSlot() {
        activeCount -= 1

        // Resume next waiting task if any
        if !waitQueue.isEmpty {
            let continuation = waitQueue.removeFirst()
            continuation.resume()
        }
    }
}
