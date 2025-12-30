//
//  ImageCacheManager.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation
import Observation

/// Central coordinator for the two-tier image caching system.
///
/// This class orchestrates image loading, caching, and prefetching by coordinating
/// between memory cache, disk cache, and network downloads.
///
/// ## Overview
/// `ImageCacheManager` provides a unified interface for:
/// - **Two-tier caching**: Memory cache for speed, disk cache for persistence
/// - **Cache promotion**: Disk hits are promoted to memory for faster future access
/// - **Unified API**: Single point of access for all image operations
/// - **Dependency injection**: Protocol-based design for testability
/// - **SwiftUI integration**: Observable for automatic UI updates
///
/// ## Cache Strategy
/// When loading an image:
/// 1. Check memory cache (fastest)
/// 2. Check disk cache (fast, persistent)
/// 3. Download from network (slow)
/// 4. Cache the downloaded image in both tiers
///
/// ## Performance Characteristics
/// - **Memory hit**: ~1ms (instant)
/// - **Disk hit**: ~10-50ms (I/O bound)
/// - **Network**: 100ms-2s (network dependent)
///
/// ## Example Usage
/// ```swift
/// // Initialize via dependency injection
/// let manager = ImageCacheManager(
///     imageLoadable: ImageDownloadService(),
///     memoryCache: MemoryImageCache(),
///     diskCache: try! DiskImageCache()
/// )
///
/// // Load an image (with automatic caching)
/// let image = try await manager.loadImage(from: url)
///
/// // Prefetch images for better UX
/// await manager.prefetchImages(urls: upcomingURLs)
///
/// // Clear cache when needed
/// await manager.clearCache()
/// ```
///
/// - Note: This class is marked `@Observable` for SwiftUI integration but most
///         apps should access it via the environment using `AppDependencies`.
@Observable
public final class ImageCacheManager {

    // MARK: - Properties

    /// Service for downloading images from the network
    public let imageLoadable: any ImageLoadable

    /// Fast, volatile memory cache
    private let memoryCache: MemoryImageCache

    /// Persistent disk cache with LRU eviction
    private let diskCache: DiskImageCache


    // MARK: - Initialization

    /// Creates a new image cache manager with the specified dependencies.
    ///
    /// - Parameters:
    ///   - imageLoadable: Service for downloading images (typically `ImageDownloadService`).
    ///   - memoryCache: Memory cache instance.
    ///   - diskCache: Disk cache instance.
    public init(
        imageLoadable: any ImageLoadable,
        memoryCache: MemoryImageCache,
        diskCache: DiskImageCache
    ) {
        self.imageLoadable = imageLoadable
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }
}


// MARK: - ImageCacheable Conformance

extension ImageCacheManager: ImageCacheable {

    /// Retrieves a cached image from either memory or disk cache.
    ///
    /// This method checks caches in order of speed:
    /// 1. Memory cache (fastest)
    /// 2. Disk cache (if memory miss, promotes to memory)
    ///
    /// - Parameter url: The URL of the image to retrieve.
    /// - Returns: The cached image if found, otherwise `nil`.
    public func getImage(for url: URL) async -> PlatformImage? {
        let key = url.absoluteString

        // Check memory cache first
        if let image = await memoryCache.getImage(for: key) {
            return image
        }

        // Check disk cache
        if let image = await diskCache.getImage(for: key) {
            // Promote to memory cache
            await memoryCache.setImage(image, for: key)
            return image
        }

        return nil
    }


    /// Stores an image in both memory and disk caches.
    ///
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - url: The URL to use as the cache key.
    public func setImage(_ image: PlatformImage, for url: URL) async {
        let key = url.absoluteString

        // Store in both caches
        await memoryCache.setImage(image, for: key)
        try? await diskCache.setImage(image, for: key)
    }


    /// Removes an image from both memory and disk caches.
    ///
    /// - Parameter url: The URL of the image to remove.
    public func removeImage(for url: URL) async {
        let key = url.absoluteString
        await memoryCache.removeImage(for: key)
        try? await diskCache.removeImage(for: key)
    }


    /// Clears all images from both memory and disk caches.
    public func clearCache() async {
        await memoryCache.clearAll()
        try? await diskCache.clearAll()
    }


    /// Returns the total size of the disk cache in bytes.
    ///
    /// - Returns: The disk cache size in bytes (memory cache size is not included as it's volatile).
    public func getCacheSize() async -> Int64 {
        await diskCache.getCacheSize()
    }
}


// MARK: - Convenience Methods

public extension ImageCacheManager {

    /// Loads an image from cache or downloads it if not cached.
    ///
    /// This is the primary method for loading images in most cases. It automatically:
    /// 1. Checks both caches for the image
    /// 2. Downloads the image if not cached
    /// 3. Caches the downloaded image for future use
    ///
    /// - Parameter url: The URL of the image to load.
    /// - Returns: The loaded or downloaded image.
    /// - Throws: `ImageCacheError` or `NetworkError` if the image cannot be loaded or downloaded.
    func loadImage(from url: URL) async throws -> PlatformImage {
        // Check cache first
        if let cachedImage = await getImage(for: url) {
            return cachedImage
        }

        // Download and cache
        let image = try await imageLoadable.loadImage(from: url)
        await setImage(image, for: url)
        return image
    }


    /// Prefetches images in the background for improved perceived performance.
    ///
    /// This method downloads and caches images at low priority without blocking
    /// the main thread. Useful for preloading images that will be needed soon
    /// (e.g., when a user is scrolling through a list).
    ///
    /// - Parameter urls: An array of image URLs to prefetch.
    ///
    /// - Note: Prefetching runs at `.background` priority and failed downloads are silently ignored.
    func prefetchImages(urls: [URL]) async {
        await imageLoadable.prefetchImages(urls: urls)
    }


    /// Cancels ongoing prefetch operations for the specified URLs.
    ///
    /// This allows you to stop downloading images that are no longer needed
    /// (e.g., when a user navigates away or scrolls past certain items).
    ///
    /// - Parameter urls: An array of image URLs to cancel prefetching for.
    func cancelPrefetch(for urls: [URL]) {
        imageLoadable.cancelPrefetch(for: urls)
    }
}
