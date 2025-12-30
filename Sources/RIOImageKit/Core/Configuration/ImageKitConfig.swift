//
//  ImageKitConfig.swift
//  RouraIOTools
//
//  Created by Christopher J. Roura on 12/29/25.
//

import Foundation

/// Global configuration constants for image caching and storage.
///
/// This enum provides centralized configuration for the image caching system,
/// including memory/disk cache sizes, expiration policies, and compression settings.
///
/// ## Overview
/// Configuration is organized into a `Cache` namespace containing:
/// - **Memory cache size**: How much RAM to dedicate to cached images
/// - **Disk cache size**: How much storage to use for persistent cache
/// - **Max age**: How long cached images remain valid before expiration
/// - **Compression quality**: JPEG quality for disk storage (0.0-1.0)
///
/// ## Design Philosophy
/// Default values balance:
/// - **Performance**: Fast access with reasonable cache sizes
/// - **Storage efficiency**: Moderate compression without visual quality loss
/// - **User experience**: Long enough expiration to feel instant, short enough to stay fresh
///
/// ## Customization
/// While these are static defaults, components can be initialized with custom values:
/// ```swift
/// // Using custom cache configuration
/// let memoryCache = MemoryImageCache(
///     maxMemoryCost: 100 * 1024 * 1024  // 100MB instead of default 50MB
/// )
///
/// let diskCache = try DiskImageCache(
///     maxSize: 200 * 1024 * 1024,  // 200MB instead of default 100MB
///     maxAge: 14 * 24 * 60 * 60    // 14 days instead of default 7 days
/// )
/// ```
///
/// ## Cache Strategy
/// The two-tier caching system works as follows:
/// 1. **Check memory** (~1ms): Fastest, but volatile
/// 2. **Check disk** (~10-50ms): Slower, but persistent
/// 3. **Download** (~100ms-2s): Slowest, requires network
/// 4. **Cache in both tiers**: For future quick access
///
/// ## Performance Tuning
/// Adjust based on your app's characteristics:
///
/// ### High-Traffic Image Apps (Instagram-like)
/// ```swift
/// memoryCacheSize: 100 * 1024 * 1024  // 100MB
/// diskCacheSize: 500 * 1024 * 1024    // 500MB
/// maxAge: 3 * 24 * 60 * 60            // 3 days (refresh often)
/// compressionQuality: 0.85             // Higher quality
/// ```
///
/// ### Low-Memory Devices
/// ```swift
/// memoryCacheSize: 20 * 1024 * 1024   // 20MB
/// diskCacheSize: 50 * 1024 * 1024     // 50MB
/// maxAge: 7 * 24 * 60 * 60            // 7 days
/// compressionQuality: 0.7              // More compression
/// ```
///
/// ### Static Content Apps
/// ```swift
/// memoryCacheSize: 50 * 1024 * 1024   // 50MB
/// diskCacheSize: 200 * 1024 * 1024    // 200MB
/// maxAge: 30 * 24 * 60 * 60           // 30 days (rarely changes)
/// compressionQuality: 0.8              // Balanced
/// ```
///
/// - Note: Changes to these constants require recompilation. For runtime config,
///         pass custom values to component initializers.
/// - SeeAlso: ``MemoryImageCache`` for in-memory caching.
/// - SeeAlso: ``DiskImageCache`` for persistent caching.
/// - SeeAlso: ``ImageCacheManager`` for the two-tier coordinator.
public enum ImageKitConfig {

    /// Configuration for image cache storage and expiration.
    ///
    /// These settings control how images are stored in memory and on disk,
    /// including size limits, expiration policies, and compression settings.
    ///
    /// ## Default Values Summary
    /// - **Memory**: 50 MB (fast, volatile)
    /// - **Disk**: 100 MB (slower, persistent)
    /// - **Max Age**: 7 days (one week)
    /// - **Compression**: 0.8 (80% JPEG quality)
    ///
    /// ## Storage Breakdown
    /// With default settings:
    /// - Memory cache: ~200-500 images (depending on size)
    /// - Disk cache: ~400-1000 images (depending on size)
    /// - Total storage: 150 MB maximum
    ///
    /// ## Example Usage
    /// ```swift
    /// // Using defaults
    /// let manager = ImageCacheManager(
    ///     imageLoadable: ImageDownloadService(),
    ///     memoryCache: MemoryImageCache(
    ///         maxMemoryCost: ImageKitConfig.Cache.memoryCacheSize
    ///     ),
    ///     diskCache: try DiskImageCache(
    ///         maxSize: ImageKitConfig.Cache.diskCacheSize,
    ///         maxAge: ImageKitConfig.Cache.maxAge
    ///     )
    /// )
    ///
    /// // Or rely on component defaults (which use these values)
    /// let manager = ImageCacheManager(
    ///     imageLoadable: ImageDownloadService(),
    ///     memoryCache: MemoryImageCache(),
    ///     diskCache: try DiskImageCache()
    /// )
    /// ```
    public enum Cache {

        /// Maximum memory (in bytes) for in-memory image caching.
        ///
        /// The memory cache provides fastest access (~1ms) but is volatile,
        /// meaning it's cleared when the app terminates or memory pressure occurs.
        ///
        /// **Default:** 50 MB (52,428,800 bytes)
        ///
        /// ## Sizing Guidelines
        /// - **Small cache (20MB)**: ~80-200 images, good for low-memory devices
        /// - **Medium cache (50MB)**: ~200-500 images, balanced for most apps
        /// - **Large cache (100MB)**: ~400-1000 images, for image-heavy apps
        ///
        /// ## Typical Image Sizes
        /// - Thumbnail (100x100): ~20-40 KB
        /// - Profile picture (300x300): ~100-200 KB
        /// - Full screen (1170x2532): ~500 KB - 2 MB
        /// - High-res photo (4K): ~2-8 MB
        ///
        /// **Example:**
        /// ```swift
        /// // Calculate cache capacity
        /// let averageImageSize = 200 * 1024  // 200 KB
        /// let memoryCacheCapacity = ImageKitConfig.Cache.memoryCacheSize / averageImageSize
        /// // Result: ~250 images
        /// ```
        ///
        /// - Note: iOS may evict memory cache under memory pressure automatically.
        public static let memoryCacheSize = 50 * 1024 * 1024  // 50MB


        /// Maximum disk space (in bytes) for persistent image caching.
        ///
        /// The disk cache is slower than memory (~10-50ms) but persists across
        /// app launches. Images are stored as JPEG files with configurable compression.
        ///
        /// **Default:** 100 MB (104,857,600 bytes)
        ///
        /// ## Sizing Guidelines
        /// - **Small cache (50MB)**: ~200-500 images
        /// - **Medium cache (100MB)**: ~400-1000 images, good for most apps
        /// - **Large cache (500MB)**: ~2000-5000 images, for Instagram-like apps
        ///
        /// ## LRU Eviction
        /// When the cache exceeds this size, the oldest (least recently used)
        /// images are automatically removed until the total size is under the limit.
        ///
        /// **Example:**
        /// ```swift
        /// // Monitor cache size
        /// let currentSize = await diskCache.getCacheSize()
        /// let maxSize = Int64(ImageKitConfig.Cache.diskCacheSize)
        /// let percentFull = Double(currentSize) / Double(maxSize) * 100
        /// print("Disk cache is \(percentFull)% full")
        ///
        /// if percentFull > 90 {
        ///     // Cache is almost full, consider clearing old entries
        ///     await diskCache.removeExpiredImages()
        /// }
        /// ```
        ///
        /// - Note: iOS may purge disk cache when device storage is critically low.
        public static let diskCacheSize: Int64 = 100 * 1024 * 1024  // 100MB


        /// Maximum age (in seconds) before cached images expire.
        ///
        /// Images older than this duration are considered stale and will be
        /// removed during cache maintenance operations.
        ///
        /// **Default:** 7 days (604,800 seconds)
        ///
        /// ## Expiration Strategy
        /// - **Short (1-3 days)**: For frequently changing content (user profiles, news)
        /// - **Medium (7 days)**: Balanced for most apps (default)
        /// - **Long (30+ days)**: For static content (app assets, rarely changing images)
        ///
        /// ## How Expiration Works
        /// Expired images are removed:
        /// 1. Automatically during cache size checks
        /// 2. On app launch (cleanup of old entries)
        /// 3. When manually calling `removeExpiredImages()`
        ///
        /// **Example:**
        /// ```swift
        /// // Different expiration for different content types
        /// let profileImageMaxAge: TimeInterval = 24 * 60 * 60       // 1 day
        /// let productImageMaxAge: TimeInterval = 7 * 24 * 60 * 60   // 7 days
        /// let logoMaxAge: TimeInterval = 30 * 24 * 60 * 60          // 30 days
        ///
        /// // Check if an image is expired
        /// let entry = CacheEntry(key: "key", timestamp: oldDate, fileSize: 1000)
        /// if entry.isExpired(maxAge: ImageKitConfig.Cache.maxAge) {
        ///     print("Image expired, will be removed")
        /// }
        /// ```
        ///
        /// **Time Breakdown:**
        /// - 1 day: `24 * 60 * 60` = 86,400 seconds
        /// - 7 days: `7 * 24 * 60 * 60` = 604,800 seconds (default)
        /// - 30 days: `30 * 24 * 60 * 60` = 2,592,000 seconds
        public static let maxAge: TimeInterval = 7 * 24 * 60 * 60  // 1 week


        /// JPEG compression quality for disk-cached images (0.0 to 1.0).
        ///
        /// Images are stored on disk as JPEG with this compression level to
        /// balance storage efficiency and visual quality.
        ///
        /// **Default:** 0.8 (80% quality)
        ///
        /// ## Quality Guidelines
        /// - **0.5-0.6**: High compression, visible artifacts, smallest files
        /// - **0.7-0.8**: Balanced compression, minimal artifacts (recommended)
        /// - **0.9-1.0**: Low compression, near-lossless, larger files
        ///
        /// ## File Size Impact
        /// For a typical 1MB PNG image:
        /// - **0.5 quality**: ~100-150 KB (10x compression)
        /// - **0.8 quality**: ~200-300 KB (4x compression) ✅
        /// - **1.0 quality**: ~800-900 KB (1.2x compression)
        ///
        /// ## Visual Quality
        /// - **0.8**: Imperceptible quality loss for most content
        /// - **0.7**: Slight artifacts in detailed areas (acceptable for thumbnails)
        /// - **0.5**: Noticeable compression artifacts
        ///
        /// **Example:**
        /// ```swift
        /// // Save image with configured compression
        /// let jpegData = image.jpegData(
        ///     compressionQuality: ImageKitConfig.Cache.compressionQuality
        /// )
        ///
        /// // Custom compression for thumbnails
        /// let thumbnailData = thumbnail.jpegData(compressionQuality: 0.6)
        ///
        /// // Higher quality for product photos
        /// let productData = productImage.jpegData(compressionQuality: 0.9)
        /// ```
        ///
        /// - Important: PNG images are converted to JPEG for caching. If you need
        ///              transparency, consider caching as PNG (but larger file sizes).
        public static let compressionQuality: CGFloat = 0.8
    }
}
