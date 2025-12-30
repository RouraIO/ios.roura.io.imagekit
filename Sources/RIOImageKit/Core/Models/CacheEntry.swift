//
//  CacheEntry.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Metadata for tracking cached items in the disk cache.
///
/// This struct stores information about cached files, including their cache key,
/// creation timestamp, and file size. It's used by ``DiskImageCache`` to implement
/// LRU (Least Recently Used) eviction and expiration policies.
///
/// ## Overview
/// Each cached image on disk has an associated `CacheEntry` that tracks:
/// - **Key**: Unique identifier (typically the URL string)
/// - **Timestamp**: When the item was cached (for LRU and expiration)
/// - **File Size**: Size in bytes (for tracking total cache size)
///
/// ## Caching Strategy
/// The cache uses this metadata to implement efficient eviction:
/// 1. **Expiration**: Remove entries older than `maxAge`
/// 2. **Size limits**: Remove oldest entries when cache exceeds size limit
/// 3. **LRU**: Prioritize keeping recently accessed items
///
/// ## Example Usage
/// ```swift
/// // Creating a cache entry
/// let entry = CacheEntry(
///     key: "https://example.com/image.jpg",
///     timestamp: Date(),
///     fileSize: 245_760 // 240 KB
/// )
///
/// // Checking if expired (e.g., after 7 days)
/// let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
/// if entry.isExpired(maxAge: maxAge) {
///     // Remove from cache
///     try await diskCache.removeImage(for: entry.key)
/// }
///
/// // Sorting entries for LRU eviction
/// let sortedEntries = cacheEntries.sorted { $0.timestamp < $1.timestamp }
/// let oldestEntry = sortedEntries.first // Remove this one first
/// ```
///
/// ## Persistence
/// Cache entries are persisted to disk (typically as JSON in `cache-metadata.json`)
/// to survive app restarts. The ``DiskImageCache`` loads this metadata on initialization.
///
/// - SeeAlso: ``DiskImageCache`` for the implementation using cache entries.
/// - SeeAlso: ``ImageKitConfig`` for configuring max age and cache size limits.
public struct CacheEntry: Codable, Sendable {

    /// The unique cache key identifying this entry.
    ///
    /// Typically the absolute URL string for remote images.
    ///
    /// **Example:**
    /// ```swift
    /// let key = "https://example.com/avatar/user123.jpg"
    /// ```
    public let key: String


    /// The timestamp when this entry was created or last accessed.
    ///
    /// Used for:
    /// - Expiration checking (entries older than `maxAge` are removed)
    /// - LRU eviction (oldest entries removed first when cache is full)
    ///
    /// **Note:** Some caches update this on access (LRU), others only on creation (FIFO).
    public let timestamp: Date


    /// The size of the cached file in bytes.
    ///
    /// Used to track total cache size and enforce size limits.
    /// When the cache exceeds its maximum size, entries are removed
    /// starting with the oldest until under the limit.
    ///
    /// **Example:**
    /// ```swift
    /// let totalCacheSize = cacheEntries.reduce(0) { $0 + $1.fileSize }
    /// if totalCacheSize > maxCacheSize {
    ///     // Evict oldest entries
    /// }
    /// ```
    public let fileSize: Int64


    /// Creates a new cache entry with the specified metadata.
    ///
    /// - Parameters:
    ///   - key: The unique cache key (typically a URL string).
    ///   - timestamp: When the entry was created or last accessed.
    ///   - fileSize: The size of the cached file in bytes.
    public init(key: String, timestamp: Date, fileSize: Int64) {
        self.key = key
        self.timestamp = timestamp
        self.fileSize = fileSize
    }


    /// Checks if this cache entry has expired based on the maximum age.
    ///
    /// An entry is considered expired if the time elapsed since its timestamp
    /// exceeds the specified maximum age.
    ///
    /// ## Example Usage
    /// ```swift
    /// // Check if entry is older than 7 days
    /// let oneWeek: TimeInterval = 7 * 24 * 60 * 60
    /// if entry.isExpired(maxAge: oneWeek) {
    ///     print("Entry expired, removing from cache")
    ///     try await cache.removeImage(for: entry.key)
    /// }
    ///
    /// // Different max ages for different content
    /// let profileImageMaxAge: TimeInterval = 24 * 60 * 60  // 1 day
    /// let staticAssetMaxAge: TimeInterval = 30 * 24 * 60 * 60  // 30 days
    /// ```
    ///
    /// - Parameter maxAge: The maximum age in seconds before expiration.
    /// - Returns: `true` if the entry is expired, `false` otherwise.
    public func isExpired(maxAge: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > maxAge
    }
}
