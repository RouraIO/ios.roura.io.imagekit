//
//  DiskImageCache.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import CryptoKit
import Foundation

/// Persistent disk-based image cache with LRU eviction and time-to-live (TTL) support.
///
/// This actor provides thread-safe access to a disk-based image cache that survives app restarts.
/// It implements intelligent eviction strategies to manage storage space efficiently.
///
/// ## Overview
/// `DiskImageCache` provides enterprise-grade disk caching with:
/// - **LRU eviction**: Automatically removes least recently used images when size limit is reached
/// - **TTL support**: Optional automatic expiration of cached images after a specified duration
/// - **Persistent metadata**: Tracks access and creation times across app launches
/// - **JPEG compression**: Reduces disk usage with configurable quality (0.8 default)
/// - **MD5 hashing**: Uses hashed filenames for safe storage of URL-based keys
/// - **Thread safety**: Actor isolation ensures safe concurrent access
///
/// ## Storage Structure
/// Images are stored in the app's Caches directory:
/// ```
/// /Library/Caches/ImageCache/
/// ├── {md5_hash_1}.jpg
/// ├── {md5_hash_2}.jpg
/// ├── access_times.json
/// └── creation_times.json
/// ```
///
/// ## Performance Characteristics
/// - **Get**: O(1) file system lookup + O(1) metadata lookup
/// - **Set**: O(1) write + O(n) eviction check (where n = number of cached images)
/// - **Storage**: Up to 100MB by default (configurable)
/// - **Compression**: JPEG at 0.8 quality (reduces size by ~40-60%)
///
/// ## Example Usage
/// ```swift
/// let cache = try DiskImageCache(
///     directory: "ImageCache",
///     maxDiskSize: 100 * 1024 * 1024, // 100MB
///     maxAge: 7 * 24 * 60 * 60        // 1 week
/// )
///
/// // Store an image
/// try await cache.setImage(image, for: imageURL.absoluteString)
///
/// // Retrieve an image (returns nil if expired or not found)
/// if let cachedImage = await cache.getImage(for: imageURL.absoluteString) {
///     // Use image
/// }
/// ```
///
/// - Note: Images are automatically removed when they exceed `maxAge` (if set).
///         The cache is cleaned up on initialization and when retrieving expired images.
public actor DiskImageCache {

    // MARK: - Properties

    /// File manager for disk operations
    private let fileManager = FileManager.default

    /// Directory where cached images are stored
    private let cacheDirectory: URL

    /// Maximum total disk space for all cached images in bytes
    private let maxDiskSize: Int64

    /// Maximum age for cached images in seconds; nil means images never expire
    private let maxAge: TimeInterval?

    /// Dictionary tracking last access time for each cached image (for LRU eviction)
    private var accessTimes: [String: Date] = [:]

    /// Dictionary tracking creation time for each cached image (for TTL)
    private var creationTimes: [String: Date] = [:]

    /// Performance statistics for this cache
    private var statistics = CacheStatistics()


    // MARK: - Initialization

    /// Creates a new disk cache with the specified configuration.
    ///
    /// The initializer sets up the cache directory and loads existing metadata.
    /// It also automatically removes any expired images found during initialization.
    ///
    /// - Parameters:
    ///   - directory: Subdirectory name within the Caches directory. Defaults to "ImageCache".
    ///   - maxDiskSize: Maximum disk space in bytes. Defaults to 100MB.
    ///   - maxAge: Maximum age for cached images in seconds. Defaults to 1 week.
    ///                Pass `nil` to disable expiration.
    ///
    /// - Throws: An error if the cache directory cannot be created.
    public init(
        directory: String = "ImageCache",
        maxDiskSize: Int64 = 100 * 1024 * 1024, // 100MB default
        maxAge: TimeInterval? = 7 * 24 * 60 * 60 // 1 week default
    ) throws {
        self.maxDiskSize = maxDiskSize
        self.maxAge = maxAge

        // Setup cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent(directory)

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }

        // Load existing times and clean up in background
        Task {
            await loadAccessTimes()
            await loadCreationTimes()
            await removeExpiredImages()
        }
    }


    // MARK: - Cache Operations

    /// Retrieves a cached image for the specified key.
    ///
    /// This method checks if the image has expired based on TTL. If expired, the image
    /// is automatically removed and `nil` is returned. On successful retrieval, the access
    /// time is updated for LRU tracking.
    ///
    /// - Parameter key: The cache key (typically a URL string).
    /// - Returns: The cached image if found and not expired, otherwise `nil`.
    public func getImage(for key: String) -> PlatformImage? {
        // Check if expired
        if let maxAge, let creationTime = creationTimes[key] {
            if Date().timeIntervalSince(creationTime) > maxAge {
                // Expired - remove it
                try? removeImage(for: key)
                statistics = statistics.recordMiss()
                return nil
            }
        }

        let fileURL = cacheDirectory.appendingPathComponent(md5Hash(of: key))

        guard let data = try? Data(contentsOf: fileURL),
              let image = PlatformImage(data: data) else {
            statistics = statistics.recordMiss()
            return nil
        }

        // Update access time for LRU
        accessTimes[key] = Date()
        saveAccessTimes()

        // Record cache hit
        statistics = statistics.recordHit()
        return image
    }


    /// Stores an image on disk with the specified key.
    ///
    /// The image is compressed as JPEG (0.8 quality) to reduce disk usage. Both access
    /// and creation times are recorded for LRU eviction and TTL tracking. If storing
    /// the image causes the cache to exceed `maxDiskSize`, the least recently used
    /// images are automatically evicted.
    ///
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - key: The cache key (typically a URL string).
    ///
    /// - Throws: An error if the image cannot be written to disk.
    public func setImage(_ image: PlatformImage, for key: String) async throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let fileURL = cacheDirectory.appendingPathComponent(md5Hash(of: key))
        try data.write(to: fileURL)

        let now = Date()
        // Track creation time for TTL
        creationTimes[key] = now
        saveCreationTimes()

        // Update access time for LRU
        accessTimes[key] = now
        saveAccessTimes()

        // Check if eviction needed
        await evictIfNeeded()
    }


    /// Removes a cached image and its associated metadata.
    ///
    /// - Parameter key: The cache key (typically a URL string).
    /// - Throws: An error if the file cannot be removed (though errors are silently ignored).
    public func removeImage(for key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(md5Hash(of: key))
        try? fileManager.removeItem(at: fileURL)
        accessTimes.removeValue(forKey: key)
        creationTimes.removeValue(forKey: key)
        saveAccessTimes()
        saveCreationTimes()
    }


    /// Removes all cached images and metadata from disk.
    ///
    /// This completely clears the cache directory and recreates it empty.
    ///
    /// - Throws: An error if the cache directory cannot be removed or recreated.
    public func clearAll() throws {
        try fileManager.removeItem(at: cacheDirectory)
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        accessTimes.removeAll()
        creationTimes.removeAll()
        saveAccessTimes()
        saveCreationTimes()
    }


    // MARK: - Query Methods

    /// Checks if an image exists in the cache for the specified key.
    ///
    /// This method checks both the file system and expiration time. If the
    /// image exists but has expired, returns `false`.
    ///
    /// This method does NOT record hits/misses in statistics since it's
    /// just a check, not an actual cache access.
    ///
    /// - Parameter key: The cache key to check.
    /// - Returns: `true` if the image exists and is not expired, `false` otherwise.
    public func exists(for key: String) -> Bool {
        // Check if expired
        if let maxAge, let creationTime = creationTimes[key] {
            if Date().timeIntervalSince(creationTime) > maxAge {
                return false
            }
        }

        let fileURL = cacheDirectory.appendingPathComponent(md5Hash(of: key))
        return fileManager.fileExists(atPath: fileURL.path)
    }


    /// Removes all expired images from the cache.
    ///
    /// This method scans the cache for images that have exceeded `maxAge`
    /// and removes them. If `maxAge` is `nil`, no images are removed.
    ///
    /// - Note: This is automatically called during initialization, but can
    ///         be called manually to proactively clean up expired entries.
    public func removeExpiredImages() {
        guard let maxAge else { return }

        let now = Date()
        let expiredKeys = creationTimes.filter { key, creationTime in
            now.timeIntervalSince(creationTime) > maxAge
        }.map(\.key)

        for key in expiredKeys {
            try? removeImage(for: key)
        }
    }


    /// Calculates the total size of all cached images on disk.
    ///
    /// - Returns: The total cache size in bytes.
    public func getCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
}

// MARK: - Private Helpers

private extension DiskImageCache {
    /// Evicts the least recently used images if the cache exceeds the maximum disk size.
    ///
    /// This method sorts images by access time and removes the oldest ones until
    /// the cache size is below `maxDiskSize`.
    func evictIfNeeded() async {
        let currentSize = getCacheSize()

        guard currentSize > maxDiskSize else { return }

        // Sort by access time (oldest first)
        let sortedKeys = accessTimes.sorted { $0.value < $1.value }.map(\.key)

        var sizeToFree = currentSize - maxDiskSize

        for key in sortedKeys {
            guard sizeToFree > 0 else { break }

            let fileURL = cacheDirectory.appendingPathComponent(md5Hash(of: key))
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                try? removeImage(for: key)
                sizeToFree -= Int64(size)
            }
        }
    }


    /// Loads the access times dictionary from disk.
    ///
    /// This is called during initialization to restore LRU tracking across app launches.
    func loadAccessTimes() async {
        let accessTimesURL = cacheDirectory.appendingPathComponent("access_times.json")
        guard let data = try? Data(contentsOf: accessTimesURL),
              let times = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return
        }
        accessTimes = times
    }


    /// Persists the access times dictionary to disk.
    ///
    /// This is called whenever access times are updated to maintain LRU tracking.
    func saveAccessTimes() {
        let accessTimesURL = cacheDirectory.appendingPathComponent("access_times.json")
        guard let data = try? JSONEncoder().encode(accessTimes) else { return }
        try? data.write(to: accessTimesURL)
    }


    /// Loads the creation times dictionary from disk.
    ///
    /// This is called during initialization to restore TTL tracking across app launches.
    func loadCreationTimes() async {
        let creationTimesURL = cacheDirectory.appendingPathComponent("creation_times.json")
        guard let data = try? Data(contentsOf: creationTimesURL),
              let times = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return
        }
        creationTimes = times
    }


    /// Persists the creation times dictionary to disk.
    ///
    /// This is called whenever creation times are updated to maintain TTL tracking.
    func saveCreationTimes() {
        let creationTimesURL = cacheDirectory.appendingPathComponent("creation_times.json")
        guard let data = try? JSONEncoder().encode(creationTimes) else { return }
        try? data.write(to: creationTimesURL)
    }


    // MARK: - Statistics

    /// Returns current cache performance statistics.
    ///
    /// - Returns: Statistics including hit rate, miss rate, and total requests.
    func getStatistics() -> CacheStatistics {
        statistics
    }


    /// Resets cache performance statistics to zero.
    func resetStatistics() {
        statistics = statistics.reset()
    }
}


// MARK: - Helper Functions

/// Generates an MD5 hash of the input string for use as a filename.
///
/// This ensures that URL strings (which may contain invalid filename characters)
/// can be safely used as cache keys.
///
/// - Parameter string: The string to hash (typically a URL).
/// - Returns: A 32-character hexadecimal MD5 hash.
///
/// - Note: MD5 is used here for speed, not security. Collision risk is acceptable
///         for cache keys.
fileprivate func md5Hash(of string: String) -> String {
    let digest = Insecure.MD5.hash(data: Data(string.utf8))
    return digest.map { String(format: "%02hhx", $0) }.joined()
}
