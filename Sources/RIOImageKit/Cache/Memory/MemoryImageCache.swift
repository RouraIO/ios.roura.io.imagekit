//
//  MemoryImageCache.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import Foundation

/// High-performance in-memory image cache using NSCache with automatic eviction.
///
/// This actor provides thread-safe access to a memory-based image cache with intelligent
/// cost-based eviction and automatic memory pressure handling.
///
/// ## Overview
/// `MemoryImageCache` wraps `NSCache` to provide:
/// - **Cost-based eviction**: Images are weighted by actual memory usage
/// - **Count limits**: Maximum 100 images to prevent excessive memory use
/// - **Automatic pressure handling**: NSCache responds to memory pressure automatically
/// - **Thread safety**: Actor isolation ensures safe concurrent access
///
/// ## Performance Characteristics
/// - **Get**: O(1) average case
/// - **Set**: O(1) average case
/// - **Memory**: Up to 50MB by default (configurable)
/// - **Eviction**: Automatic LRU-style eviction by NSCache
///
/// ## Example Usage
/// ```swift
/// let cache = MemoryImageCache(maxMemoryCost: 50 * 1024 * 1024) // 50MB
///
/// // Store an image
/// await cache.setImage(image, for: "cache-key")
///
/// // Retrieve an image
/// if let cachedImage = await cache.getImage(for: "cache-key") {
///     // Use image
/// }
/// ```
///
/// - Note: This cache is volatile and will be cleared when the app terminates.
///         Use `DiskImageCache` for persistent storage.
public actor MemoryImageCache {

    // MARK: - Properties

    /// The underlying NSCache instance for storing images
    private let cache = NSCache<NSString, PlatformImage>()

    /// Maximum total memory cost for all cached images in bytes
    private let maxMemoryCost: Int

    /// Observer for memory warnings that automatically clears the cache
    nonisolated(unsafe) private var memoryWarningObserver: MemoryWarningObserver?

    /// Performance statistics for this cache
    private var statistics = CacheStatistics()


    // MARK: - Initialization

    /// Creates a new memory cache with the specified size limit.
    ///
    /// The cache automatically clears itself when the system issues memory warnings.
    ///
    /// - Parameter maxMemoryCost: Maximum memory to use in bytes. Defaults to 50MB.
    public init(maxMemoryCost: Int = 50 * 1024 * 1024) { // 50MB default
        self.maxMemoryCost = maxMemoryCost
        cache.totalCostLimit = maxMemoryCost
        cache.countLimit = 100 // Max 100 images

        // Set up automatic memory warning handling
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, *) {
            memoryWarningObserver = MemoryWarningObserver { [weak self] in
                Task { await self?.clearAll() }
            }
        }
    }


    // MARK: - Cache Operations

    /// Retrieves a cached image for the specified key.
    ///
    /// - Parameter key: The cache key (typically a URL string).
    /// - Returns: The cached image if found, otherwise `nil`.
    public func getImage(for key: String) -> PlatformImage? {
        let image = cache.object(forKey: key as NSString)

        // Record hit/miss for statistics
        if image != nil {
            statistics = statistics.recordHit()
        } else {
            statistics = statistics.recordMiss()
        }

        return image
    }


    /// Stores an image in the cache with the specified key.
    ///
    /// The image is stored with a cost based on its actual memory footprint.
    /// If the cache is full, NSCache will automatically evict the least recently used images.
    ///
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - key: The cache key (typically a URL string).
    public func setImage(_ image: PlatformImage, for key: String) {
        let cost = image.memoryCost
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }


    /// Removes a cached image for the specified key.
    ///
    /// - Parameter key: The cache key (typically a URL string).
    public func removeImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }


    /// Clears all cached images from memory.
    ///
    /// This is typically called in response to user-initiated cache clearing.
    public func clearAll() {
        cache.removeAllObjects()
    }


    // MARK: - Query Methods

    /// Checks if an image exists in the cache for the specified key.
    ///
    /// This method does NOT record hits/misses in statistics since it's
    /// just a check, not an actual cache access.
    ///
    /// - Parameter key: The cache key to check.
    /// - Returns: `true` if the image exists in cache, `false` otherwise.
    public func exists(for key: String) -> Bool {
        cache.object(forKey: key as NSString) != nil
    }


    // MARK: - Statistics

    /// Returns current cache performance statistics.
    ///
    /// - Returns: Statistics including hit rate, miss rate, and total requests.
    public func getStatistics() -> CacheStatistics {
        statistics
    }


    /// Resets cache performance statistics to zero.
    public func resetStatistics() {
        statistics = statistics.reset()
    }
}


// MARK: - PlatformImage Extension

private extension PlatformImage {

    /// Calculates the approximate memory cost of this image in bytes.
    ///
    /// This is used by NSCache to determine when to evict images based on total cost.
    ///
    /// - Returns: The memory cost in bytes, or 0 if the image has no backing CGImage.
    var memoryCost: Int {

#if canImport(UIKit)
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height

#elseif canImport(AppKit)
        guard let tiffData = tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return 0
        }
        return bitmapRep.bytesPerRow * bitmapRep.pixelsHigh
#endif
    }
}
