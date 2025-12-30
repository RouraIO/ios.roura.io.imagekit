//
//  ImageCacheable.swift
//  RIOImageKit
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Protocol defining the interface for image caching operations.
///
/// This protocol provides a standardized interface for image caching implementations,
/// supporting both memory and disk-based caching strategies. Conforming types should
/// implement thread-safe caching mechanisms that can handle concurrent access.
///
/// ## Overview
/// The protocol supports a two-tier caching architecture:
/// - **Memory cache**: Fast, volatile storage (NSCache-based)
/// - **Disk cache**: Persistent storage with LRU eviction
///
/// ## Thread Safety
/// All methods are `async` to ensure safe concurrent access. Implementations should
/// use actors or other synchronization mechanisms to prevent race conditions.
///
/// ## Example Usage
/// ```swift
/// let cacheManager: ImageCacheable = ImageCacheManager(...)
///
/// // Store an image
/// await cacheManager.setImage(image, for: url)
///
/// // Retrieve an image
/// if let cachedImage = await cacheManager.getImage(for: url) {
///     // Use cached image
/// }
///
/// // Clear cache when memory is low
/// await cacheManager.clearCache()
/// ```
public protocol ImageCacheable: Sendable {
    
    /// Retrieves a cached image for the specified URL.
    ///
    /// This method checks both memory and disk caches in order of speed.
    /// If found in disk cache, the image is promoted to memory cache for faster future access.
    ///
    /// - Parameter url: The URL that was used to download the image.
    /// - Returns: The cached image if found, otherwise `nil`.
    ///
    /// - Note: This operation is thread-safe and can be called from any context.
    func getImage(for url: URL) async -> PlatformImage?
    
    
    /// Stores an image in the cache for the specified URL.
    ///
    /// The image is stored in both memory and disk caches. Memory cache uses
    /// cost-based eviction, while disk cache uses LRU eviction when size limits are exceeded.
    ///
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - url: The URL to use as the cache key.
    ///
    /// - Note: If the cache is full, older entries will be evicted automatically.
    func setImage(_ image: PlatformImage, for url: URL) async
    
    
    /// Removes a cached image for the specified URL.
    ///
    /// This removes the image from both memory and disk caches.
    ///
    /// - Parameter url: The URL of the cached image to remove.
    func removeImage(for url: URL) async
    
    
    /// Clears all images from both memory and disk caches.
    ///
    /// This is useful for:
    /// - Responding to memory warnings
    /// - User-initiated cache clearing
    /// - Testing and development
    ///
    /// - Warning: This operation cannot be undone. All cached images will need to be re-downloaded.
    func clearCache() async
    
    
    /// Returns the total size of all cached images in bytes.
    ///
    /// This includes both memory and disk cache sizes.
    ///
    /// - Returns: The total cache size in bytes.
    ///
    /// - Note: This is an approximate value and may not reflect exact memory usage.
    func getCacheSize() async -> Int64
}
