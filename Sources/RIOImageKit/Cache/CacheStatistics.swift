//
//  CacheStatistics.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Performance statistics for image caching operations.
///
/// Tracks cache hits, misses, and computed metrics to help optimize
/// cache configuration and diagnose performance issues.
///
/// ## Key Metrics
/// - **Hit Rate**: Percentage of requests served from cache
/// - **Miss Rate**: Percentage of requests requiring downloads
/// - **Total Requests**: Cumulative number of image requests
///
/// ## Example Usage
/// ```swift
/// let stats = await cache.statistics
/// print("Hit rate: \(stats.hitRate * 100)%")
/// print("Total requests: \(stats.totalRequests)")
/// ```
public struct CacheStatistics: Sendable {

    // MARK: - Properties

    /// Number of successful cache hits
    public let hits: Int

    /// Number of cache misses
    public let misses: Int

    /// Timestamp when statistics were last reset
    public let startTime: Date


    // MARK: - Initialization

    /// Creates cache statistics with the specified values.
    ///
    /// - Parameters:
    ///   - hits: Number of cache hits.
    ///   - misses: Number of cache misses.
    ///   - startTime: When statistics tracking began. Defaults to now.
    public init(hits: Int = 0, misses: Int = 0, startTime: Date = Date()) {
        self.hits = hits
        self.misses = misses
        self.startTime = startTime
    }


    // MARK: - Computed Properties

    /// Total number of cache requests (hits + misses)
    public var totalRequests: Int {
        hits + misses
    }


    /// Cache hit rate as a percentage (0.0 to 1.0)
    ///
    /// A rate of 0.8 means 80% of requests were served from cache.
    public var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(hits) / Double(totalRequests)
    }


    /// Cache miss rate as a percentage (0.0 to 1.0)
    ///
    /// A rate of 0.2 means 20% of requests required downloads.
    public var missRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(misses) / Double(totalRequests)
    }


    /// Time elapsed since statistics tracking began
    public var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }


    // MARK: - Methods

    /// Creates a new statistics object with an incremented hit count.
    ///
    /// - Returns: Updated statistics with hits incremented by 1.
    public func recordHit() -> CacheStatistics {
        CacheStatistics(hits: hits + 1, misses: misses, startTime: startTime)
    }


    /// Creates a new statistics object with an incremented miss count.
    ///
    /// - Returns: Updated statistics with misses incremented by 1.
    public func recordMiss() -> CacheStatistics {
        CacheStatistics(hits: hits, misses: misses + 1, startTime: startTime)
    }


    /// Creates a new statistics object with reset counters.
    ///
    /// - Returns: Fresh statistics with zero hits and misses.
    public func reset() -> CacheStatistics {
        CacheStatistics(hits: 0, misses: 0, startTime: Date())
    }
}


// MARK: - CustomStringConvertible

extension CacheStatistics: CustomStringConvertible {

    public var description: String {
        """
        Cache Statistics:
          Hits: \(hits)
          Misses: \(misses)
          Total Requests: \(totalRequests)
          Hit Rate: \(String(format: "%.1f%%", hitRate * 100))
          Miss Rate: \(String(format: "%.1f%%", missRate * 100))
          Elapsed Time: \(String(format: "%.1fs", elapsedTime))
        """
    }
}
